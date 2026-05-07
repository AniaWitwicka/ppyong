package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

type GroupRepository struct {
	pool *pgxpool.Pool
}

func NewGroupRepository(pool *pgxpool.Pool) *GroupRepository {
	return &GroupRepository{pool: pool}
}

func (r *GroupRepository) List(ctx context.Context, userID string) ([]model.GroupSummary, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			g.id, g.name, g.emoji, g.color,
			COUNT(DISTINCT gm.user_id)  AS member_count,
			COUNT(DISTINCT d.id)        AS deck_count,
			MAX(u.last_active)          AS last_active
		FROM groups g
		JOIN group_members gm ON gm.group_id = g.id
		LEFT JOIN group_members gm2 ON gm2.group_id = g.id
		LEFT JOIN users u ON u.id = gm2.user_id
		LEFT JOIN collections c ON c.created_by = gm2.user_id
		LEFT JOIN decks d ON d.collection_id = c.id
		WHERE g.id IN (SELECT group_id FROM group_members WHERE user_id = $1)
		GROUP BY g.id, g.name, g.emoji, g.color
		ORDER BY g.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []model.GroupSummary
	for rows.Next() {
		var g model.GroupSummary
		if err := rows.Scan(&g.ID, &g.Name, &g.Emoji, &g.Color,
			&g.MemberCount, &g.DeckCount, &g.LastActive); err != nil {
			return nil, err
		}
		groups = append(groups, g)
	}

	// Fetch up to 4 member avatars per group
	for i := range groups {
		avatars, err := r.memberAvatars(ctx, groups[i].ID)
		if err != nil {
			return nil, err
		}
		groups[i].Avatars = avatars
	}

	if groups == nil {
		groups = []model.GroupSummary{}
	}
	return groups, nil
}

