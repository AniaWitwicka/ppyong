package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"os"
	"strings"

	"golang.org/x/crypto/bcrypt"

	"github.com/yourname/koreanapp-backend/internal/auth"
	"github.com/yourname/koreanapp-backend/internal/repository"
)

// allowedEmails returns the set of emails permitted to register.
// When ALLOWED_EMAILS is unset every email is allowed (dev mode).
func allowedEmails() map[string]bool {
	raw := os.Getenv("ALLOWED_EMAILS")
	if raw == "" {
		return nil // nil == open
	}
	set := map[string]bool{}
	for _, e := range strings.Split(raw, ",") {
		if e = strings.TrimSpace(strings.ToLower(e)); e != "" {
			set[e] = true
		}
	}
	return set
}

type AuthHandler struct {
	authRepo *repository.AuthRepository
}

func NewAuthHandler(authRepo *repository.AuthRepository) *AuthHandler {
	return &AuthHandler{authRepo: authRepo}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Name == "" || req.Email == "" || req.Password == "" {
		writeError(w, http.StatusBadRequest, "name, email and password are required")
		return
	}
	if len(req.Password) < 8 {
		writeError(w, http.StatusBadRequest, "password must be at least 8 characters")
		return
	}

	if allowed := allowedEmails(); allowed != nil && !allowed[strings.ToLower(req.Email)] {
		writeError(w, http.StatusForbidden, "registration is by invitation only")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
	if err != nil {
		writeServerError(w, r, err)
		return
	}

	if _, err := h.authRepo.CreateUser(r.Context(), req.Name, req.Email, string(hash)); err != nil {
		if errors.Is(err, repository.ErrDuplicateEmail) {
			writeError(w, http.StatusConflict, "email already in use")
		} else {
			writeServerError(w, r, err)
		}
		return
	}

	writeJSON(w, http.StatusCreated, map[string]any{
		"message": "registration successful, your account is pending approval",
	})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	user, err := h.authRepo.GetByEmail(r.Context(), req.Email)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "invalid email or password")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		writeError(w, http.StatusUnauthorized, "invalid email or password")
		return
	}

	if user.AccountStatus != "active" {
		writeError(w, http.StatusForbidden, "your account is pending approval — the admin will activate it shortly")
		return
	}

	token, err := auth.GenerateToken(user.ID)
	if err != nil {
		writeServerError(w, r, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"token": token})
}
