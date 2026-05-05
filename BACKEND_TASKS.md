# Ppyong — backend task breakdown

> Frontend tasks live in `TASKS.md`

---

## 1. Infrastructure

- [x] `/ping` health check endpoint with request logging
- [ ] Database connection — Supabase PostgreSQL via pgx
  - [ ] Create Supabase project and copy connection string (Settings → Database → URI)
  - [ ] Add `github.com/jackc/pgx/v5` and `github.com/joho/godotenv` to `go.mod`
  - [ ] Create `backend/.env` with `DATABASE_URL`, `PORT`, `JWT_SECRET`, `ALLOWED_ORIGINS`
  - [ ] Create `backend/internal/db/db.go` — opens `pgxpool.Pool` from `DATABASE_URL`, `Ping()` on startup
  - [ ] Wire pool into `main.go` — fail fast if connection fails
  - [ ] Test: `GET /ping` returns `{"message":"pong"}` and logs show DB connected
- [ ] JWT auth middleware (attach to all protected routes)
- [ ] CORS config (allow Vercel origin + localhost)
- [ ] `.env` loading via godotenv (`PORT`, `DATABASE_URL`, `JWT_SECRET`, `ALLOWED_ORIGINS`)

---

## 2. Auth endpoints

Needed by: **Login screen**, **Forgot password screen**

- [ ] `POST /auth/register` — name, email, password → JWT token + user object
- [ ] `POST /auth/login` — email, password → JWT token + user object
- [ ] `POST /auth/forgot-password` — email → sends reset link (Supabase email or custom)
- [ ] Role field on user: everyone registers as `member`; `teacher` / `admin` set manually in DB

---

## 3. User profile & settings

Needed by: **Profile screen**, **Deck sharing popup** (member list)

`/me` is a convenience alias that resolves server-side to the authenticated user's ID.
All routes under `/users/:id` work for any user — permission checks gate what fields are returned.

- [x] `GET /users/:id` — profile: name, email, role, initials, streak, best_streak, last_active
- [x] `GET /me` → alias for `GET /users/<token_user_id>`
- [x] `GET /me/stats` + `GET /users/:id/stats` — mastered count, learning count, session count, accuracy %, weekly activity (7 bools)
- [x] `GET /me/settings` + `GET /users/:id/settings` — own account only
- [x] `PATCH /users/:id` — update name / email; only allowed if `:id` == token user or admin
- [x] `PATCH /users/:id/settings` — notifications_enabled (bool), study_reminder_time (string); own account only
- [x] `GET /users` — list all users in the group (for sharing dialog); returns id, name, initials, role
- [ ] `POST /auth/logout` — invalidate token / clear session
- [ ] Connect all of the above to real DB queries (currently mocked)
  - [ ] `backend/internal/repository/user_repository.go` — GetByID, GetStats, GetSettings, Update, UpdateSettings, List
  - [ ] SQL migrations: `users` table with streak, best_streak, last_active, role, initials
  - [ ] SQL migrations: `user_settings` table with notifications_enabled, study_reminder_time

---

## 4. Collections

Needed by: **Library screen**, **Home screen**, **Add collection sheet**

- [x] `GET /collections` — list user's collections; each returns: id, name, emoji, color, deck_count, word_count, due_count, progress (0.0–1.0)
- [x] `POST /collections` — create: name, emoji, color, description
- [x] `GET /collections/:id` — single collection detail
- [x] `PATCH /collections/:id` — rename, change emoji/color/description
- [x] `DELETE /collections/:id`
- [ ] Connect all of the above to real DB queries (currently mocked)
  - [ ] `backend/internal/repository/collection_repository.go` — List, GetByID, Create, Update, Delete
  - [ ] SQL migration: `collections` table (id, name, emoji, color, created_by, created_at)
  - [ ] deck_count, word_count, due_count, progress computed via JOIN/aggregate queries

---

## 5. Decks

Needed by: **Deck detail screen**, **Library screen**, **Edit deck sheet**, **Flashcard study screen**

- [x] `GET /collections/:id/decks` — list decks in a collection; each returns: id, name, card_count, mastered_count, learning_count, new_count
- [x] `POST /collections/:id/decks` — create deck: name, description
- [x] `GET /decks/:id` — deck detail: name, collection_name, card_count, mastered/learning/new counts
- [x] `PATCH /decks/:id` — rename, change description or collection
- [x] `DELETE /decks/:id`
- [x] `POST /decks/:id/share` — body: `{ member_ids: [string] }` → grant Viewer access; returns list of newly shared members
- [ ] Connect all of the above to real DB queries (currently mocked)
  - [ ] `backend/internal/repository/deck_repository.go` — List, GetByID, Create, Update, Delete, Share
  - [ ] SQL migration: `decks` table (id, collection_id, name, description, created_by, created_at)
  - [ ] mastered/learning/new counts computed via JOIN with srs_progress


---

## 6. Cards

Needed by: **Deck detail screen**, **Flashcard study screen**, **Add flashcard sheet**

- [ ] `GET /decks/:id/cards` — all cards in deck; each returns: id, korean, romanisation, translation, notes, status (mastered | learning | new), due_date
- [ ] `GET /decks/:id/cards?scope=due` — cards where due_date ≤ today (for "Due today (N)" scope picker)
- [ ] `GET /decks/:id/cards?scope=weak` — cards with low ease_factor (for "Weak words (N)" scope picker)
- [ ] `POST /decks/:id/cards` — create card: korean, romanisation, translation, notes
- [ ] `PATCH /cards/:id` — edit card fields
- [ ] `DELETE /cards/:id`

---

## 7. SRS — spaced repetition

Needed by: **Flashcard study screen** (every swipe), **Deck detail screen** (status dots + progress bar)

- [ ] SM-2 implementation in `backend/internal/service/srs.go`
  - Input: current ease_factor, interval_days, rating (knew_it: bool)
  - Output: new ease_factor, new interval_days, next due_date
- [ ] `POST /cards/:id/review` — body: `{ knew_it: bool }` → runs SM-2, persists srs_progress row, returns updated interval + due_date
- [ ] Card status derivation rule (used in `GET /decks/:id/cards`):
  - `new` — never reviewed (no srs_progress row)
  - `learning` — reviewed but ease_factor < threshold or interval < 7 days
  - `mastered` — interval ≥ 7 days
- [ ] Seed initial srs_progress rows when a card is first studied

## 8. PWA / backend deploy

- [ ] Railway deploy config (`Dockerfile` or `railway.json`)
- [ ] Environment variables set on Railway (`DATABASE_URL`, `JWT_SECRET`, `ALLOWED_ORIGINS`)
