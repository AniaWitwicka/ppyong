package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

type DeckRepository struct {
	pool *pgxpool.Pool
}

func NewDeckRepository(pool *pgxpool.Pool) *DeckRepository {
	return &DeckRepository{pool: pool}
}

// deckSummaryQuery computes mastered/learning/new counts per deck for a given user.
const deckSummaryQuery = `
	SELECT
		d.id,
		d.title AS name,
		COUNT(DISTINCT ca.id)                                                   AS card_count,
		COUNT(DISTINCT CASE WHEN sp.interval_days >= 7
		                    AND sp.user_id = $1 THEN ca.id END)                 AS mastered_count,
		COUNT(DISTINCT CASE WHEN sp.interval_days < 7
		                    AND sp.user_id = $1
		                    AND sp.repetitions > 0 THEN ca.id END)              AS learning_count,
		COUNT(DISTINCT CASE WHEN sp.card_id IS NULL
		                    OR (sp.user_id = $1 AND sp.repetitions = 0)
		                    THEN ca.id END)                                      AS new_count
	FROM decks d
	LEFT JOIN cards ca ON ca.deck_id = d.id
	LEFT JOIN srs_progress sp ON sp.card_id = ca.id AND sp.user_id = $1
`

func (r *DeckRepository) List(ctx context.Context, collectionID, userID string) ([]model.DeckSummary, error) {
	rows, err := r.pool.Query(ctx, deckSummaryQuery+`
		WHERE d.collection_id = $2
		GROUP BY d.id, d.title
		ORDER BY d.created_at ASC
	`, userID, collectionID)
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

func (r *DeckRepository) GetByID(ctx context.Context, id, userID string) (*model.DeckDetail, error) {
	var d model.DeckDetail
	err := r.pool.QueryRow(ctx, `
		SELECT
			d.id,
			d.title AS name,
			COALESCE(d.description, '') AS description,
			d.collection_id,
			c.title AS collection_name,
			COUNT(DISTINCT ca.id)                                                   AS card_count,
			COUNT(DISTINCT CASE WHEN sp.interval_days >= 7
			                    AND sp.user_id = $2 THEN ca.id END)                 AS mastered_count,
			COUNT(DISTINCT CASE WHEN sp.interval_days < 7
			                    AND sp.user_id = $2
			                    AND sp.repetitions > 0 THEN ca.id END)              AS learning_count,
			COUNT(DISTINCT CASE WHEN sp.card_id IS NULL
			                    OR (sp.user_id = $2 AND sp.repetitions = 0)
			                    THEN ca.id END)                                      AS new_count
		FROM decks d
		JOIN collections c ON c.id = d.collection_id
		LEFT JOIN cards ca ON ca.deck_id = d.id
		LEFT JOIN srs_progress sp ON sp.card_id = ca.id AND sp.user_id = $2
		WHERE d.id = $1
		GROUP BY d.id, d.title, d.description, d.collection_id, c.title
	`, id, userID).Scan(
		&d.ID, &d.Name, &d.Description, &d.CollectionID, &d.CollectionName,
		&d.CardCount, &d.MasteredCount, &d.LearningCount, &d.NewCount,
	)
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *DeckRepository) Create(ctx context.Context, collectionID, userID, name, description string) (*model.DeckSummary, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO decks (collection_id, title, description, created_by)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, collectionID, name, description, userID).Scan(&id)
	if err != nil {
		return nil, err
	}
	return &model.DeckSummary{ID: id, Name: name}, nil
}

func (r *DeckRepository) Update(ctx context.Context, id string, name, description, collectionID *string) (*model.DeckDetail, error) {
	_, err := r.pool.Exec(ctx, `
		UPDATE decks SET
			title         = COALESCE($2, title),
			description   = COALESCE($3, description),
			collection_id = COALESCE($4, collection_id)
		WHERE id = $1
	`, id, name, description, collectionID)
	if err != nil {
		return nil, err
	}
	var d model.DeckDetail
	err = r.pool.QueryRow(ctx, `
		SELECT d.id, d.title, COALESCE(d.description,''), d.collection_id, c.title
		FROM decks d JOIN collections c ON c.id = d.collection_id
		WHERE d.id = $1
	`, id).Scan(&d.ID, &d.Name, &d.Description, &d.CollectionID, &d.CollectionName)
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *DeckRepository) Delete(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM decks WHERE id = $1`, id)
	return err
}

func (r *DeckRepository) Share(ctx context.Context, deckID string, memberIDs []string) ([]model.UserSummary, error) {
	// For now, return the users that were shared with (deck_shares table is future work).
	// Just look up the users by ID to return summary info.
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, initials, role FROM users WHERE id = ANY($1)
	`, memberIDs)
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
