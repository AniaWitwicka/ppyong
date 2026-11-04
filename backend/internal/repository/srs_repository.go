package repository

import (
	"context"
	"errors"
	"fmt"

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
	var notDueYet bool
	var daysSinceReview int
	err := r.pool.QueryRow(ctx, `
		SELECT ease_factor, interval_days, repetitions, due_date > CURRENT_DATE,
		       COALESCE(CURRENT_DATE - last_reviewed::date, 0)
		FROM srs_progress
		WHERE card_id = $1 AND user_id = $2
	`, cardID, userID).Scan(&easeFactor, &intervalDays, &repetitions, &notDueYet, &daysSinceReview)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}

	// Early "knew it" (before the due date): the level only grows as much as
	// the real time since the last review supports. Passing a word three times
	// in a day no longer makes it "mastered" (HRHTA-115). "Again" always counts.
	if err == nil && knewIt && notDueYet {
		// A missed word answered right again: back to learning, still due
		// tomorrow, so it stops jumping to the front of every session.
		if repetitions == 0 {
			return r.save(ctx, cardID, userID, easeFactor, intervalDays, 1, intervalDays)
		}
		earned, grows := service.SRSEarlyInterval(intervalDays, daysSinceReview, easeFactor)
		if !grows {
			return r.notePractice(ctx, cardID, userID)
		}
		return r.save(ctx, cardID, userID, easeFactor, earned, repetitions+1, intervalDays)
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
	return r.save(ctx, cardID, userID, newEF, newInterval, newRepetitions, intervalDays)
}

// save writes the new schedule, logs mastery when a word first reaches a
// 7+ day interval, and counts the day toward the streak.
func (r *SRSRepository) save(ctx context.Context, cardID, userID string,
	newEF float64, newInterval, newRepetitions, oldInterval int) (*model.SRSProgress, error) {
	var sp model.SRSProgress
	err := r.pool.QueryRow(ctx, `
		INSERT INTO srs_progress
			(user_id, card_id, ease_factor, interval_days, repetitions, due_date, last_reviewed)
		VALUES
			($1, $2, $3, $4, $5, CURRENT_DATE + ($4::int * INTERVAL '1 day'), NOW())
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
	if oldInterval < 7 && newInterval >= 7 {
		go r.logMastery(cardID, userID)
	}

	_ = r.touchStreak(ctx, userID)

	return &sp, nil
}

// notePractice records an early "knew it": only last_reviewed changes (so
// practice rotates) and the day counts toward the streak.
func (r *SRSRepository) notePractice(ctx context.Context, cardID, userID string) (*model.SRSProgress, error) {
	var sp model.SRSProgress
	err := r.pool.QueryRow(ctx, `
		UPDATE srs_progress SET last_reviewed = NOW()
		WHERE card_id = $1 AND user_id = $2
		RETURNING id, user_id, card_id, ease_factor, interval_days, repetitions, due_date, last_reviewed
	`, cardID, userID).Scan(
		&sp.ID, &sp.UserID, &sp.CardID, &sp.EaseFactor,
		&sp.IntervalDays, &sp.Repetitions, &sp.DueDate, &sp.LastReviewed,
	)
	if err != nil {
		return nil, err
	}
	_ = r.touchStreak(ctx, userID)
	return &sp, nil
}

// touchStreak marks the user active today: if last_active was yesterday → streak++,
// today → no change, older → reset to 1.
func (r *SRSRepository) touchStreak(ctx context.Context, userID string) error {
	_, err := r.pool.Exec(ctx, `
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
	return err
}

// ErrDeckNotFound is returned by LogPractice when the deck does not exist.
var ErrDeckNotFound = errors.New("deck not found")

// LogPractice records a finished game: it counts toward the streak and writes a
// 'match' activity_log entry ("matched N words in <deck>") for every group the
// user belongs to. Word progress is not touched here.
func (r *SRSRepository) LogPractice(ctx context.Context, userID, deckID string, matched int) error {
	var deckTitle string
	err := r.pool.QueryRow(ctx, `SELECT title FROM decks WHERE id = $1`, deckID).Scan(&deckTitle)
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrDeckNotFound
	}
	if err != nil {
		return err
	}

	if err := r.touchStreak(ctx, userID); err != nil {
		return err
	}

	_, err = r.pool.Exec(ctx, `
		INSERT INTO activity_log (user_id, group_id, kind, subject, target)
		SELECT $1, gm.group_id, 'match', $2, $3
		FROM group_members gm
		WHERE gm.user_id = $1
	`, userID, deckTitle, fmt.Sprintf("%d", matched))
	return err
}
