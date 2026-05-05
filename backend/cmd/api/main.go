package main

import (
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
	"github.com/yourname/koreanapp-backend/internal/db"
	"github.com/yourname/koreanapp-backend/internal/handler"
	"github.com/yourname/koreanapp-backend/internal/middleware"
	"github.com/yourname/koreanapp-backend/internal/repository"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("no .env file found, using environment variables")
	}

	pool, err := db.Connect()
	if err != nil {
		log.Fatalf("database connection failed: %v", err)
	}
	defer pool.Close()
	log.Println("database connected")

	userHandler := handler.NewUserHandler(repository.NewUserRepository(pool))
	authHandler := handler.NewAuthHandler(repository.NewAuthRepository(pool))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()

	// Public routes
	mux.HandleFunc("GET /ping", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"message":"pong"}`))
	})
	mux.HandleFunc("POST /auth/register", authHandler.Register)
	mux.HandleFunc("POST /auth/login", authHandler.Login)

	// Protected routes — require valid JWT
	auth := func(h http.HandlerFunc) http.HandlerFunc {
		return middleware.RequireAuth(h).ServeHTTP
	}

	// Current user
	mux.HandleFunc("GET /me", auth(userHandler.GetMe))
	mux.HandleFunc("PATCH /me", auth(userHandler.UpdateMe))
	mux.HandleFunc("GET /me/stats", auth(userHandler.GetMyStats))
	mux.HandleFunc("GET /me/settings", auth(userHandler.GetMySettings))
	mux.HandleFunc("PATCH /me/settings", auth(userHandler.UpdateMySettings))

	// Collections
	mux.HandleFunc("GET /collections", auth(handler.ListCollections))
	mux.HandleFunc("POST /collections", auth(handler.CreateCollection))
	mux.HandleFunc("GET /collections/{id}", auth(handler.GetCollection))
	mux.HandleFunc("PATCH /collections/{id}", auth(handler.UpdateCollection))
	mux.HandleFunc("DELETE /collections/{id}", auth(handler.DeleteCollection))
	mux.HandleFunc("GET /collections/{id}/decks", auth(handler.ListDecks))
	mux.HandleFunc("POST /collections/{id}/decks", auth(handler.CreateDeck))

	// Decks
	mux.HandleFunc("GET /decks/{id}", auth(handler.GetDeck))
	mux.HandleFunc("PATCH /decks/{id}", auth(handler.UpdateDeck))
	mux.HandleFunc("DELETE /decks/{id}", auth(handler.DeleteDeck))
	mux.HandleFunc("POST /decks/{id}/share", auth(handler.ShareDeck))

	// Users
	mux.HandleFunc("GET /users", auth(userHandler.ListUsers))
	mux.HandleFunc("GET /users/{id}", auth(userHandler.GetUser))
	mux.HandleFunc("PATCH /users/{id}", auth(userHandler.UpdateUser))
	mux.HandleFunc("GET /users/{id}/stats", auth(userHandler.GetUserStats))
	mux.HandleFunc("GET /users/{id}/settings", auth(userHandler.GetUserSettings))
	mux.HandleFunc("PATCH /users/{id}/settings", auth(userHandler.UpdateUserSettings))

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: middleware.Logger(middleware.CORS(mux)),
	}

	log.Printf("starting server on :%s", port)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
