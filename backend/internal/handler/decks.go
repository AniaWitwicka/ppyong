package handler

import (
	"encoding/json"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/model"
)

// mockDecks maps collection ID → list of decks in that collection.
var mockDecks = map[string][]model.DeckSummary{
	"col-1": {
		{ID: "deck-1", Name: "Greetings", CardCount: 8, MasteredCount: 2, LearningCount: 3, NewCount: 3},
		{ID: "deck-2", Name: "Basic Phrases", CardCount: 12, MasteredCount: 5, LearningCount: 4, NewCount: 3},
		{ID: "deck-3", Name: "Numbers", CardCount: 10, MasteredCount: 8, LearningCount: 2, NewCount: 0},
		{ID: "deck-4", Name: "Days & Time", CardCount: 14, MasteredCount: 0, LearningCount: 0, NewCount: 14},
	},
	"col-2": {
		{ID: "deck-5", Name: "At the Restaurant", CardCount: 12, MasteredCount: 6, LearningCount: 4, NewCount: 2},
		{ID: "deck-6", Name: "Drinks & Snacks", CardCount: 8, MasteredCount: 7, LearningCount: 1, NewCount: 0},
	},
	"col-3": {
		{ID: "deck-7", Name: "Emotions", CardCount: 10, MasteredCount: 10, LearningCount: 0, NewCount: 0},
		{ID: "deck-8", Name: "Relationships", CardCount: 14, MasteredCount: 14, LearningCount: 0, NewCount: 0},
		{ID: "deck-9", Name: "Actions & Verbs", CardCount: 12, MasteredCount: 12, LearningCount: 0, NewCount: 0},
	},
	"col-4": {
		{ID: "deck-10", Name: "Counting Systems", CardCount: 10, MasteredCount: 1, LearningCount: 2, NewCount: 7},
		{ID: "deck-11", Name: "Telling the Time", CardCount: 10, MasteredCount: 1, LearningCount: 3, NewCount: 6},
	},
}

// mockDeckDetails maps deck ID → full detail (for GET /decks/:id).
var mockDeckDetails = map[string]model.DeckDetail{
	"deck-1":  {ID: "deck-1", Name: "Greetings", Description: "Essential Korean greetings and farewells", CollectionID: "col-1", CollectionName: "TOPIK Basics", CardCount: 8, MasteredCount: 2, LearningCount: 3, NewCount: 3},
	"deck-2":  {ID: "deck-2", Name: "Basic Phrases", Description: "Everyday phrases for beginners", CollectionID: "col-1", CollectionName: "TOPIK Basics", CardCount: 12, MasteredCount: 5, LearningCount: 4, NewCount: 3},
	"deck-3":  {ID: "deck-3", Name: "Numbers", Description: "Native and Sino-Korean number systems", CollectionID: "col-1", CollectionName: "TOPIK Basics", CardCount: 10, MasteredCount: 8, LearningCount: 2, NewCount: 0},
	"deck-4":  {ID: "deck-4", Name: "Days & Time", Description: "Days of the week, months, and time expressions", CollectionID: "col-1", CollectionName: "TOPIK Basics", CardCount: 14, MasteredCount: 0, LearningCount: 0, NewCount: 14},
	"deck-5":  {ID: "deck-5", Name: "At the Restaurant", Description: "Ordering food and asking for the bill", CollectionID: "col-2", CollectionName: "Food & Drink", CardCount: 12, MasteredCount: 6, LearningCount: 4, NewCount: 2},
	"deck-6":  {ID: "deck-6", Name: "Drinks & Snacks", Description: "Popular Korean drinks and street food", CollectionID: "col-2", CollectionName: "Food & Drink", CardCount: 8, MasteredCount: 7, LearningCount: 1, NewCount: 0},
	"deck-7":  {ID: "deck-7", Name: "Emotions", Description: "Expressing feelings in Korean", CollectionID: "col-3", CollectionName: "K-drama phrases", CardCount: 10, MasteredCount: 10, LearningCount: 0, NewCount: 0},
	"deck-8":  {ID: "deck-8", Name: "Relationships", Description: "Family members and relationship terms", CollectionID: "col-3", CollectionName: "K-drama phrases", CardCount: 14, MasteredCount: 14, LearningCount: 0, NewCount: 0},
	"deck-9":  {ID: "deck-9", Name: "Actions & Verbs", Description: "Common verbs used in dramas", CollectionID: "col-3", CollectionName: "K-drama phrases", CardCount: 12, MasteredCount: 12, LearningCount: 0, NewCount: 0},
	"deck-10": {ID: "deck-10", Name: "Counting Systems", Description: "Native vs Sino-Korean counters", CollectionID: "col-4", CollectionName: "Numbers & Time", CardCount: 10, MasteredCount: 1, LearningCount: 2, NewCount: 7},
	"deck-11": {ID: "deck-11", Name: "Telling the Time", Description: "Hours, minutes, AM/PM in Korean", CollectionID: "col-4", CollectionName: "Numbers & Time", CardCount: 10, MasteredCount: 1, LearningCount: 3, NewCount: 6},
}

func ListDecks(w http.ResponseWriter, r *http.Request) {
	collectionID := r.PathValue("id")
	decks, ok := mockDecks[collectionID]
	if !ok {
		writeError(w, http.StatusNotFound, "collection not found")
		return
	}
	writeJSON(w, http.StatusOK, decks)
}

func GetDeck(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	deck, ok := mockDeckDetails[id]
	if !ok {
		writeError(w, http.StatusNotFound, "deck not found")
		return
	}
	writeJSON(w, http.StatusOK, deck)
}

func CreateDeck(w http.ResponseWriter, r *http.Request) {
	collectionID := r.PathValue("id")
	if _, ok := mockDecks[collectionID]; !ok {
		writeError(w, http.StatusNotFound, "collection not found")
		return
	}

	var req model.CreateDeckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Name == "" {
		writeError(w, http.StatusBadRequest, "name is required")
		return
	}

	created := model.DeckSummary{
		ID:            "deck-new",
		Name:          req.Name,
		CardCount:     0,
		MasteredCount: 0,
		LearningCount: 0,
		NewCount:      0,
	}
	writeJSON(w, http.StatusCreated, created)
}

func UpdateDeck(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	deck, ok := mockDeckDetails[id]
	if !ok {
		writeError(w, http.StatusNotFound, "deck not found")
		return
	}

	var req model.UpdateDeckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Name != nil {
		deck.Name = *req.Name
	}
	if req.Description != nil {
		deck.Description = *req.Description
	}
	if req.CollectionID != nil {
		deck.CollectionID = *req.CollectionID
	}
	writeJSON(w, http.StatusOK, deck)
}

func DeleteDeck(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if _, ok := mockDeckDetails[id]; !ok {
		writeError(w, http.StatusNotFound, "deck not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func ShareDeck(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if _, ok := mockDeckDetails[id]; !ok {
		writeError(w, http.StatusNotFound, "deck not found")
		return
	}

	var req model.ShareDeckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	// Return the members that were shared with (subset of mockUsers matching IDs).
	shared := make([]model.UserSummary, 0)
	for _, u := range mockUsers {
		for _, id := range req.MemberIDs {
			if u.ID == id {
				shared = append(shared, u)
				break
			}
		}
	}
	writeJSON(w, http.StatusOK, shared)
}
