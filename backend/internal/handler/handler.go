package handler

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/repository"
)

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

// writeServerError logs the underlying error then responds 500.
// Use for any db/internal failures so errors show up in Railway logs.
func writeServerError(w http.ResponseWriter, r *http.Request, err error) {
	log.Printf("ERROR %s %s: %v", r.Method, r.URL.Path, err)
	writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "internal server error"})
}

// allowEdit answers 404/403 unless the signed-in user may change it (they
// own the collection or are an admin); true means the handler may go on.
func allowEdit(w http.ResponseWriter, r *http.Request, ok bool, err error) bool {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		writeError(w, http.StatusNotFound, "not found")
		return false
	case err != nil:
		writeServerError(w, r, err)
		return false
	case !ok:
		writeError(w, http.StatusForbidden, "only the owner of this collection can change it")
		return false
	}
	return true
}
