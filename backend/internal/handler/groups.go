package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/repository"
)

type GroupHandler struct {
	repo *repository.GroupRepository
}

func NewGroupHandler(repo *repository.GroupRepository) *GroupHandler {
	return &GroupHandler{repo: repo}
}

func (h *GroupHandler) List(w http.ResponseWriter, r *http.Request) {
	groups, err := h.repo.List(r.Context(), userIDFromContext(r))
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, groups)
}

func (h *GroupHandler) Get(w http.ResponseWriter, r *http.Request) {
	userID := userIDFromContext(r)
	groupID := r.PathValue("id")

	ok, err := h.repo.IsMember(r.Context(), groupID, userID)
	if err != nil || !ok {
		writeError(w, http.StatusForbidden, "not a member of this group")
		return
	}

	g, err := h.repo.GetByID(r.Context(), groupID, userID)
	if err != nil {
		writeError(w, http.StatusNotFound, "group not found")
		return
	}
	writeJSON(w, http.StatusOK, g)
}

func (h *GroupHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name  string `json:"name"`
		Emoji string `json:"emoji"`
		Color string `json:"color"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Name == "" {
		writeError(w, http.StatusBadRequest, "name is required")
		return
	}
	if req.Emoji == "" {
		req.Emoji = "🇰🇷"
	}
	if req.Color == "" {
		req.Color = "#F296BD"
	}
	g, err := h.repo.Create(r.Context(), userIDFromContext(r), req.Name, req.Emoji, req.Color)
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, g)
}

func (h *GroupHandler) Update(w http.ResponseWriter, r *http.Request) {
	userID := userIDFromContext(r)
	groupID := r.PathValue("id")

	ok, err := h.repo.IsOwner(r.Context(), groupID, userID)
	if err != nil || !ok {
		writeError(w, http.StatusForbidden, "only the group owner can update it")
		return
	}

	var req struct {
		Name  *string `json:"name"`
		Emoji *string `json:"emoji"`
		Color *string `json:"color"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	g, err := h.repo.Update(r.Context(), groupID, req.Name, req.Emoji, req.Color)
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, g)
}

func (h *GroupHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := userIDFromContext(r)
	groupID := r.PathValue("id")

	ok, err := h.repo.IsOwner(r.Context(), groupID, userID)
	if err != nil || !ok {
		writeError(w, http.StatusForbidden, "only the group owner can delete it")
		return
	}

	if err := h.repo.Delete(r.Context(), groupID); err != nil {
		writeServerError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *GroupHandler) Leave(w http.ResponseWriter, r *http.Request) {
	err := h.repo.Leave(r.Context(), r.PathValue("id"), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
