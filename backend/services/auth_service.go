/*
Package services contains the business logic layer for the application.
This file implements the AuthService, which handles user authentication and authorization,
including registration, login, JWT token generation/validation, and refresh token management.
It uses bcrypt for password hashing, JWT for stateless authentication, and integrates
with the database via GORM for user and token storage. It also creates default workspaces
and settings upon user registration.
*/
package services

import (
	"errors"
	"time"

	"backend/config"
	"backend/models"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// TokenPair represents a pair of access and refresh tokens for a user.
type TokenPair struct {
	AccessToken  string
	RefreshToken string
}

// AuthService handles all authentication-related operations.
type AuthService struct {
	db     *gorm.DB
	config *config.Config
}

// JWTClaims defines the structure of JWT payload for authentication.
type JWTClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// NewAuthService creates a new instance of AuthService.
func NewAuthService(db *gorm.DB, cfg *config.Config) *AuthService {
	return &AuthService{
		db:     db,
		config: cfg,
	}
}

/*
Register creates a new user with email, password, and name.
It hashes the password, generates access and refresh tokens,
and sets up a default workspace and user settings.
*/
func (s *AuthService) Register(email, password, name string) (*models.User, *TokenPair, error) {
	var existingUser models.User
	if err := s.db.Where("email = ?", email).First(&existingUser).Error; err == nil {
		// Email already exists
		return nil, nil, errors.New("email already exists")
	}
	// Hash the user's password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, nil, err
	}
	// Create user record
	user := models.User{
		Email:    email,
		Password: string(hashedPassword),
		Name:     name,
	}

	if err := s.db.Create(&user).Error; err != nil {
		return nil, nil, err
	}
	// Generate JWT access token
	accessToken, err := s.GenerateToken(user.ID, user.Email)
	if err != nil {
		return nil, nil, err
	}
	// Generate refresh token
	refreshToken, err := s.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, nil, err
	}

	// default workspace, member, settings (unchanged)
	workspace := models.Workspace{
		Name:        "Default Workspace",
		Description: "Your default workspace",
		OwnerID:     user.ID,
	}
	s.db.Create(&workspace)
	// Add user as admin member of default workspace
	s.db.Create(&models.WorkspaceMember{
		WorkspaceID: workspace.ID,
		UserID:      user.ID,
		Role:        "admin",
	})
	// Create default user settings
	s.db.Create(&models.UserSettings{
		UserID: user.ID,
		Theme:  "light",
	})

	return &user, &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// Login authenticates a user using email and password.
// It validates credentials, and if correct, returns a JWT access and refresh token pair
func (s *AuthService) Login(email, password string) (*models.User, *TokenPair, error) {
	var user models.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, nil, errors.New("invalid credentials")
	}
	// Compare hashed password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return nil, nil, errors.New("invalid credentials")
	}
	// Generate tokens
	accessToken, err := s.GenerateToken(user.ID, user.Email)
	if err != nil {
		return nil, nil, err
	}

	refreshToken, err := s.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, nil, err
	}

	return &user, &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// GenerateToken creates a JWT access token for a given user with 1-hour expiration.
func (s *AuthService) GenerateToken(userID uuid.UUID, email string) (string, error) {
	expirationTime := time.Now().Add(1 * time.Hour)

	claims := &JWTClaims{
		UserID: userID.String(),
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(s.config.JWTSecret))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// ValidateToken parses and validates a JWT access token
func (s *AuthService) ValidateToken(tokenString string) (*JWTClaims, error) {
	claims := &JWTClaims{}
	//This function parses a JWT string (tokenString) and validates its signature.
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(s.config.JWTSecret), nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}

// GenerateRefreshToken creates a long-lived refresh token and stores it in the database
func (s *AuthService) GenerateRefreshToken(userID uuid.UUID) (string, error) {
	refreshToken := uuid.New().String()
	expiresAt := time.Now().Add(720 * time.Hour) // 30 days

	token := models.RefreshToken{
		UserID:    userID,
		Token:     refreshToken,
		ExpiresAt: expiresAt,
	}

	if err := s.db.Create(&token).Error; err != nil {
		return "", err
	}

	return refreshToken, nil
}

// RefreshAccessToken validates a refresh token and generates a new access token.
func (s *AuthService) RefreshAccessToken(refreshToken string) (string, error) {
	var token models.RefreshToken
	if err := s.db.Where("token = ? AND revoked_at IS NULL", refreshToken).First(&token).Error; err != nil {
		return "", errors.New("invalid refresh token")
	}

	if time.Now().After(token.ExpiresAt) {
		return "", errors.New("refresh token expired")
	}

	//Get user from database
	var user models.User
	if err := s.db.First(&user, token.UserID).Error; err != nil {
		return "", err
	}

	// Generate new access token
	accessToken, err := s.GenerateToken(user.ID, user.Email)
	if err != nil {
		return "", err
	}

	return accessToken, nil
}

// RevokeRefreshToken marks a refresh token as revoked in the database.
func (s *AuthService) RevokeRefreshToken(refreshToken string) error {
	now := time.Now()
	return s.db.Model(&models.RefreshToken{}).
		Where("token = ?", refreshToken).
		Update("revoked_at", now).Error
}
