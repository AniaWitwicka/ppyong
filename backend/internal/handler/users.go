package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/yourname/koreanapp-backend/internal/model"
)

// Mock data — replaced by real DB queries once the database is wired up.
// All PATCH endpoints mutate these vars so changes persist within a server session.

var mockUserProfile = model.UserProfile{
	ID:         "user-1",
	Name:       "Ania",
	Email:      "witwicka.ania@gmail.com",
	Role:       model.RoleLearner,
	Initials:   "AW",
	Streak:     7,
	BestStreak: 14,
	LastActive: time.Now().Add(-2 * time.Hour),
}

var mockStats = model.UserStats{
	MasteredCount:   34,
	LearningCount:   12,
	SessionCount:    21,
	AccuracyPercent: 78,
	WeeklyActivity:  []bool{true, true, true, true, false, true, true},
}

var mockSettings = model.UserSettings{
	NotificationsEnabled: true,
	StudyReminderTime:    "09:00",
}

var mockUsers = []model.UserSummary{
	{ID: "user-1", Name: "Ania", Initials: "AW", Role: model.RoleLearner},
	{ID: "user-2", Name: "Park Min-jun", Initials: "PM", Role: model.RoleTeacher},
	{ID: "user-3", Name: "Kim Soo-ah", Initials: "KS", Role: model.RoleLearner},
	{ID: "user-4", Name: "Lee Ji-yeon", Initials: "LJ", Role: model.RoleLearner},
	{ID: "user-5", Name: "Choi Hyun-woo", Initials: "CH", Role: model.RoleLearner},
}

// currentUserID resolves the authenticated user's ID.
// Hardcoded for now — will read from JWT claims once auth middleware is in place.
const currentUserID = "user-1"

// GetMe resolves /me to the current user's profile.
func GetMe(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, mockUserProfile)
}

// GetMyStats resolves /me/stats to the current user's stats.
func GetMyStats(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, mockStats)
}

// GetMySettings resolves /me/settings to the current user's settings.
func GetMySettings(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, mockSettings)
}

// UpdateMe handles PATCH /me — updates name and/or email for the current user.
func UpdateMe(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Name  *string `json:"name"`
		Email *string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if body.Name != nil {
		mockUserProfile.Name = *body.Name
	}
	if body.Email != nil {
		mockUserProfile.Email = *body.Email
	}
	writeJSON(w, http.StatusOK, mockUserProfile)
}

// UpdateMySettings handles PATCH /me/settings.
func UpdateMySettings(w http.ResponseWriter, r *http.Request) {
	var body struct {
		NotificationsEnabled *bool   `json:"notifications_enabled"`
		StudyReminderTime    *string `json:"study_reminder_time"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if body.NotificationsEnabled != nil {
		mockSettings.NotificationsEnabled = *body.NotificationsEnabled
	}
	if body.StudyReminderTime != nil {
		mockSettings.StudyReminderTime = *body.StudyReminderTime
	}
	writeJSON(w, http.StatusOK, mockSettings)
}

// GetUser handles GET /users/{id}.
func GetUser(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id != mockUserProfile.ID {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}
	writeJSON(w, http.StatusOK, mockUserProfile)
}

// GetUserStats handles GET /users/{id}/stats.
func GetUserStats(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id != mockUserProfile.ID {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}
	writeJSON(w, http.StatusOK, mockStats)
}

// UpdateUser handles PATCH /users/{id} — updates name and/or email.
func UpdateUser(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id != currentUserID {
		writeError(w, http.StatusForbidden, "cannot edit another user's profile")
		return
	}

	var body struct {
		Name  *string `json:"name"`
		Email *string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if body.Name != nil {
		mockUserProfile.Name = *body.Name
	}
	if body.Email != nil {
		mockUserProfile.Email = *body.Email
	}

	writeJSON(w, http.StatusOK, mockUserProfile)
}

// GetUserSettings handles GET /users/{id}/settings.
func GetUserSettings(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id != currentUserID {
		writeError(w, http.StatusForbidden, "cannot view another user's settings")
		return
	}
	writeJSON(w, http.StatusOK, mockSettings)
}

// UpdateUserSettings handles PATCH /users/{id}/settings.
func UpdateUserSettings(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id != currentUserID {
		writeError(w, http.StatusForbidden, "cannot edit another user's settings")
		return
	}

	var body struct {
		NotificationsEnabled *bool   `json:"notifications_enabled"`
		StudyReminderTime    *string `json:"study_reminder_time"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if body.NotificationsEnabled != nil {
		mockSettings.NotificationsEnabled = *body.NotificationsEnabled
	}
	if body.StudyReminderTime != nil {
		mockSettings.StudyReminderTime = *body.StudyReminderTime
	}

	writeJSON(w, http.StatusOK, mockSettings)
}

// ListUsers handles GET /users — returns all group members (used by sharing dialog).
func ListUsers(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, mockUsers)
}
