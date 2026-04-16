# Korean Learning App

A flashcard-based Korean language learning app for a study group.

## Structure

```
/backend    Go REST API
/app        Flutter PWA + mobile app
/docs       Design assets and notes
```

## Backend

Built with Go. Connects to PostgreSQL (Supabase).

```bash
cd backend
cp .env.example .env   # fill in your values
go run ./cmd/api
```

## Flutter app

```bash
cd app
flutter pub get
flutter run -d chrome   # web
flutter run             # mobile
```

## Deployment

- Backend → Railway (auto-deploy from /backend on push to main)
- Flutter → Vercel (auto-deploy from /app on push to main)
- Database → Supabase (managed PostgreSQL)
