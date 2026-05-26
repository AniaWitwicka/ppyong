package handler

import (
	"encoding/json"
	"log"
	"net/http"
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
