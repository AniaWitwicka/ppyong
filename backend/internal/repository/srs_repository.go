package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
	"github.com/yourname/koreanapp-backend/internal/service"
)

// logMastery writes an activity_log entry for every group the user belongs to.
// Runs in a goroutine — failures are silently ignored so they never affect the review response.
func (r *SRSRepository) logMastery(cardID, userID string) {
	ctx := context.Background()
	var korean string
	if err := r.pool.QueryRow(ctx, `SELECT korean FROM cards WHERE id = $1`, cardID).Scan(&korean); err != nil {
		return
	}
	rows, err := r.pool.Query(ctx, `SELECT group_id FROM group_members WHERE user_id = $1`, userID)
	if err != nil {
		return
	}
	defer rows.Close()
	for rows.Next() {
		var groupID string
		if err := rows.Scan(&groupID); err != nil {
			continue
		}
		r.pool.Exec(ctx, `
			INSERT INTO activity_log (user_id, group_id, kind, subject)
			VALUES ($1, $2, 'mastered', $3)
		`, userID, groupID, korean)
	}
}

type SRSRepository struct {
	pool *pgxpool.Pool
}

func NewSRSRepository(pool *pgxpool.Pool) *SRSRepository {
	return &SRSRepository{pool: pool}
}

// Review applies one SM-2 iteration for the given user+card and persists the result.
// Returns the updated SRSProgress row.
func (r *SRSRepository) Review(ctx context.Context, cardID, userID string, knewIt bool) (*model.SRSProgress, error) {
	// Fetch current progress (or use SM-2 defaults on first review)
	var easeFactor float64
	var intervalDays, repetitions int
	err := r.pool.QueryRow(ctx, `
		SELECT ease_factor, interval_days, repetitions
		FROM srs_progress
		WHERE card_id = $1 AND user_id = $2
	`, cardID, userID).Scan(&easeFactor, &intervalDays, &repetitions)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	if errors.Is(err, pgx.ErrNoRows) {
		easeFactor = 2.5
		intervalDays = 1
		repetitions = 0
	}

	newEF, newInterval := service.SRSCalculate(easeFactor, intervalDays, repetitions, knewIt)

	newRepetitions := repetitions + 1
	if !knewIt {
		newRepetitions = 0
	}

	var sp model.SRSProgress
	err = r.pool.QueryRow(ctx, `
		INSERT INTO srs_progress
			(user_id, card_id, ease_factor, interval_days, repetitions, due_date, last_reviewed)
		VALUES
			($1, $2, $3, $4, $5, CURRENT_DATE + ($4 * INTERVAL '1 day'), NOW())
		ON CONFLICT (user_id, card_id) DO UPDATE SET
			ease_factor   = EXCLUDED.ease_factor,
			interval_days = EXCLUDED.interval_days,
			repetitions   = EXCLUDED.repetitions,
			due_date      = EXCLUDED.due_date,
			last_reviewed = EXCLUDED.last_reviewed
		RETURNING id, user_id, card_id, ease_factor, interval_days, repetitions, due_date, last_reviewed
	`, userID, cardID, newEF, newInterval, newRepetitions).Scan(
		&sp.ID, &sp.UserID, &sp.CardID, &sp.EaseFactor,
		&sp.IntervalDays, &sp.Repetitions, &sp.DueDate, &sp.LastReviewed,
	)
	if err != nil {
		return nil, err
	}

	// Log mastery the first time a card crosses the mastered threshold (interval_days < 7 → >= 7).
	if knewIt && intervalDays < 7 && newInterval >= 7 {
		go r.logMastery(cardID, userID)
	}

	// Update streak: if last_active was yesterday → streak++, today → no change, older → reset to 1
	_, _ = r.pool.Exec(ctx, `
		UPDATE users SET
			last_active = CURRENT_DATE,
			streak = CASE
				WHEN last_active = CURRENT_DATE - INTERVAL '1 day' THEN streak + 1
				WHEN last_active = CURRENT_DATE                     THEN streak
				ELSE 1
			END,
			best_streak = GREATEST(best_streak, CASE
				WHEN last_active = CURRENT_DATE - INTERVAL '1 day' THEN streak + 1
				WHEN last_active = CURRENT_DATE                     THEN streak
				ELSE 1
			END)
		WHERE id = $1
	`, userID)

	return &sp, nil
}
