package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

type FriendRepository struct {
	pool *pgxpool.Pool
}

func NewFriendRepository(pool *pgxpool.Pool) *FriendRepository {
	return &FriendRepository{pool: pool}
}

func (r *FriendRepository) List(ctx context.Context, userID string) ([]model.Friend, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			f.id AS friendship_id,
			u.id, u.name, u.initials, u.role, u.streak,
			(SELECT COUNT(DISTINCT sp.card_id)
			 FROM srs_progress sp WHERE sp.user_id = u.id)         AS word_count,
			(SELECT COUNT(DISTINCT sp2.card_id)
			 FROM srs_progress sp2
			 WHERE sp2.user_id = u.id AND sp2.due_date <= CURRENT_DATE) AS due_count
		FROM friends f
		JOIN users u ON u.id = CASE WHEN f.requester_id = $1 THEN f.addressee_id
		                            ELSE f.requester_id END
		WHERE (f.requester_id = $1 OR f.addressee_id = $1)
		  AND f.status = 'accepted'
		ORDER BY u.name
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	friends := []model.Friend{}
	for rows.Next() {
		var fr model.Friend
		if err := rows.Scan(&fr.FriendshipID, &fr.UserID, &fr.Name, &fr.Initials,
			&fr.Role, &fr.Streak, &fr.WordCount, &fr.DueCount); err != nil {
			return nil, err
		}
		friends = append(friends, fr)
	}
	return friends, nil
}

func (r *FriendRepository) Search(ctx context.Context, userID, query string) ([]model.UserSummary, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, initials, role
		FROM users
		WHERE id != $1
		  AND (name ILIKE '%' || $2 || '%' OR email ILIKE '%' || $2 || '%')
		  AND id NOT IN (
		      SELECT CASE WHEN requester_id = $1 THEN addressee_id ELSE requester_id END
		      FROM friends
		      WHERE requester_id = $1 OR addressee_id = $1
		  )
		ORDER BY name
		LIMIT 20
	`, userID, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	results := []model.UserSummary{}
	for rows.Next() {
		var u model.UserSummary
		if err := rows.Scan(&u.ID, &u.Name, &u.Initials, &u.Role); err != nil {
			return nil, err
		}
		results = append(results, u)
	}
	return results, nil
}

func (r *FriendRepository) ListPendingRequests(ctx context.Context, userID string) ([]model.Friend, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			f.id AS friendship_id,
			u.id, u.name, u.initials, u.role, u.streak,
			(SELECT COUNT(DISTINCT sp.card_id)
			 FROM srs_progress sp WHERE sp.user_id = u.id)         AS word_count,
			(SELECT COUNT(DISTINCT sp2.card_id)
			 FROM srs_progress sp2
			 WHERE sp2.user_id = u.id AND sp2.due_date <= CURRENT_DATE) AS due_count
		FROM friends f
		JOIN users u ON u.id = f.requester_id
		WHERE f.addressee_id = $1 AND f.status = 'pending'
		ORDER BY f.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	requests := []model.Friend{}
	for rows.Next() {
		var fr model.Friend
		if err := rows.Scan(&fr.FriendshipID, &fr.UserID, &fr.Name, &fr.Initials,
			&fr.Role, &fr.Streak, &fr.WordCount, &fr.DueCount); err != nil {
			return nil, err
		}
		requests = append(requests, fr)
	}
	return requests, nil
}

func (r *FriendRepository) SendRequest(ctx context.Context, requesterID, addresseeID string) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO friends (requester_id, addressee_id, status)
		VALUES ($1, $2, 'pending')
		ON CONFLICT (requester_id, addressee_id) DO NOTHING
	`, requesterID, addresseeID)
	return err
}

func (r *FriendRepository) Accept(ctx context.Context, friendshipID, userID string) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE friends SET status = 'accepted'
		WHERE id = $1 AND addressee_id = $2 AND status = 'pending'
	`, friendshipID, userID)
	return err
}

func (r *FriendRepository) Decline(ctx context.Context, friendshipID, userID string) error {
	_, err := r.pool.Exec(ctx, `
		DELETE FROM friends
		WHERE id = $1 AND addressee_id = $2 AND status = 'pending'
	`, friendshipID, userID)
	return err
}
