# Ppyong — backend task breakdown

> Frontend tasks live in `TASKS.md`

---

## 1. Infrastructure

- [x] `/ping` health check endpoint with request logging
- [x] Database connection — Supabase PostgreSQL via pgx
  - [x] Create Supabase project and copy connection string
  - [x] Add `github.com/jackc/pgx/v5` and `github.com/joho/godotenv` to `go.mod`
  - [x] Create `backend/.env` with `DATABASE_URL`, `PORT`, `JWT_SECRET`, `ALLOWED_ORIGINS`
  - [x] Create `backend/internal/db/db.go` — opens `pgxpool.Pool` from `DATABASE_URL`, `Ping()` on startup
  - [x] Wire pool into `main.go` — fail fast if connection fails
  - [x] Test: DB connected log on startup
- [x] JWT auth middleware — `middleware.RequireAuth`, applied to all non-public routes
- [x] CORS config (allow all origins for now)
- [x] `.env` loading via godotenv

---

## 2. Auth endpoints

Needed by: **Login screen**, **Forgot password screen**

- [x] `POST /auth/register` — name, email, password → JWT token + user object
- [x] `POST /auth/login` — email, password → JWT token + user object
- [ ] `POST /auth/forgot-password` — email → sends reset link (Supabase email or custom)
- [x] Role field on user: everyone registers as `learner`; `teacher` / `admin` set manually in DB

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
- [x] Connect all of the above to real DB queries
  - [x] `backend/internal/repository/user_repository.go` — GetByID, GetStats, GetSettings, Update, UpdateSettings, List
  - [x] `backend/internal/repository/auth_repository.go` — CreateUser, GetByEmail
  - [x] SQL migrations: `users` table with streak, best_streak, last_active, role, initials (001, 002)
  - [x] SQL migration: `user_settings` table (002)
  - [x] SQL migration: seed users with fixed UUIDs (004)
  - [x] SQL migration: add password_hash column (005)

---

## 4. Collections

Needed by: **Library screen**, **Home screen**, **Add collection sheet**

- [x] `GET /collections` — list user's collections; each returns: id, name, emoji, color, deck_count, word_count, due_count, progress (0.0–1.0)
- [x] `POST /collections` — create: name, emoji, color, description
- [x] `GET /collections/:id` — single collection detail
- [x] `PATCH /collections/:id` — rename, change emoji/color/description
- [x] `DELETE /collections/:id`
- [x] Connect all of the above to real DB queries
  - [x] `backend/internal/repository/collection_repository.go` — List, GetByID, Create, Update, Delete
  - [x] SQL migration: `collections` table (id, name, emoji, color, created_by, created_at) — migration 003
  - [x] deck_count, word_count, due_count, progress computed via JOIN/aggregate queries

---

## 5. Decks

Needed by: **Deck detail screen**, **Library screen**, **Edit deck sheet**, **Flashcard study screen**

- [x] `GET /collections/:id/decks` — list decks in a collection; each returns: id, name, card_count, mastered_count, learning_count, new_count
- [x] `POST /collections/:id/decks` — create deck: name, description
- [x] `GET /decks/:id` — deck detail: name, collection_name, card_count, mastered/learning/new counts
- [x] `PATCH /decks/:id` — rename, change description or collection
- [x] `DELETE /decks/:id`
- [x] `POST /decks/:id/share` — body: `{ member_ids: [string] }` → grant Viewer access; returns list of newly shared members
- [x] Connect all of the above to real DB queries
  - [x] `backend/internal/repository/deck_repository.go` — List, GetByID, Create, Update, Delete, Share
  - [x] SQL migration: `decks` table already in migration 001
  - [x] mastered/learning/new counts computed via JOIN with srs_progress


---

## 6. Cards

Needed by: **Deck detail screen**, **Flashcard study screen**, **Add flashcard sheet**

