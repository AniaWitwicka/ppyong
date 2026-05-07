package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

type CollectionRepository struct {
	pool *pgxpool.Pool
}

func NewCollectionRepository(pool *pgxpool.Pool) *CollectionRepository {
	return &CollectionRepository{pool: pool}
}

// summaryQuery selects all computed fields for one or more collections.
// It joins decks, cards, and srs_progress to compute counts and progress.
const summaryQuery = `
	SELECT
		c.id,
		c.title       AS name,
		c.emoji,
		c.color,
		COUNT(DISTINCT d.id)                                        AS deck_count,
		COUNT(DISTINCT ca.id)                                       AS word_count,
		COUNT(DISTINCT CASE WHEN sp.due_date <= CURRENT_DATE
		                    AND sp.user_id = $1 THEN ca.id END)     AS due_count,
		CASE WHEN COUNT(DISTINCT ca.id) = 0 THEN 0
		     ELSE COUNT(DISTINCT CASE WHEN sp.interval_days >= 7
		                               AND sp.user_id = $1 THEN ca.id END)::float
		          / COUNT(DISTINCT ca.id)
		END                                                         AS progress
	FROM collections c
	LEFT JOIN decks d   ON d.collection_id = c.id
	LEFT JOIN cards ca  ON ca.deck_id = d.id
	LEFT JOIN srs_progress sp ON sp.card_id = ca.id AND sp.user_id = $1
`

func (r *CollectionRepository) List(ctx context.Context, userID string) ([]model.CollectionSummary, error) {
	rows, err := r.pool.Query(ctx, summaryQuery+`
		WHERE c.created_by = $1 OR EXISTS (
			SELECT 1 FROM decks d2
			JOIN cards ca2 ON ca2.deck_id = d2.id
			JOIN srs_progress sp2 ON sp2.card_id = ca2.id AND sp2.user_id = $1
			WHERE d2.collection_id = c.id
		)
		GROUP BY c.id, c.title, c.emoji, c.color
		ORDER BY c.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var collections []model.CollectionSummary
	for rows.Next() {
		var c model.CollectionSummary
		if err := rows.Scan(&c.ID, &c.Name, &c.Emoji, &c.Color,
			&c.DeckCount, &c.WordCount, &c.DueCount, &c.Progress); err != nil {
			return nil, err
		}
		collections = append(collections, c)
	}
	if collections == nil {
		collections = []model.CollectionSummary{}
	}
	return collections, nil
}

func (r *CollectionRepository) GetByID(ctx context.Context, id, userID string) (*model.CollectionSummary, error) {
	var c model.CollectionSummary
	err := r.pool.QueryRow(ctx, summaryQuery+`
		WHERE c.id = $2
		GROUP BY c.id, c.title, c.emoji, c.color
	`, userID, id).Scan(&c.ID, &c.Name, &c.Emoji, &c.Color,
		&c.DeckCount, &c.WordCount, &c.DueCount, &c.Progress)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *CollectionRepository) Create(ctx context.Context, userID, name, emoji, color string) (*model.CollectionSummary, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO collections (title, emoji, color, created_by)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, name, emoji, color, userID).Scan(&id)
	if err != nil {
		return nil, err
	}
	return &model.CollectionSummary{
		ID: id, Name: name, Emoji: emoji, Color: color,
	}, nil
}

func (r *CollectionRepository) Update(ctx context.Context, id string, name, emoji, color *string) (*model.CollectionSummary, error) {
	_, err := r.pool.Exec(ctx, `
		UPDATE collections SET
			title = COALESCE($2, title),
			emoji = COALESCE($3, emoji),
			color = COALESCE($4, color)
		WHERE id = $1
	`, id, name, emoji, color)
	if err != nil {
		return nil, err
	}
	// Fetch updated row without user-specific stats (no userID available here)
	var c model.CollectionSummary
	err = r.pool.QueryRow(ctx, `
		SELECT id, title, emoji, color FROM collections WHERE id = $1
	`, id).Scan(&c.ID, &c.Name, &c.Emoji, &c.Color)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *CollectionRepository) Delete(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM collections WHERE id = $1`, id)
	return err
}

func (r *CollectionRepository) Share(ctx context.Context, collectionID string, memberIDs []string) ([]model.UserSummary, error) {
	rows, err := r.pool.Query(ctx, `SELECT id, name, initials, role FROM users WHERE id = ANY($1)`, memberIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var shared []model.UserSummary
	for rows.Next() {
		var u model.UserSummary
		if err := rows.Scan(&u.ID, &u.Name, &u.Initials, &u.Role); err != nil {
			return nil, err
		}
		shared = append(shared, u)
	}
	if shared == nil {
		shared = []model.UserSummary{}
	}
	return shared, nil
}
