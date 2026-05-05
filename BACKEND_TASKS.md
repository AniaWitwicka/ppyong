# Ppyong — backend task breakdown

> Frontend tasks live in `TASKS.md`

---

## 1. Infrastructure

- [x] `/ping` health check endpoint with request logging
- [ ] Database connection — Supabase PostgreSQL via pgx
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

- [ ] `GET /me` — current user: name, email, role, initials, streak, best_streak, last_active
- [ ] `GET /me/stats` — mastered count, learning count, session count, accuracy %, weekly activity (7 bools)
- [ ] `PATCH /me` — update name / email
- [ ] `PATCH /me/settings` — notifications_enabled (bool), study_reminder_time (string)
- [ ] `POST /auth/logout` — invalidate token / clear session
- [ ] `GET /members` — list all members in the user's group (for sharing dialog); returns id, name, initials, role

---

## 4. Collections

Needed by: **Library screen**, **Home screen**, **Add collection sheet**

- [ ] `GET /collections` — list user's collections; each returns: id, name, emoji, color, deck_count, word_count, due_count, progress (0.0–1.0)
- [ ] `POST /collections` — create: name, emoji, color, description
- [ ] `GET /collections/:id` — single collection detail
- [ ] `PUT /collections/:id` — rename, change emoji/color/description
- [ ] `DELETE /collections/:id`

---

## 5. Decks

Needed by: **Deck detail screen**, **Library screen**, **Edit deck sheet**, **Flashcard study screen**

- [ ] `GET /collections/:id/decks` — list decks in a collection; each returns: id, name, card_count, mastered_count, learning_count, new_count
- [ ] `POST /collections/:id/decks` — create deck: name, description
- [ ] `GET /decks/:id` — deck detail: name, collection_name, card_count, mastered/learning/new counts
- [ ] `PATCH /decks/:id` — rename, change description or collection
- [ ] `DELETE /decks/:id`
- [ ] `POST /decks/:id/share` — body: `{ member_ids: [string] }` → grant Viewer access; returns list of newly shared members

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

---

## 8. Flutter service layer

- [x] Ping/pong proof of concept
- [ ] `lib/services/api_service.dart` — base HTTP client, attaches `Authorization: Bearer <token>` header to every request, centralises error handling
- [ ] Token storage: save/read/delete JWT with `shared_preferences`
- [ ] `lib/models/` — Dart model classes with `fromJson` for: User, Collection, Deck, Card, SrsProgress, StudyStats

---

## 9. Flutter ↔ backend wiring (screen by screen)

Wire each screen to real API data once Go endpoints are ready.

### Login / Register screen
- [ ] Call `POST /auth/login`, store token, navigate to Home on success; show error toast on failure
- [ ] Call `POST /auth/register`, store token, navigate to Home on success; show error toast on failure

### Forgot password screen
- [ ] Call `POST /auth/forgot-password`; success state already built in UI

### Home screen
- [ ] Load streak, due count, mastered count from `GET /me` + `GET /me/stats`
- [ ] Load collection list from `GET /collections`
- [ ] Resume card: show most recently studied deck

### Library screen
- [ ] Load collections from `GET /collections`; apply filter pills client-side on returned data
- [ ] Add collection sheet: call `POST /collections`, refresh list on success + show info toast

### Deck detail screen
- [ ] Load deck from `GET /decks/:id`
- [ ] Load cards from `GET /decks/:id/cards`
- [ ] Progress bar + SRS chips use mastered/learning/new counts from the deck response
- [ ] Add flashcard sheet: call `POST /decks/:id/cards`, refresh card list + show info toast
- [ ] Edit deck sheet: call `PATCH /decks/:id`, refresh + show info toast
- [ ] Deck sharing popup: call `POST /decks/:id/share`, show success toast (already built)

### Flashcard study screen
- [ ] Load cards from `GET /decks/:id/cards?scope=<scope>`
- [ ] Show real due/weak counts in scope picker pills
- [ ] Each "Knew it" / "Again" swipe calls `POST /cards/:id/review`
- [ ] Show error toast if review call fails (card still advances locally)

### Profile screen
- [ ] Load user from `GET /me`, stats from `GET /me/stats`
- [ ] Notifications toggle calls `PATCH /me/settings`
- [ ] Sign out: clear stored token, navigate to Login screen

### Deck sharing popup
- [ ] Load member list from `GET /members`
- [ ] Share action calls `POST /decks/:id/share`

---

## 10. PWA deploy

- [ ] Flutter web build (`flutter build web`)
- [ ] Vercel deploy config (already has `vercel.json`)
- [ ] Railway deploy config (already has `railway.json` + `Dockerfile`)
- [ ] Environment variables set in both platforms (`DATABASE_URL`, `JWT_SECRET`, `ALLOWED_ORIGINS`)
