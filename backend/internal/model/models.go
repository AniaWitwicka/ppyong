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
	DueCount        int    `json:"due_count"`
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

// CardSummary is returned by GET /decks/:id/cards.
type CardSummary struct {
	ID           string     `json:"id"`
	Korean       string     `json:"korean"`
	Romanisation string     `json:"romanisation"`
	Translation  string     `json:"translation"`
	Notes        string     `json:"notes"`
	Status       string     `json:"status"` // "new" | "learning" | "mastered"
	DueDate      *time.Time `json:"due_date"`
}

// WeakCard is returned by GET /me/weak-words — cards the user struggles with.
type WeakCard struct {
	ID             string  `json:"id"`
	Korean         string  `json:"korean"`
	Romanisation   string  `json:"romanisation"`
	Translation    string  `json:"translation"`
	Notes          string  `json:"notes"`
	DeckID         string  `json:"deck_id"`
	DeckName       string  `json:"deck_name"`
	CollectionName string  `json:"collection_name"`
	EaseFactor     float64 `json:"ease_factor"`
	IntervalDays   int     `json:"interval_days"`
}

// ── Groups ────────────────────────────────────────────────────────────────

type MemberAvatar struct {
	Initials string `json:"initials"`
	Color    string `json:"color"`
}

type GroupSummary struct {
	ID          string         `json:"id"`
	Name        string         `json:"name"`
	Emoji       string         `json:"emoji"`
	Color       string         `json:"color"`
	MemberCount int            `json:"member_count"`
	DeckCount   int            `json:"deck_count"`
	LastActive  *time.Time     `json:"last_active"`
	Avatars     []MemberAvatar `json:"avatars"`
}

type GroupMember struct {
	UserID   string  `json:"user_id"`
	Name     string  `json:"name"`
	Initials string  `json:"initials"`
	Role     string  `json:"role"` // "owner" | "member"
	Progress float64 `json:"progress"`
}

type GroupDetail struct {
	ID          string        `json:"id"`
	Name        string        `json:"name"`
	Emoji       string        `json:"emoji"`
	Color       string        `json:"color"`
	MemberCount int           `json:"member_count"`
	DeckCount   int           `json:"deck_count"`
	IsOwner     bool          `json:"is_owner"`
	Members     []GroupMember `json:"members"`
	SharedDecks []DeckSummary `json:"shared_decks"`
}

type CreateGroupRequest struct {
	Name  string `json:"name"`
	Emoji string `json:"emoji"`
	Color string `json:"color"`
}

type UpdateGroupRequest struct {
	Name  *string `json:"name"`
	Emoji *string `json:"emoji"`
	Color *string `json:"color"`
}

// ── Invites ───────────────────────────────────────────────────────────────

type Invite struct {
	ID           string    `json:"id"`
	GroupID      string    `json:"group_id"`
	GroupName    string    `json:"group_name"`
	GroupEmoji   string    `json:"group_emoji"`
	GroupColor   string    `json:"group_color"`
	InviterName  string    `json:"inviter_name"`
	InviteeEmail string    `json:"invitee_email"`
	Status       string    `json:"status"`
	ExpiresAt    time.Time `json:"expires_at"`
	CreatedAt    time.Time `json:"created_at"`
}

type InviteListResponse struct {
	Incoming []Invite `json:"incoming"`
	Sent     []Invite `json:"sent"`
}

// ── Friends ───────────────────────────────────────────────────────────────

type Friend struct {
	FriendshipID string `json:"friendship_id"`
	UserID       string `json:"user_id"`
	Name         string `json:"name"`
	Initials     string `json:"initials"`
	Role         Role   `json:"role"`
	Streak       int    `json:"streak"`
	WordCount    int    `json:"word_count"`
	DueCount     int    `json:"due_count"`
}

// ── Teacher ───────────────────────────────────────────────────────────────

type ActivityEvent struct {
	ID        string    `json:"id"`
	UserName  string    `json:"user_name"`
	Initials  string    `json:"initials"`
	Kind      string    `json:"kind"`    // "mastered" | "streak" | "quiz" | "weak"
	Subject   string    `json:"subject"` // Korean word or deck name
	Target    string    `json:"target"`
	CreatedAt time.Time `json:"created_at"`
}

type AttentionItem struct {
	UserID    string `json:"user_id"`
	Name      string `json:"name"`
	Initials  string `json:"initials"`
	Color     string `json:"color"`
	GroupID   string `json:"group_id"`
	GroupName string `json:"group_name"`
	Reason    string `json:"reason"`
	Severity  string `json:"severity"` // "urgent" | "warn"
}

type TeacherGroupSummary struct {
	ID          string         `json:"id"`
	Name        string         `json:"name"`
	Emoji       string         `json:"emoji"`
	Color       string         `json:"color"`
	MemberCount int            `json:"member_count"`
	DeckCount   int            `json:"deck_count"`
	LastActive  *time.Time     `json:"last_active"`
	Avatars     []MemberAvatar `json:"avatars"`
	ClassAvg    int            `json:"class_avg"`
}

type StudentRosterItem struct {
	UserID          string `json:"user_id"`
	Name            string `json:"name"`
	Initials        string `json:"initials"`
	Color           string `json:"color"`
	Streak          int    `json:"streak"`
	DueCount        int    `json:"due_count"`
	ProgressPercent int    `json:"progress_percent"`
}

type TeacherDashboard struct {
	ActiveToday    int                   `json:"active_today"`
	TotalStudents  int                   `json:"total_students"`
	AvgAccuracy    int                   `json:"avg_accuracy"`
	DecksAssigned  int                   `json:"decks_assigned"`
	Attention      []AttentionItem       `json:"attention"`
	Groups         []TeacherGroupSummary `json:"groups"`
	RecentActivity []ActivityEvent       `json:"recent_activity"`
}

// ── Import ────────────────────────────────────────────────────────────────

// ParsedCard is the unit produced by the import parser and accepted by bulk-create.
type ParsedCard struct {
	Korean       string `json:"korean"`
	Translation  string `json:"translation"`
	Romanisation string `json:"romanisation"`
	Notes        string `json:"notes"`
}

// ParseResult is returned by POST /import/preview.
type ParseResult struct {
	DetectedFormat string       `json:"detected_format"`
	ParsedCards    []ParsedCard `json:"parsed_cards"`
	TotalCount     int          `json:"total_count"`
}

// ── SRS ───────────────────────────────────────────────────────────────────

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
