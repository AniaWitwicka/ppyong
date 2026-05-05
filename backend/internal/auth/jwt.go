package auth

import (
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const UserIDKey contextKey = "userID"

func GenerateToken(userID string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": userID,
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(30 * 24 * time.Hour).Unix(),
	})
	return token.SignedString([]byte(secret))
}

func ValidateToken(tokenString string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	token, err := jwt.Parse(tokenString, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method")
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return "", fmt.Errorf("invalid token")
	}
	sub, err := token.Claims.GetSubject()
	if err != nil {
		return "", fmt.Errorf("invalid token claims")
	}
	return sub, nil
}
