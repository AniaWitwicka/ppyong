package handler

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"

	"github.com/yourname/koreanapp-backend/internal/model"
	"github.com/yourname/koreanapp-backend/internal/repository"
	"github.com/yourname/koreanapp-backend/internal/service"
)

type ImportHandler struct {
	cardRepo *repository.CardRepository
}

func NewImportHandler(cardRepo *repository.CardRepository) *ImportHandler {
	return &ImportHandler{cardRepo: cardRepo}
}

// Preview parses pasted text or an uploaded CSV and returns the structured card list.
// POST /import/preview
//   - JSON body: { "source": "paste", "raw_text": "..." }
//   - Multipart: file field containing CSV bytes
func (h *ImportHandler) Preview(w http.ResponseWriter, r *http.Request) {
	ct := r.Header.Get("Content-Type")

	if strings.HasPrefix(ct, "multipart/form-data") {
		if err := r.ParseMultipartForm(5 << 20); err != nil {
			writeError(w, http.StatusBadRequest, "file too large (max 5 MB)")
			return
		}
		f, _, err := r.FormFile("file")
		if err != nil {
			writeError(w, http.StatusBadRequest, "missing file field")
			return
		}
		defer f.Close()
		data, err := io.ReadAll(io.LimitReader(f, 5<<20))
		if err != nil {
			writeServerError(w, r, err)
			return
		}
		writeJSON(w, http.StatusOK, service.ParseCardText(string(data)))
		return
	}

	var req struct {
		RawText string `json:"raw_text"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if strings.TrimSpace(req.RawText) == "" {
		writeError(w, http.StatusBadRequest, "raw_text is required")
		return
	}
	writeJSON(w, http.StatusOK, service.ParseCardText(req.RawText))
}

// BulkCreate inserts up to 200 cards into an existing deck in a single transaction.
// POST /decks/:id/cards/bulk
func (h *ImportHandler) BulkCreate(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Cards []model.ParsedCard `json:"cards"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if len(req.Cards) == 0 {
		writeError(w, http.StatusBadRequest, "no cards provided")
		return
	}
	if len(req.Cards) > 200 {
		writeError(w, http.StatusBadRequest, "max 200 cards per import")
		return
	}

	created, err := h.cardRepo.BulkCreate(r.Context(), r.PathValue("id"), req.Cards)
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]int{"created": created})
}
