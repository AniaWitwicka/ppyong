package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

type InviteRepository struct {
	pool *pgxpool.Pool
}

func NewInviteRepository(pool *pgxpool.Pool) *InviteRepository {
	return &InviteRepository{pool: pool}
}

const inviteSelectCols = `
	i.id, i.group_id, g.name AS group_name, g.emoji AS group_emoji, g.color AS group_color,
	inviter.name AS inviter_name, i.invitee_email, i.status, i.expires_at, i.created_at
`

const inviteSelectJoin = `
	FROM invites i
	JOIN groups g ON g.id = i.group_id
	JOIN users inviter ON inviter.id = i.inviter_id
`

func scanInvite(row interface {
	Scan(...any) error
}) (model.Invite, error) {
	var inv model.Invite
	err := row.Scan(
		&inv.ID, &inv.GroupID, &inv.GroupName, &inv.GroupEmoji, &inv.GroupColor,
		&inv.InviterName, &inv.InviteeEmail, &inv.Status, &inv.ExpiresAt, &inv.CreatedAt,
	)
	return inv, err
}

func (r *InviteRepository) List(ctx context.Context, userID string) (*model.InviteListResponse, error) {
	// Fetch user's email for matching incoming invites
	var email string
	if err := r.pool.QueryRow(ctx, `SELECT email FROM users WHERE id = $1`, userID).Scan(&email); err != nil {
		return nil, err
	}

	// Incoming: pending invites addressed to this user's email
	inRows, err := r.pool.Query(ctx, `
		SELECT `+inviteSelectCols+`
		`+inviteSelectJoin+`
		WHERE i.invitee_email = $1 AND i.status = 'pending' AND i.expires_at > NOW()
		ORDER BY i.created_at DESC
	`, email)
	if err != nil {
		return nil, err
	}
	defer inRows.Close()

	incoming := []model.Invite{}
	for inRows.Next() {
		inv, err := scanInvite(inRows)
		if err != nil {
			return nil, err
		}
		incoming = append(incoming, inv)
	}

	// Sent: invites this user sent
	outRows, err := r.pool.Query(ctx, `
		SELECT `+inviteSelectCols+`
		`+inviteSelectJoin+`
		WHERE i.inviter_id = $1
		ORDER BY i.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer outRows.Close()

	sent := []model.Invite{}
	for outRows.Next() {
		inv, err := scanInvite(outRows)
		if err != nil {
			return nil, err
		}
		sent = append(sent, inv)
	}

	return &model.InviteListResponse{Incoming: incoming, Sent: sent}, nil
}

// Create inserts an invite. Pass either a direct email, or a userID to resolve the email.
func (r *InviteRepository) Create(ctx context.Context, groupID, inviterID, email, userID string) (*model.Invite, error) {
	// Resolve email from userID if email not provided directly.
	if email == "" && userID != "" {
		if err := r.pool.QueryRow(ctx, `SELECT email FROM users WHERE id = $1`, userID).Scan(&email); err != nil {
			return nil, err
		}
	}
	if email == "" {
		return nil, &PermissionError{msg: "email or user_id is required"}
	}

	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO invites (group_id, inviter_id, invitee_email)
		VALUES ($1, $2, $3)
		RETURNING id
	`, groupID, inviterID, email).Scan(&id)
	if err != nil {
		return nil, err
	}

	var inv model.Invite
	err = r.pool.QueryRow(ctx, `
		SELECT `+inviteSelectCols+`
		`+inviteSelectJoin+`
		WHERE i.id = $1
	`, id).Scan(
		&inv.ID, &inv.GroupID, &inv.GroupName, &inv.GroupEmoji, &inv.GroupColor,
		&inv.InviterName, &inv.InviteeEmail, &inv.Status, &inv.ExpiresAt, &inv.CreatedAt,
	)
	return &inv, err
}

func (r *InviteRepository) Accept(ctx context.Context, inviteID, userID string) error {
	// Verify the invite is addressed to this user and still pending
	var email, groupID string
	err := r.pool.QueryRow(ctx, `
		SELECT i.invitee_email, i.group_id
		FROM invites i
		WHERE i.id = $1 AND i.status = 'pending' AND i.expires_at > NOW()
	`, inviteID).Scan(&email, &groupID)
	if err != nil {
		return err
	}

	var userEmail string
	if err := r.pool.QueryRow(ctx, `SELECT email FROM users WHERE id = $1`, userID).Scan(&userEmail); err != nil {
		return err
	}
	if userEmail != email {
		return &PermissionError{"invite not addressed to you"}
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		UPDATE invites SET status = 'accepted', invitee_user_id = $2 WHERE id = $1
	`, inviteID, userID)
	if err != nil {
		return err
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO group_members (group_id, user_id, role)
		VALUES ($1, $2, 'member')
		ON CONFLICT (group_id, user_id) DO NOTHING
	`, groupID, userID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *InviteRepository) Decline(ctx context.Context, inviteID, userID string) error {
	var email string
	err := r.pool.QueryRow(ctx, `
		SELECT invitee_email FROM invites WHERE id = $1 AND status = 'pending'
	`, inviteID).Scan(&email)
	if err != nil {
		return err
	}

	var userEmail string
	if err := r.pool.QueryRow(ctx, `SELECT email FROM users WHERE id = $1`, userID).Scan(&userEmail); err != nil {
		return err
	}
	if userEmail != email {
		return &PermissionError{"invite not addressed to you"}
	}

	_, err = r.pool.Exec(ctx, `
		UPDATE invites SET status = 'declined' WHERE id = $1
	`, inviteID)
	return err
}

func (r *InviteRepository) PendingCount(ctx context.Context, userID string) (int, error) {
	var email string
	if err := r.pool.QueryRow(ctx, `SELECT email FROM users WHERE id = $1`, userID).Scan(&email); err != nil {
		return 0, err
	}
	var count int
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM invites
		WHERE invitee_email = $1 AND status = 'pending' AND expires_at > NOW()
	`, email).Scan(&count)
	return count, err
}

// PermissionError is a sentinel so handlers can return 403 vs 500.
type PermissionError struct{ msg string }

func (e *PermissionError) Error() string { return e.msg }
