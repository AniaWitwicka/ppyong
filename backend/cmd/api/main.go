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

	userHandler       := handler.NewUserHandler(repository.NewUserRepository(pool))
	authHandler       := handler.NewAuthHandler(repository.NewAuthRepository(pool))
	collectionHandler := handler.NewCollectionHandler(repository.NewCollectionRepository(pool))
	deckHandler       := handler.NewDeckHandler(repository.NewDeckRepository(pool))
	cardHandler       := handler.NewCardHandler(repository.NewCardRepository(pool))
	groupHandler      := handler.NewGroupHandler(repository.NewGroupRepository(pool))
	inviteHandler     := handler.NewInviteHandler(repository.NewInviteRepository(pool))
	friendHandler     := handler.NewFriendHandler(repository.NewFriendRepository(pool))

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
	mux.HandleFunc("GET /me/weak-words", auth(userHandler.GetMyWeakCards))

	// Collections
	mux.HandleFunc("GET /collections", auth(collectionHandler.List))
	mux.HandleFunc("POST /collections", auth(collectionHandler.Create))
	mux.HandleFunc("GET /collections/{id}", auth(collectionHandler.Get))
	mux.HandleFunc("PATCH /collections/{id}", auth(collectionHandler.Update))
	mux.HandleFunc("DELETE /collections/{id}", auth(collectionHandler.Delete))
	mux.HandleFunc("POST /collections/{id}/share", auth(collectionHandler.Share))
	mux.HandleFunc("GET /collections/{id}/decks", auth(deckHandler.List))
	mux.HandleFunc("POST /collections/{id}/decks", auth(deckHandler.Create))

	// Decks
	mux.HandleFunc("GET /decks/{id}", auth(deckHandler.Get))
	mux.HandleFunc("PATCH /decks/{id}", auth(deckHandler.Update))
	mux.HandleFunc("DELETE /decks/{id}", auth(deckHandler.Delete))
	mux.HandleFunc("POST /decks/{id}/share", auth(deckHandler.Share))
	mux.HandleFunc("GET /decks/{id}/cards", auth(cardHandler.List))
	mux.HandleFunc("POST /decks/{id}/cards", auth(cardHandler.Create))

	// Cards
	mux.HandleFunc("PATCH /cards/{id}", auth(cardHandler.Update))
	mux.HandleFunc("DELETE /cards/{id}", auth(cardHandler.Delete))

	// Users
	mux.HandleFunc("GET /users", auth(userHandler.ListUsers))
	mux.HandleFunc("GET /users/{id}", auth(userHandler.GetUser))
	mux.HandleFunc("PATCH /users/{id}", auth(userHandler.UpdateUser))
	mux.HandleFunc("GET /users/{id}/stats", auth(userHandler.GetUserStats))
	mux.HandleFunc("GET /users/{id}/settings", auth(userHandler.GetUserSettings))
	mux.HandleFunc("PATCH /users/{id}/settings", auth(userHandler.UpdateUserSettings))
	mux.HandleFunc("GET /users/search", auth(friendHandler.Search))

	// Groups
	mux.HandleFunc("GET /groups", auth(groupHandler.List))
	mux.HandleFunc("POST /groups", auth(groupHandler.Create))
	mux.HandleFunc("GET /groups/{id}", auth(groupHandler.Get))
	mux.HandleFunc("PATCH /groups/{id}", auth(groupHandler.Update))
	mux.HandleFunc("DELETE /groups/{id}", auth(groupHandler.Delete))
	mux.HandleFunc("POST /groups/{id}/leave", auth(groupHandler.Leave))
	mux.HandleFunc("POST /groups/{id}/invite", auth(inviteHandler.Create))

	// Invites
	mux.HandleFunc("GET /invites", auth(inviteHandler.List))
	mux.HandleFunc("GET /invites/pending-count", auth(inviteHandler.PendingCount))
	mux.HandleFunc("POST /invites/{id}/accept", auth(inviteHandler.Accept))
	mux.HandleFunc("POST /invites/{id}/decline", auth(inviteHandler.Decline))

	// Friends
	mux.HandleFunc("GET /friends", auth(friendHandler.List))
	mux.HandleFunc("GET /friends/requests", auth(friendHandler.ListPendingRequests))
	mux.HandleFunc("POST /friends/request", auth(friendHandler.SendRequest))
	mux.HandleFunc("POST /friends/{id}/accept", auth(friendHandler.Accept))
	mux.HandleFunc("POST /friends/{id}/decline", auth(friendHandler.Decline))

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: middleware.Logger(middleware.CORS(mux)),
	}

	log.Printf("starting server on :%s", port)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
