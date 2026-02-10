/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the AuthHandler, which manages authentication-related routes
such as login, registration, token refresh, and verification. It acts as the
interface between HTTP requests and the AuthService business logic, handling
JSON binding, validation, and response formatting for user authentication flows.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// AuthHandler struct holds the AuthService instance to handle authentication logic
type AuthHandler struct {
	authService *services.AuthService
}

// NewAuthHandler creates a new instance of AuthHandler
func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// LoginRequest defines the expected JSON payload for login requests
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// RegisterRequest defines the expected JSON payload for registration requests
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Name     string `json:"name" binding:"required"`
}

// Login handles user login requests
// It validates the input, authenticates the user via AuthService, and returns JWT tokens
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	// Bind incoming JSON payload to struct and validate
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Authenticate user using AuthService
	user, token, err := h.authService.Login(req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	// Return access and refresh tokens along with user info
	c.JSON(http.StatusOK, gin.H{
		"access_token":  token.AccessToken,
		"refresh_token": token.RefreshToken,
		"user_id":       user.ID,
		"email":         user.Email,
		"name":          user.Name,
	})

}

// Register handles user registration requests
// It creates a new user, generates tokens, and returns user info
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	// Bind incoming JSON payload to struct and validate
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Register the user using AuthService
	user, token, err := h.authService.Register(req.Email, req.Password, req.Name)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Return success message with tokens and user info
	c.JSON(http.StatusCreated, gin.H{
		"message":       "User created successfully",
		"access_token":  token.AccessToken,
		"refresh_token": token.RefreshToken,
		"user_id":       user.ID,
		"email":         user.Email,
		"name":          user.Name,
	})

}

// Logout handles user logout requests
// Currently, it just returns a success message; token invalidation can be added if needed
func (h *AuthHandler) Logout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Logged out successfully"})
}

// RefreshTokenRequest defines the expected JSON payload for refresh token requests
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshToken handles access token renewal using a refresh token
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Generate new access token using the refresh token
	token, err := h.authService.RefreshAccessToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	// Return the new access token
	c.JSON(http.StatusOK, gin.H{
		"access_token": token,
	})
}

// VerifyToken checks if the provided JWT access token is valid
func (h *AuthHandler) VerifyToken(c *gin.Context) {
	// Extract user ID from the context, set by AuthMiddleware
	userID, err := middlewares.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "unauthorized",
		})
		return
	}
	// Return success message with the user ID
	c.JSON(http.StatusOK, gin.H{
		"message": "Token is valid",
		"user_id": userID.String(),
	})
}
