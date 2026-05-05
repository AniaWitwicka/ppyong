# Migrations log

Run these in order in the Supabase SQL editor (Dashboard → SQL Editor).

| # | File | Description | Applied |
|---|------|-------------|---------|
| 001 | `001_initial_schema.sql` | Core tables: users, collections, decks, cards, srs_progress | ✅ 2026-05-05 |
| 002 | `002_user_profile_additions.sql` | Add `initials`, `best_streak` to users; create `user_settings` table | ✅ 2026-05-05 |
| 003 | `003_collection_additions.sql` | Add `emoji`, `color` to collections | ✅ 2026-05-05 |
| 004 | `004_seed_users.sql` | Seed 5 test users with fixed UUIDs + default settings | ✅ 2026-05-05 |
