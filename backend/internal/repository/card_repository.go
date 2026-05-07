package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

type CardRepository struct {
	pool *pgxpool.Pool
}

func NewCardRepository(pool *pgxpool.Pool) *CardRepository {
	return &CardRepository{pool: pool}
}

// cardStatus derives mastered/learning/new from srs_progress for a given user.
// mastered: interval_days >= 7
// learning: reviewed at least once but interval_days < 7
// new: no srs_progress row
const cardSelectCols = `
	ca.id,
	ca.korean,
	COALESCE(ca.romanisation, '') AS romanisation,
	ca.translation,
	COALESCE(ca.notes, '') AS notes,
	CASE
		WHEN sp.card_id IS NULL OR sp.repetitions = 0 THEN 'new'
		WHEN sp.interval_days >= 7 THEN 'mastered'
		ELSE 'learning'
	END AS status,
	sp.due_date
`

func (r *CardRepository) List(ctx context.Context, deckID, userID, scope string) ([]model.CardSummary, error) {
	q := fmt.Sprintf(`
		SELECT %s
		FROM cards ca
		LEFT JOIN srs_progress sp ON sp.card_id = ca.id AND sp.user_id = $2
		WHERE ca.deck_id = $1
	`, cardSelectCols)

	switch scope {
	case "due":
		q += " AND sp.due_date <= CURRENT_DATE"
	case "weak":
		q += " AND sp.ease_factor < 2.0 AND sp.repetitions > 0"
	}

	q += " ORDER BY ca.position ASC, ca.created_at ASC"

	rows, err := r.pool.Query(ctx, q, deckID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cards []model.CardSummary
	for rows.Next() {
		var c model.CardSummary
		if err := rows.Scan(&c.ID, &c.Korean, &c.Romanisation, &c.Translation, &c.Notes, &c.Status, &c.DueDate); err != nil {
			return nil, err
		}
		cards = append(cards, c)
	}
	if cards == nil {
		cards = []model.CardSummary{}
	}
	return cards, nil
}

func (r *CardRepository) Create(ctx context.Context, deckID, korean, romanisation, translation, notes string) (*model.CardSummary, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO cards (deck_id, korean, romanisation, translation, notes, position)
		VALUES ($1, $2, $3, $4, $5,
			(SELECT COALESCE(MAX(position), 0) + 1 FROM cards WHERE deck_id = $1))
		RETURNING id
	`, deckID, korean, romanisation, translation, notes).Scan(&id)
	if err != nil {
		return nil, err
	}
	return &model.CardSummary{
		ID:           id,
		Korean:       korean,
		Romanisation: romanisation,
		Translation:  translation,
		Notes:        notes,
		Status:       "new",
	}, nil
}

func (r *CardRepository) Update(ctx context.Context, id string, korean, romanisation, translation, notes *string) (*model.CardSummary, error) {
	_, err := r.pool.Exec(ctx, `
		UPDATE cards SET
			korean       = COALESCE($2, korean),
			romanisation = COALESCE($3, romanisation),
			translation  = COALESCE($4, translation),
			notes        = COALESCE($5, notes)
		WHERE id = $1
	`, id, korean, romanisation, translation, notes)
	if err != nil {
		return nil, err
	}
	var c model.CardSummary
	err = r.pool.QueryRow(ctx, `
		SELECT id, korean, COALESCE(romanisation,''), translation, COALESCE(notes,''), 'new', NULL
		FROM cards WHERE id = $1
	`, id).Scan(&c.ID, &c.Korean, &c.Romanisation, &c.Translation, &c.Notes, &c.Status, &c.DueDate)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *CardRepository) Delete(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM cards WHERE id = $1`, id)
	return err
}
