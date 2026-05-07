package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/model"
	"github.com/yourname/koreanapp-backend/internal/repository"
)

type DeckHandler struct {
	repo *repository.DeckRepository
}

func NewDeckHandler(repo *repository.DeckRepository) *DeckHandler {
	return &DeckHandler{repo: repo}
}

func (h *DeckHandler) List(w http.ResponseWriter, r *http.Request) {
	decks, err := h.repo.List(r.Context(), r.PathValue("id"), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to load decks")
		return
	}
	writeJSON(w, http.StatusOK, decks)
}

func (h *DeckHandler) Get(w http.ResponseWriter, r *http.Request) {
	deck, err := h.repo.GetByID(r.Context(), r.PathValue("id"), userIDFromContext(r))
	if err != nil {
		writeError(w, http.StatusNotFound, "deck not found")
		return
	}
	writeJSON(w, http.StatusOK, deck)
}

func (h *DeckHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req model.CreateDeckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Name == "" {
		writeError(w, http.StatusBadRequest, "name is required")
		return
	}
	deck, err := h.repo.Create(r.Context(), r.PathValue("id"), userIDFromContext(r), req.Name, req.Description)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to create deck")
		return
	}
	writeJSON(w, http.StatusCreated, deck)
}

func (h *DeckHandler) Update(w http.ResponseWriter, r *http.Request) {
	var req model.UpdateDeckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	deck, err := h.repo.Update(r.Context(), r.PathValue("id"), req.Name, req.Description, req.CollectionID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to update deck")
		return
	}
	writeJSON(w, http.StatusOK, deck)
}

func (h *DeckHandler) Delete(w http.ResponseWriter, r *http.Request) {
	if err := h.repo.Delete(r.Context(), r.PathValue("id")); err != nil {
		writeError(w, http.StatusInternalServerError, "failed to delete deck")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *DeckHandler) Share(w http.ResponseWriter, r *http.Request) {
	var req model.ShareDeckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	shared, err := h.repo.Share(r.Context(), r.PathValue("id"), req.MemberIDs)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to share deck")
		return
	}
	writeJSON(w, http.StatusOK, shared)
}
