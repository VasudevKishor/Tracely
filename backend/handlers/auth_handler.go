package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	Name     string `json:"name" binding:"required"`
}

// Login - FIXED to match Flutter frontend expectations
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := h.authService.Login(req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Generate access token
	token, err := h.authService.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token generation failed"})
		return
	}

	// Create refresh token
	refreshToken, err := h.authService.CreateRefreshToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Refresh token creation failed"})
		return
	}

	// FIXED RESPONSE FORMAT - Matches Flutter frontend expectations
	c.JSON(http.StatusOK, gin.H{
		"access_token":  token,            // ✅ Frontend expects "access_token"
		"refresh_token": refreshToken,     // ✅ Frontend expects "refresh_token"
		"user_id":       user.ID.String(), // ✅ Frontend uses this
		"email":         user.Email,       // ✅ Frontend displays this
		"name":          user.Name,        // ✅ Frontend displays this
	})
}

// Register - FIXED to auto-login after registration
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := h.authService.Register(req.Email, req.Password, req.Name)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// FIXED: Generate tokens immediately after registration for auto-login
	token, err := h.authService.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token generation failed"})
		return
	}

	refreshToken, err := h.authService.CreateRefreshToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Refresh token creation failed"})
		return
	}

	// FIXED RESPONSE FORMAT - Auto-login after registration
	c.JSON(http.StatusCreated, gin.H{
		"message":       "User created successfully",
		"access_token":  token,        // ✅ Allows immediate login
		"refresh_token": refreshToken, // ✅ For token refresh
		"user_id":       user.ID.String(),
		"email":         user.Email,
		"name":          user.Name,
	})
}

// Logout
func (h *AuthHandler) Logout(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	if err := h.authService.Logout(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Logged out successfully"})
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshToken
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, err := h.authService.ValidateRefreshToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid refresh token"})
		return
	}

	// Generate new access token
	accessToken, err := h.authService.GenerateToken(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token generation failed"})
		return
	}

	// Generate new refresh token
	newRefreshToken, err := h.authService.CreateRefreshToken(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Refresh token creation failed"})
		return
	}

	// Revoke old refresh token
	h.authService.RevokeRefreshToken(req.RefreshToken)

	c.JSON(http.StatusOK, gin.H{
		"access_token":  accessToken,
		"refresh_token": newRefreshToken,
	})
}

// VerifyToken
func (h *AuthHandler) VerifyToken(c *gin.Context) {
	userID, exists := middlewares.GetUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"valid":   true,
		"user_id": userID.String(),
	})
}
