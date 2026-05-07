package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/repository"
)

type CollectionHandler struct {
	repo *repository.CollectionRepository
}

func NewCollectionHandler(repo *repository.CollectionRepository) *CollectionHandler {
	return &CollectionHandler{repo: repo}
}

func (h *CollectionHandler) List(w http.ResponseWriter, r *http.Request) {
	collections, err := h.repo.List(r.Context(), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load collections")
		return
	}
	writeJSON(w, http.StatusOK, collections)
}

func (h *CollectionHandler) Get(w http.ResponseWriter, r *http.Request) {
	c, err := h.repo.GetByID(r.Context(), r.PathValue("id"), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusNotFound, "collection not found")
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *CollectionHandler) Create(w http.ResponseWriter, r *http.Request) {
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
		req.Emoji = "📚"
	}
	if req.Color == "" {
		req.Color = "#99B7F5"
	}
	c, err := h.repo.Create(r.Context(), userIDFromContext(r), req.Name, req.Emoji, req.Color)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create collection")
		return
	}
	writeJSON(w, http.StatusCreated, c)
}

func (h *CollectionHandler) Update(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name  *string `json:"name"`
		Emoji *string `json:"emoji"`
		Color *string `json:"color"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	c, err := h.repo.Update(r.Context(), r.PathValue("id"), req.Name, req.Emoji, req.Color)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update collection")
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *CollectionHandler) Delete(w http.ResponseWriter, r *http.Request) {
	if err := h.repo.Delete(r.Context(), r.PathValue("id")); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to delete collection")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *CollectionHandler) Share(w http.ResponseWriter, r *http.Request) {
	var req struct {
		MemberIDs []string `json:"member_ids"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	shared, err := h.repo.Share(r.Context(), r.PathValue("id"), req.MemberIDs)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to share collection")
		return
	}
	writeJSON(w, http.StatusOK, shared)
}
