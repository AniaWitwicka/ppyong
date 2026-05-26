package repository

import (
	"context"
	"errors"
	"os"
	"strings"
	"unicode/utf8"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

var ErrDuplicateEmail = errors.New("email already in use")

func isDuplicateEmail(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}

type AuthRepository struct {
	pool *pgxpool.Pool
}

func NewAuthRepository(pool *pgxpool.Pool) *AuthRepository {
	return &AuthRepository{pool: pool}
}

type UserWithPassword struct {
	ID            string
	PasswordHash  string
	AccountStatus string
}

func (r *AuthRepository) CreateUser(ctx context.Context, name, email, passwordHash, status string) (*model.UserProfile, error) {
	initials := computeInitials(name)

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var p model.UserProfile
	err = tx.QueryRow(ctx, `
		INSERT INTO users (email, name, role, initials, password_hash, account_status)
		VALUES ($1, $2, 'learner', $3, $4, $5)
		RETURNING id, email, name, role, initials, streak, best_streak, last_active
	`, email, name, initials, passwordHash, status).Scan(
		&p.ID, &p.Email, &p.Name, &p.Role, &p.Initials,
		&p.Streak, &p.BestStreak, new(any),
	)
	if err != nil {
		if isDuplicateEmail(err) {
			return nil, ErrDuplicateEmail
		}
		return nil, err
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO user_settings (user_id) VALUES ($1)
	`, p.ID)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	// Auto-join starter group if configured and account is active
	if status == "active" {
		if groupID := os.Getenv("STARTER_GROUP_ID"); groupID != "" {
			_, _ = r.pool.Exec(ctx, `
				INSERT INTO group_members (group_id, user_id, role)
				VALUES ($1, $2, 'member')
				ON CONFLICT (group_id, user_id) DO NOTHING
			`, groupID, p.ID)
		}
	}

	return &p, nil
}

func (r *AuthRepository) GetByEmail(ctx context.Context, email string) (*UserWithPassword, error) {
	var u UserWithPassword
	err := r.pool.QueryRow(ctx, `
		SELECT id, password_hash, account_status FROM users WHERE email = $1
	`, email).Scan(&u.ID, &u.PasswordHash, &u.AccountStatus)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func computeInitials(name string) string {
	parts := strings.Fields(name)
	if len(parts) == 0 {
		return "?"
	}
	if len(parts) == 1 {
		r1, s1 := utf8.DecodeRuneInString(parts[0])
		if len(parts[0]) > s1 {
			r2, _ := utf8.DecodeRuneInString(parts[0][s1:])
			return strings.ToUpper(string(r1) + string(r2))
		}
		return strings.ToUpper(string(r1))
	}
	r1, _ := utf8.DecodeRuneInString(parts[0])
	r2, _ := utf8.DecodeRuneInString(parts[len(parts)-1])
	return strings.ToUpper(string(r1) + string(r2))
}