func (r *GroupRepository) memberAvatars(ctx context.Context, groupID string) ([]model.MemberAvatar, error) {
	// Assign a palette color to each member by join order
	palette := []string{"#99B7F5", "#267F53", "#F5793B", "#F296BD", "#FCCA59"}
	rows, err := r.pool.Query(ctx, `
		SELECT u.initials
		FROM group_members gm
		JOIN users u ON u.id = gm.user_id
		WHERE gm.group_id = $1
		ORDER BY gm.joined_at
		LIMIT 4
	`, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var avatars []model.MemberAvatar
	i := 0
	for rows.Next() {
		var initials string
		if err := rows.Scan(&initials); err != nil {
			return nil, err
		}
		avatars = append(avatars, model.MemberAvatar{
			Initials: initials,
			Color:    palette[i%len(palette)],
		})
		i++
	}
	if avatars == nil {
		avatars = []model.MemberAvatar{}
	}
	return avatars, nil
}

func (r *GroupRepository) GetByID(ctx context.Context, groupID, userID string) (*model.GroupDetail, error) {
	var g model.GroupDetail
	err := r.pool.QueryRow(ctx, `
		SELECT
			g.id, g.name, g.emoji, g.color,
			COUNT(DISTINCT gm.user_id) AS member_count,
			COUNT(DISTINCT d.id)       AS deck_count
		FROM groups g
		JOIN group_members gm ON gm.group_id = g.id
		LEFT JOIN group_members gm2 ON gm2.group_id = g.id
		LEFT JOIN collections c ON c.created_by = gm2.user_id
		LEFT JOIN decks d ON d.collection_id = c.id
		WHERE g.id = $1
		GROUP BY g.id, g.name, g.emoji, g.color
	`, groupID).Scan(&g.ID, &g.Name, &g.Emoji, &g.Color, &g.MemberCount, &g.DeckCount)
	if err != nil {
		return nil, err
	}

	members, err := r.listMembers(ctx, groupID, userID)
	if err != nil {
		return nil, err
	}
	g.Members = members
	for _, m := range members {
		if m.UserID == userID && m.Role == "owner" {
			g.IsOwner = true
			break
		}
	}

	decks, err := r.listSharedDecks(ctx, groupID, userID)
	if err != nil {
		return nil, err
	}
	g.SharedDecks = decks

	return &g, nil
}

func (r *GroupRepository) listMembers(ctx context.Context, groupID, userID string) ([]model.GroupMember, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			u.id, u.name, u.initials, gm.role,
			COALESCE(
				(SELECT COUNT(DISTINCT sp.card_id)::float
				 FROM srs_progress sp
				 WHERE sp.user_id = u.id AND sp.interval_days >= 7)
				/
				NULLIF((SELECT COUNT(*) FROM cards ca2
				        JOIN decks d2 ON d2.id = ca2.deck_id
				        JOIN collections c2 ON c2.id = d2.collection_id
				        WHERE c2.created_by IN (
				            SELECT user_id FROM group_members WHERE group_id = $1
				        ))::float, 0),
			0) AS progress
		FROM group_members gm
		JOIN users u ON u.id = gm.user_id
		WHERE gm.group_id = $1
		ORDER BY gm.joined_at
	`, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []model.GroupMember
	for rows.Next() {
		var m model.GroupMember
		if err := rows.Scan(&m.UserID, &m.Name, &m.Initials, &m.Role, &m.Progress); err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	if members == nil {
		members = []model.GroupMember{}
	}
	return members, nil
}

func (r *GroupRepository) listSharedDecks(ctx context.Context, groupID, userID string) ([]model.DeckSummary, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			d.id, d.title AS name,
			COUNT(DISTINCT ca.id)                                              AS card_count,
			COUNT(DISTINCT CASE WHEN sp.interval_days >= 7
			                    AND sp.user_id = $2 THEN ca.id END)            AS mastered_count,
			COUNT(DISTINCT CASE WHEN sp.interval_days < 7
			                    AND sp.user_id = $2
			                    AND sp.repetitions > 0 THEN ca.id END)         AS learning_count,
			COUNT(DISTINCT CASE WHEN sp.card_id IS NULL
			                    OR (sp.user_id = $2
			                        AND sp.repetitions = 0) THEN ca.id END)   AS new_count
		FROM decks d
		LEFT JOIN cards ca ON ca.deck_id = d.id
		LEFT JOIN srs_progress sp ON sp.card_id = ca.id AND sp.user_id = $2
		WHERE d.collection_id IN (
			SELECT c.id FROM collections c
			WHERE c.created_by IN (
				SELECT user_id FROM group_members WHERE group_id = $1
			)
		)
		GROUP BY d.id, d.title
		ORDER BY d.created_at DESC
	`, groupID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var decks []model.DeckSummary
	for rows.Next() {
		var d model.DeckSummary
		if err := rows.Scan(&d.ID, &d.Name, &d.CardCount, &d.MasteredCount, &d.LearningCount, &d.NewCount); err != nil {
			return nil, err
		}
		decks = append(decks, d)
	}
	if decks == nil {
		decks = []model.DeckSummary{}
	}
	return decks, nil
}

func (r *GroupRepository) Create(ctx context.Context, userID, name, emoji, color string) (*model.GroupSummary, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var id string
	err = tx.QueryRow(ctx, `
		INSERT INTO groups (name, emoji, color, created_by)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, name, emoji, color, userID).Scan(&id)
	if err != nil {
		return nil, err
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO group_members (group_id, user_id, role)
		VALUES ($1, $2, 'owner')
	`, id, userID)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &model.GroupSummary{
		ID: id, Name: name, Emoji: emoji, Color: color,
		MemberCount: 1, DeckCount: 0,
		Avatars: []model.MemberAvatar{},
	}, nil
}

func (r *GroupRepository) Update(ctx context.Context, groupID string, name, emoji, color *string) (*model.GroupSummary, error) {
	_, err := r.pool.Exec(ctx, `
		UPDATE groups SET
			name  = COALESCE($2, name),
			emoji = COALESCE($3, emoji),
			color = COALESCE($4, color)
		WHERE id = $1
	`, groupID, name, emoji, color)
	if err != nil {
		return nil, err
	}

	var g model.GroupSummary
	err = r.pool.QueryRow(ctx, `
		SELECT id, name, emoji, color FROM groups WHERE id = $1
	`, groupID).Scan(&g.ID, &g.Name, &g.Emoji, &g.Color)
	if err != nil {
		return nil, err
	}
	g.Avatars = []model.MemberAvatar{}
	return &g, nil
}

func (r *GroupRepository) Delete(ctx context.Context, groupID string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM groups WHERE id = $1`, groupID)
	return err
}

func (r *GroupRepository) Leave(ctx context.Context, groupID, userID string) error {
	var role string
	err := r.pool.QueryRow(ctx, `
		SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2
	`, groupID, userID).Scan(&role)
	if err != nil {
		return fmt.Errorf("not a member")
	}
	if role == "owner" {
		return fmt.Errorf("owner cannot leave; delete the group instead")
	}
	_, err = r.pool.Exec(ctx, `
		DELETE FROM group_members WHERE group_id = $1 AND user_id = $2
	`, groupID, userID)
	return err
}

func (r *GroupRepository) IsMember(ctx context.Context, groupID, userID string) (bool, error) {
	var count int
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM group_members WHERE group_id = $1 AND user_id = $2
	`, groupID, userID).Scan(&count)
	return count > 0, err
}

func (r *GroupRepository) IsOwner(ctx context.Context, groupID, userID string) (bool, error) {
	var count int
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM group_members WHERE group_id = $1 AND user_id = $2 AND role = 'owner'
	`, groupID, userID).Scan(&count)
	return count > 0, err
}
