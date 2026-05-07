package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/auth"
	"github.com/yourname/koreanapp-backend/internal/repository"
)

func userIDFromContext(r *http.Request) string {
	id, _ := r.Context().Value(auth.UserIDKey).(string)
	return id
}

type UserHandler struct {
	repo *repository.UserRepository
}

func NewUserHandler(repo *repository.UserRepository) *UserHandler {
	return &UserHandler{repo: repo}
}

func (h *UserHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	profile, err := h.repo.GetByID(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func (h *UserHandler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name  *string `json:"name"`
		Email *string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	profile, err := h.repo.Update(r.Context(), userIDFromContext(r), req.Name, req.Email)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update profile")
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func (h *UserHandler) GetMyStats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.repo.GetStats(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load stats")
		return
	}
	writeJSON(w, http.StatusOK, stats)
}

func (h *UserHandler) GetMySettings(w http.ResponseWriter, r *http.Request) {
	settings, err := h.repo.GetSettings(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load settings")
		return
	}
	writeJSON(w, http.StatusOK, settings)
}

func (h *UserHandler) UpdateMySettings(w http.ResponseWriter, r *http.Request) {
	var req struct {
		NotificationsEnabled *bool   `json:"notifications_enabled"`
		StudyReminderTime    *string `json:"study_reminder_time"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	settings, err := h.repo.UpdateSettings(r.Context(), userIDFromContext(r), req.NotificationsEnabled, req.StudyReminderTime)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update settings")
		return
	}
	writeJSON(w, http.StatusOK, settings)
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	profile, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func (h *UserHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var req struct {
		Name  *string `json:"name"`
		Email *string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	profile, err := h.repo.Update(r.Context(), id, req.Name, req.Email)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update user")
		return
	}
	writeJSON(w, http.StatusOK, profile)
}

func (h *UserHandler) GetUserStats(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	stats, err := h.repo.GetStats(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load stats")
		return
	}
	writeJSON(w, http.StatusOK, stats)
}

func (h *UserHandler) GetUserSettings(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	settings, err := h.repo.GetSettings(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load settings")
		return
	}
	writeJSON(w, http.StatusOK, settings)
}

func (h *UserHandler) UpdateUserSettings(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var req struct {
		NotificationsEnabled *bool   `json:"notifications_enabled"`
		StudyReminderTime    *string `json:"study_reminder_time"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	settings, err := h.repo.UpdateSettings(r.Context(), id, req.NotificationsEnabled, req.StudyReminderTime)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update settings")
		return
	}
	writeJSON(w, http.StatusOK, settings)
}

func (h *UserHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
	users, err := h.repo.List(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list users")
		return
	}
	writeJSON(w, http.StatusOK, users)
}

func (h *UserHandler) GetMyWeakCards(w http.ResponseWriter, r *http.Request) {
	cards, err := h.repo.GetWeakCards(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load weak cards")
		return
	}
	writeJSON(w, http.StatusOK, cards)
}
