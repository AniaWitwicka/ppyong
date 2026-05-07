package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/repository"
)

type InviteHandler struct {
	repo *repository.InviteRepository
}

func NewInviteHandler(repo *repository.InviteRepository) *InviteHandler {
	return &InviteHandler{repo: repo}
}

func (h *InviteHandler) List(w http.ResponseWriter, r *http.Request) {
	resp, err := h.repo.List(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load invites")
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (h *InviteHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email  string `json:"email"`
		UserID string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Email == "" && req.UserID == "" {
		writeError(w, http.StatusBadRequest, "email or user_id is required")
		return
	}
	inv, err := h.repo.Create(r.Context(), r.PathValue("id"), userIDFromContext(r), req.Email, req.UserID)
	if err != nil {
		if isPermissionError(err) {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to send invite")
		return
	}
	writeJSON(w, http.StatusCreated, inv)
}

func (h *InviteHandler) Accept(w http.ResponseWriter, r *http.Request) {
	err := h.repo.Accept(r.Context(), r.PathValue("id"), userIDFromContext(r))
	if err != nil {
		if isPermissionError(err) {
			writeError(w, http.StatusForbidden, err.Error())
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to accept invite")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *InviteHandler) Decline(w http.ResponseWriter, r *http.Request) {
	err := h.repo.Decline(r.Context(), r.PathValue("id"), userIDFromContext(r))
	if err != nil {
		if isPermissionError(err) {
			writeError(w, http.StatusForbidden, err.Error())
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to decline invite")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *InviteHandler) PendingCount(w http.ResponseWriter, r *http.Request) {
	count, err := h.repo.PendingCount(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get pending count")
		return
	}
	writeJSON(w, http.StatusOK, map[string]int{"count": count})
}

func isPermissionError(err error) bool {
	_, ok := err.(*repository.PermissionError)
	return ok
}
