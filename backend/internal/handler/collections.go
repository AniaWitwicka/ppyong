package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/model"
)

var mockCollections = []model.CollectionSummary{
	{
		ID:        "col-1",
		Name:      "TOPIK Basics",
		Emoji:     "📚",
		Color:     "#99B7F5",
		DeckCount: 4,
		WordCount: 48,
		DueCount:  12,
		Progress:  0.45,
	},
	{
		ID:        "col-2",
		Name:      "Food & Drink",
		Emoji:     "🍜",
		Color:     "#F296BD",
		DeckCount: 2,
		WordCount: 24,
		DueCount:  3,
		Progress:  0.7,
	},
	{
		ID:        "col-3",
		Name:      "K-drama phrases",
		Emoji:     "💬",
		Color:     "#FCCA59",
		DeckCount: 3,
		WordCount: 36,
		DueCount:  0,
		Progress:  1.0,
	},
	{
		ID:        "col-4",
		Name:      "Numbers & Time",
		Emoji:     "🕐",
		Color:     "#267F53",
		DeckCount: 2,
		WordCount: 20,
		DueCount:  5,
		Progress:  0.2,
	},
}

func ListCollections(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, mockCollections)
}

func GetCollection(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	for _, c := range mockCollections {
		if c.ID == id {
			writeJSON(w, http.StatusOK, c)
			return
		}
	}
	writeError(w, http.StatusNotFound, "collection not found")
}

func CreateCollection(w http.ResponseWriter, r *http.Request) {
	var req model.CreateCollectionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Name == "" {
		writeError(w, http.StatusBadRequest, "name is required")
		return
	}

	created := model.CollectionSummary{
		ID:        "col-new",
		Name:      req.Name,
		Emoji:     req.Emoji,
		Color:     req.Color,
		DeckCount: 0,
		WordCount: 0,
		DueCount:  0,
		Progress:  0,
	}
	writeJSON(w, http.StatusCreated, created)
}

func UpdateCollection(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var col *model.CollectionSummary
	for i := range mockCollections {
		if mockCollections[i].ID == id {
			col = &mockCollections[i]
			break
		}
	}
	if col == nil {
		writeError(w, http.StatusNotFound, "collection not found")
		return
	}

	var req model.UpdateCollectionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Name != nil {
		col.Name = *req.Name
	}
	if req.Emoji != nil {
		col.Emoji = *req.Emoji
	}
	if req.Color != nil {
		col.Color = *req.Color
	}
	writeJSON(w, http.StatusOK, col)
}

func DeleteCollection(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	for _, c := range mockCollections {
		if c.ID == id {
			w.WriteHeader(http.StatusNoContent)
			return
		}
	}
	writeError(w, http.StatusNotFound, "collection not found")
}