- [x] `GET /decks/:id/cards` — all cards in deck; each returns: id, korean, romanisation, translation, notes, status (mastered | learning | new), due_date
- [x] `GET /decks/:id/cards?scope=due` — cards where due_date ≤ today
- [x] `GET /decks/:id/cards?scope=weak` — cards with low ease_factor
- [x] `POST /decks/:id/cards` — create card: korean, romanisation, translation, notes
- [x] `PATCH /cards/:id` — edit card fields
- [x] `DELETE /cards/:id`
- [x] `backend/internal/repository/card_repository.go` — List (with scope), Create, Update, Delete
- [x] Connected to Flutter: `lib/models/card.dart`, `lib/services/card_service.dart`
- [x] Deck detail screen loads real cards; Add flashcard sheet saves to API

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

## 8. Groups & social

Needed by: **Groups tab** (all views), **Group detail screen**

### DB migrations
- [x] Migration: `groups` table — id, name, emoji, color, created_by (user_id FK), created_at
- [x] Migration: `group_members` table — group_id, user_id, role (`owner` | `member`), joined_at
- [x] Migration: `invites` table — id, group_id, inviter_id, invitee_email, invitee_user_id (nullable), status (`pending` | `accepted` | `declined`), expires_at (7 days from created_at)
- [x] Migration: `friends` table — id, user_id, friend_id, status (`pending` | `accepted`), created_at

### Groups endpoints
- [x] `GET /groups` — list groups the authenticated user belongs to; each returns: id, name, emoji, color, member_count, deck_count, last_active, member avatars (up to 4)
- [x] `POST /groups` — create group: name, emoji; creator becomes `owner`
- [x] `GET /groups/:id` — group detail: name, emoji, color, members list (id, name, initials, role, progress %), shared decks list
- [x] `PATCH /groups/:id` — update name or emoji; owner only
- [x] `DELETE /groups/:id` — owner only; cascades to group_members + invites
- [x] `POST /groups/:id/leave` — remove self from group_members; owner cannot leave (must delete or transfer)
- [x] `backend/internal/repository/group_repository.go` — List, GetByID, Create, Update, Delete, Leave, IsMember, IsOwner
- [x] `backend/internal/handler/groups.go` — GroupHandler struct

### Invites endpoints
- [x] `GET /invites` — list incoming invites (status=pending, invitee is me) + sent invites (inviter is me)
- [x] `POST /groups/:id/invite` — body: `{ email: string }` — creates invite row, sends email (stub for now); returns invite object
- [x] `POST /invites/:id/accept` — sets status=accepted, adds user to group_members; invitee only
- [x] `POST /invites/:id/decline` — sets status=declined; invitee only
- [x] `GET /invites/pending-count` — returns `{ count: int }` — used for badge on Groups tab
- [x] `backend/internal/repository/invite_repository.go` — List, Create, Accept, Decline, PendingCount
- [x] `backend/internal/handler/invites.go` — InviteHandler struct

### Friends endpoints
- [x] `GET /friends` — list accepted friends with name, initials, streak, word count, due count, role
- [x] `GET /users/search?q=` — search users by name or email (used in Add friend sheet); excludes existing friends and self
- [x] `POST /friends/request` — body: `{ user_id: string }` — sends friend request
- [x] `POST /friends/:id/accept` — accept incoming friend request
- [x] `POST /friends/:id/decline` — decline incoming friend request
- [x] `backend/internal/repository/friend_repository.go` — List, Search, SendRequest, Accept, Decline
- [x] `backend/internal/handler/friends.go` — FriendHandler struct

### Wire into main.go
- [x] Register group, invite, friend routes in `cmd/api/main.go`

---

## 9. PWA / backend deploy

- [ ] Railway deploy config (`Dockerfile` or `railway.json`)
- [ ] Environment variables set on Railway (`DATABASE_URL`, `JWT_SECRET`, `ALLOWED_ORIGINS`)
