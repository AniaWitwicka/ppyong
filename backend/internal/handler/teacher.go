package handler

import (
	"net/http"

	"github.com/yourname/koreanapp-backend/internal/repository"
)

type TeacherHandler struct {
	repo *repository.TeacherRepository
}

func NewTeacherHandler(repo *repository.TeacherRepository) *TeacherHandler {
	return &TeacherHandler{repo: repo}
}

func (h *TeacherHandler) Dashboard(w http.ResponseWriter, r *http.Request) {
	dashboard, err := h.repo.GetDashboard(r.Context(), userIDFromContext(r))
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, dashboard)
}

func (h *TeacherHandler) GroupStudents(w http.ResponseWriter, r *http.Request) {
	students, err := h.repo.GetGroupStudents(r.Context(), r.PathValue("id"))
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, students)
}

func (h *TeacherHandler) GroupActivity(w http.ResponseWriter, r *http.Request) {
	events, err := h.repo.GetGroupActivity(r.Context(), r.PathValue("id"))
	if err != nil {
		writeServerError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, events)
}
