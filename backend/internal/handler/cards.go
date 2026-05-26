package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/repository"
)

type CardHandler struct {
	repo    *repository.CardRepository
	srsRepo *repository.SRSRepository
}

func NewCardHandler(repo *repository.CardRepository, srsRepo *repository.SRSRepository) *CardHandler {
	return &CardHandler{repo: repo, srsRepo: srsRepo}
}

func (h *CardHandler) List(w http.ResponseWriter, r *http.Request) {
	scope := r.URL.Query().Get("scope") // "due" | "weak" | "" (all)
	cards, err := h.repo.List(r.Context(), r.PathValue("id"), userIDFromContext(r), scope)
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, cards)
}

func (h *CardHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Korean       string `json:"korean"`
		Romanisation string `json:"romanisation"`
		Translation  string `json:"translation"`
		Notes        string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Korean == "" || req.Translation == "" {
		writeError(w, http.StatusBadRequest, "korean and translation are required")
		return
	}
	card, err := h.repo.Create(r.Context(), r.PathValue("id"), req.Korean, req.Romanisation, req.Translation, req.Notes)
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, card)
}

func (h *CardHandler) Update(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Korean       *string `json:"korean"`
		Romanisation *string `json:"romanisation"`
		Translation  *string `json:"translation"`
		Notes        *string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	card, err := h.repo.Update(r.Context(), r.PathValue("id"), req.Korean, req.Romanisation, req.Translation, req.Notes)
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, card)
}

func (h *CardHandler) Delete(w http.ResponseWriter, r *http.Request) {
	if err := h.repo.Delete(r.Context(), r.PathValue("id")); err != nil {
		writeServerError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *CardHandler) Review(w http.ResponseWriter, r *http.Request) {
	var req struct {
		KnewIt bool `json:"knew_it"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	progress, err := h.srsRepo.Review(r.Context(), r.PathValue("id"), userIDFromContext(r), req.KnewIt)
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, progress)
}
