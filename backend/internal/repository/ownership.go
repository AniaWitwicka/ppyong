package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotFound means the collection, deck or card does not exist.
var ErrNotFound = errors.New("not found")

// Who may change content: whoever created its collection, and admins (they
// look after all the decks). Everyone else it is shared with can study it,
// nothing more.

// canEditExpr is true when $2 owns the collection c or is an admin.
const canEditExpr = `(c.created_by = $2 OR EXISTS (
		SELECT 1 FROM users u WHERE u.id = $2 AND u.role = 'admin'))`

const canEditCollectionSQL = `SELECT ` + canEditExpr + ` FROM collections c WHERE c.id = $1`

const canEditDeckSQL = `
	SELECT ` + canEditExpr + ` FROM decks d
	JOIN collections c ON c.id = d.collection_id
	WHERE d.id = $1`

const canEditCardSQL = `
	SELECT ` + canEditExpr + ` FROM cards ca
	JOIN decks d ON d.id = ca.deck_id
	JOIN collections c ON c.id = d.collection_id
	WHERE ca.id = $1`

// canEdit returns ErrNotFound when nothing matches id, otherwise whether
// userID may change it.
func canEdit(ctx context.Context, pool *pgxpool.Pool, query, id, userID string) (bool, error) {
	var ok bool
	err := pool.QueryRow(ctx, query, id, userID).Scan(&ok)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, ErrNotFound
	}
	if err != nil {
		// A malformed id (not a UUID) can't match anything.
		var pgErr interface{ SQLState() string }
		if errors.As(err, &pgErr) && pgErr.SQLState() == "22P02" {
			return false, ErrNotFound
		}
		return false, err
	}
	return ok, nil
}

func (r *CollectionRepository) CanEdit(ctx context.Context, collectionID, userID string) (bool, error) {
	return canEdit(ctx, r.pool, canEditCollectionSQL, collectionID, userID)
}

func (r *DeckRepository) CanEditCollection(ctx context.Context, collectionID, userID string) (bool, error) {
	return canEdit(ctx, r.pool, canEditCollectionSQL, collectionID, userID)
}

func (r *DeckRepository) CanEdit(ctx context.Context, deckID, userID string) (bool, error) {
	return canEdit(ctx, r.pool, canEditDeckSQL, deckID, userID)
}

func (r *CardRepository) CanEditDeck(ctx context.Context, deckID, userID string) (bool, error) {
	return canEdit(ctx, r.pool, canEditDeckSQL, deckID, userID)
}

func (r *CardRepository) CanEdit(ctx context.Context, cardID, userID string) (bool, error) {
	return canEdit(ctx, r.pool, canEditCardSQL, cardID, userID)
}
