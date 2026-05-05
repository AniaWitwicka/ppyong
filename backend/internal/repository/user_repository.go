package repository

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

type UserRepository struct {
	pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

func (r *UserRepository) GetByID(ctx context.Context, id string) (*model.UserProfile, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, email, name, role, initials, streak, best_streak, last_active
		FROM users WHERE id = $1
	`, id)

	var p model.UserProfile
	var lastActive *time.Time
	if err := row.Scan(&p.ID, &p.Email, &p.Name, &p.Role, &p.Initials,
		&p.Streak, &p.BestStreak, &lastActive); err != nil {
		return nil, err
	}
	if lastActive != nil {
		p.LastActive = *lastActive
	}
	return &p, nil
}

func (r *UserRepository) GetStats(ctx context.Context, id string) (*model.UserStats, error) {
	// Mastered: interval >= 7 days
	var mastered, learning int
	r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM srs_progress WHERE user_id = $1 AND interval_days >= 7
	`, id).Scan(&mastered)

	// Learning: has been reviewed but not yet mastered
	r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM srs_progress WHERE user_id = $1 AND interval_days < 7
	`, id).Scan(&learning)

	// Weekly activity: which days this Mon–Sun the user reviewed at least one card
	rows, err := r.pool.Query(ctx, `
		SELECT DISTINCT EXTRACT(DOW FROM last_reviewed)::int
		FROM srs_progress
		WHERE user_id = $1
		  AND last_reviewed >= date_trunc('week', NOW())
		  AND last_reviewed < date_trunc('week', NOW()) + INTERVAL '7 days'
	`, id)

	weekly := make([]bool, 7)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var dow int // 0=Sun,1=Mon,...,6=Sat
			if rows.Scan(&dow) == nil {
				// Convert to index 0=Mon, 6=Sun
				idx := (dow + 6) % 7
				weekly[idx] = true
			}
		}
	}

	return &model.UserStats{
		MasteredCount:   mastered,
		LearningCount:   learning,
		SessionCount:    0, // tracked once sessions table exists
		AccuracyPercent: 0, // tracked once review history exists
		WeeklyActivity:  weekly,
	}, nil
}

func (r *UserRepository) GetSettings(ctx context.Context, id string) (*model.UserSettings, error) {
	var s model.UserSettings
	err := r.pool.QueryRow(ctx, `
		SELECT notifications_enabled, study_reminder_time
		FROM user_settings WHERE user_id = $1
	`, id).Scan(&s.NotificationsEnabled, &s.StudyReminderTime)
	if err != nil {
		// Return defaults if no row yet
		return &model.UserSettings{
			NotificationsEnabled: true,
			StudyReminderTime:    "09:00",
		}, nil
	}
	return &s, nil
}

func (r *UserRepository) Update(ctx context.Context, id string, name, email *string) (*model.UserProfile, error) {
	row := r.pool.QueryRow(ctx, `
		UPDATE users SET
			name  = COALESCE($2, name),
			email = COALESCE($3, email)
		WHERE id = $1
		RETURNING id, email, name, role, initials, streak, best_streak, last_active
	`, id, name, email)

	var p model.UserProfile
	var lastActive *time.Time
	if err := row.Scan(&p.ID, &p.Email, &p.Name, &p.Role, &p.Initials,
		&p.Streak, &p.BestStreak, &lastActive); err != nil {
		return nil, err
	}
	if lastActive != nil {
		p.LastActive = *lastActive
	}
	return &p, nil
}

func (r *UserRepository) UpdateSettings(ctx context.Context, id string, notif *bool, reminderTime *string) (*model.UserSettings, error) {
	var s model.UserSettings
	err := r.pool.QueryRow(ctx, `
		INSERT INTO user_settings (user_id, notifications_enabled, study_reminder_time)
		VALUES ($1,
			COALESCE($2, TRUE),
			COALESCE($3, '09:00'))
		ON CONFLICT (user_id) DO UPDATE SET
			notifications_enabled = COALESCE($2, user_settings.notifications_enabled),
			study_reminder_time   = COALESCE($3, user_settings.study_reminder_time)
		RETURNING notifications_enabled, study_reminder_time
	`, id, notif, reminderTime).Scan(&s.NotificationsEnabled, &s.StudyReminderTime)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *UserRepository) List(ctx context.Context) ([]model.UserSummary, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, initials, role FROM users ORDER BY name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []model.UserSummary
	for rows.Next() {
		var u model.UserSummary
		if err := rows.Scan(&u.ID, &u.Name, &u.Initials, &u.Role); err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, nil
}
