package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/repository"
)

type FriendHandler struct {
	repo *repository.FriendRepository
}

func NewFriendHandler(repo *repository.FriendRepository) *FriendHandler {
	return &FriendHandler{repo: repo}
}

func (h *FriendHandler) List(w http.ResponseWriter, r *http.Request) {
	friends, err := h.repo.List(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load friends")
		return
	}
	writeJSON(w, http.StatusOK, friends)
}

func (h *FriendHandler) Search(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	if q == "" {
		writeJSON(w, http.StatusOK, []struct{}{})
		return
	}
	results, err := h.repo.Search(r.Context(), userIDFromContext(r), q)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "search failed")
		return
	}
	writeJSON(w, http.StatusOK, results)
}

func (h *FriendHandler) ListPendingRequests(w http.ResponseWriter, r *http.Request) {
	requests, err := h.repo.ListPendingRequests(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load friend requests")
		return
	}
	writeJSON(w, http.StatusOK, requests)
}

func (h *FriendHandler) SendRequest(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.UserID == "" {
		writeError(w, http.StatusBadRequest, "user_id is required")
		return
	}
	if err := h.repo.SendRequest(r.Context(), userIDFromContext(r), req.UserID); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to send friend request")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendHandler) Accept(w http.ResponseWriter, r *http.Request) {
	if err := h.repo.Accept(r.Context(), r.PathValue("id"), userIDFromContext(r)); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to accept friend request")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *FriendHandler) Decline(w http.ResponseWriter, r *http.Request) {
	if err := h.repo.Decline(r.Context(), r.PathValue("id"), userIDFromContext(r)); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to decline friend request")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
