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

type Collection struct {
	ID          string    `json:"id" db:"id"`
	Title       string    `json:"title" db:"title"`
	Description string    `json:"description" db:"description"`
	CreatedBy   string    `json:"created_by" db:"created_by"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type Deck struct {
	ID           string    `json:"id" db:"id"`
	CollectionID string    `json:"collection_id" db:"collection_id"`
	Title        string    `json:"title" db:"title"`
	Description  string    `json:"description" db:"description"`
	CreatedBy    string    `json:"created_by" db:"created_by"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
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
