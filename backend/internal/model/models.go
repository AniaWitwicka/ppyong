package model

import (
	"time"
)

type Role string

const (
	RoleLearner Role = "learner"
	RoleTeacher Role = "teacher"
)

type User struct {
	ID         string     `json:"id" db:"id"`
	Email      string     `json:"email" db:"email"`
	Name       string     `json:"name" db:"name"`
	Role       Role       `json:"role" db:"role"`
	Streak     int        `json:"streak" db:"streak"`
	LastActive *time.Time `json:"last_active" db:"last_active"`
	CreatedAt  time.Time  `json:"created_at" db:"created_at"`
}

// UserProfile is the full profile response returned to the owner, their teacher, or admin.
type UserProfile struct {
	ID         string    `json:"id"`
	Name       string    `json:"name"`
	Email      string    `json:"email"`
	Role       Role      `json:"role"`
	Initials   string    `json:"initials"`
	Streak     int       `json:"streak"`
	BestStreak int       `json:"best_streak"`
	LastActive time.Time `json:"last_active"`
}

// UserSummary is minimal info returned in list endpoints (e.g. sharing dialog).
type UserSummary struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Initials string `json:"initials"`
	Role     Role   `json:"role"`
}

// UserStats holds learning statistics for a user.
type UserStats struct {
	MasteredCount   int    `json:"mastered_count"`
	LearningCount   int    `json:"learning_count"`
	SessionCount    int    `json:"session_count"`
	AccuracyPercent int    `json:"accuracy_percent"`
	WeeklyActivity  []bool `json:"weekly_activity"` // index 0 = Mon, 6 = Sun
}

// UserSettings holds user preferences.
type UserSettings struct {
	NotificationsEnabled bool   `json:"notifications_enabled"`
	StudyReminderTime    string `json:"study_reminder_time"` // "HH:MM" 24h
}

type Collection struct {
	ID          string    `json:"id" db:"id"`
	Title       string    `json:"title" db:"title"`
	Description string    `json:"description" db:"description"`
	CreatedBy   string    `json:"created_by" db:"created_by"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// CollectionSummary is returned by GET /collections and GET /collections/:id.
type CollectionSummary struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	Emoji     string  `json:"emoji"`
	Color     string  `json:"color"` // hex e.g. "#99B7F5"
	DeckCount int     `json:"deck_count"`
	WordCount int     `json:"word_count"`
	DueCount  int     `json:"due_count"`
	Progress  float64 `json:"progress"` // 0.0–1.0
}

// CreateCollectionRequest is the body for POST /collections.
type CreateCollectionRequest struct {
	Name  string `json:"name"`
	Emoji string `json:"emoji"`
	Color string `json:"color"`
}

// UpdateCollectionRequest is the body for PATCH /collections/:id.
type UpdateCollectionRequest struct {
	Name  *string `json:"name"`
	Emoji *string `json:"emoji"`
	Color *string `json:"color"`
}

type Deck struct {
	ID           string    `json:"id" db:"id"`
	CollectionID string    `json:"collection_id" db:"collection_id"`
	Title        string    `json:"title" db:"title"`
	Description  string    `json:"description" db:"description"`
	CreatedBy    string    `json:"created_by" db:"created_by"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

// DeckSummary is returned by GET /collections/:id/decks.
type DeckSummary struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	CardCount     int    `json:"card_count"`
	MasteredCount int    `json:"mastered_count"`
	LearningCount int    `json:"learning_count"`
	NewCount      int    `json:"new_count"`
}

// DeckDetail is returned by GET /decks/:id.
type DeckDetail struct {
	ID             string `json:"id"`
	Name           string `json:"name"`
	Description    string `json:"description"`
	CollectionID   string `json:"collection_id"`
	CollectionName string `json:"collection_name"`
	CardCount      int    `json:"card_count"`
	MasteredCount  int    `json:"mastered_count"`
	LearningCount  int    `json:"learning_count"`
	NewCount       int    `json:"new_count"`
}

// CreateDeckRequest is the body for POST /collections/:id/decks.
type CreateDeckRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

// UpdateDeckRequest is the body for PATCH /decks/:id.
type UpdateDeckRequest struct {
	Name         *string `json:"name"`
	Description  *string `json:"description"`
	CollectionID *string `json:"collection_id"`
}

// ShareDeckRequest is the body for POST /decks/:id/share.
type ShareDeckRequest struct {
	MemberIDs []string `json:"member_ids"`
}

type Card struct {
	ID           string    `json:"id" db:"id"`
	DeckID       string    `json:"deck_id" db:"deck_id"`
	Korean       string    `json:"korean" db:"korean"`
	Romanisation string    `json:"romanisation" db:"romanisation"`
	Translation  string    `json:"translation" db:"translation"`
	Notes        string    `json:"notes" db:"notes"`
	Position     int       `json:"position" db:"position"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

type SRSProgress struct {
	ID           string     `json:"id" db:"id"`
	UserID       string     `json:"user_id" db:"user_id"`
	CardID       string     `json:"card_id" db:"card_id"`
	IntervalDays int        `json:"interval_days" db:"interval_days"`
	EaseFactor   float64    `json:"ease_factor" db:"ease_factor"`
	Repetitions  int        `json:"repetitions" db:"repetitions"`
	DueDate      time.Time  `json:"due_date" db:"due_date"`
	LastReviewed *time.Time `json:"last_reviewed" db:"last_reviewed"`
}
