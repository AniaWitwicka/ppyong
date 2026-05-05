package main

import (
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
	"github.com/yourname/koreanapp-backend/internal/db"
	"github.com/yourname/koreanapp-backend/internal/handler"
	"github.com/yourname/koreanapp-backend/internal/middleware"
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

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("GET /ping", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"message":"pong"}`))
	})

	// Current user aliases — resolve to the authenticated user once JWT is wired
	mux.HandleFunc("GET /me", handler.GetMe)
	mux.HandleFunc("PATCH /me", handler.UpdateMe)
	mux.HandleFunc("GET /me/stats", handler.GetMyStats)
	mux.HandleFunc("GET /me/settings", handler.GetMySettings)
	mux.HandleFunc("PATCH /me/settings", handler.UpdateMySettings)

	// Collections
	mux.HandleFunc("GET /collections", handler.ListCollections)
	mux.HandleFunc("POST /collections", handler.CreateCollection)
	mux.HandleFunc("GET /collections/{id}", handler.GetCollection)
	mux.HandleFunc("PATCH /collections/{id}", handler.UpdateCollection)
	mux.HandleFunc("DELETE /collections/{id}", handler.DeleteCollection)
	mux.HandleFunc("GET /collections/{id}/decks", handler.ListDecks)
	mux.HandleFunc("POST /collections/{id}/decks", handler.CreateDeck)

	// Decks
	mux.HandleFunc("GET /decks/{id}", handler.GetDeck)
	mux.HandleFunc("PATCH /decks/{id}", handler.UpdateDeck)
	mux.HandleFunc("DELETE /decks/{id}", handler.DeleteDeck)
	mux.HandleFunc("POST /decks/{id}/share", handler.ShareDeck)

	// Users
	mux.HandleFunc("GET /users", handler.ListUsers)
	mux.HandleFunc("GET /users/{id}", handler.GetUser)
	mux.HandleFunc("PATCH /users/{id}", handler.UpdateUser)
	mux.HandleFunc("GET /users/{id}/stats", handler.GetUserStats)
	mux.HandleFunc("GET /users/{id}/settings", handler.GetUserSettings)
	mux.HandleFunc("PATCH /users/{id}/settings", handler.UpdateUserSettings)

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: middleware.Logger(middleware.CORS(mux)),
	}

	log.Printf("starting server on :%s", port)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
