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

type AuthService struct {
	db     *gorm.DB
	config *config.Config
}

type JWTClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

func NewAuthService(db *gorm.DB, cfg *config.Config) *AuthService {
	return &AuthService{
		db:     db,
		config: cfg,
	}
}

func (s *AuthService) Register(email, password, name string) (*models.User, string, error) {
	// Check if user already exists
	var existingUser models.User
	if err := s.db.Where("email = ?", email).First(&existingUser).Error; err == nil {
		return nil, "", errors.New("email already exists")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, "", err
	}

	// Create user
	user := models.User{
		Email:    email,
		Password: string(hashedPassword),
		Name:     name,
	}

	if err := s.db.Create(&user).Error; err != nil {
		return nil, "", err
	}

	// Generate JWT token
	token, err := s.GenerateToken(user.ID, user.Email)
	if err != nil {
		return nil, "", err
	}

	// Create default workspace for user
	workspace := models.Workspace{
		Name:        "Default Workspace",
		Description: "Your default workspace",
		OwnerID:     user.ID,
	}
	if err := s.db.Create(&workspace).Error; err != nil {
		return nil, "", err
	}

	// Add user as admin member
	member := models.WorkspaceMember{
		WorkspaceID: workspace.ID,
		UserID:      user.ID,
		Role:        "admin",
	}
	if err := s.db.Create(&member).Error; err != nil {
		return nil, "", err
	}

	// Create default settings
	settings := models.UserSettings{
		UserID: user.ID,
		Theme:  "light",
	}
	if err := s.db.Create(&settings).Error; err != nil {
		return nil, "", err
	}

	return &user, token, nil
}

func (s *AuthService) Login(email, password string) (*models.User, string, error) {
	var user models.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, "", errors.New("invalid credentials")
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return nil, "", errors.New("invalid credentials")
	}

	// Generate JWT token
	token, err := s.GenerateToken(user.ID, user.Email)
	if err != nil {
		return nil, "", err
	}

	return &user, token, nil
}

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

func (s *AuthService) ValidateToken(tokenString string) (*JWTClaims, error) {
	claims := &JWTClaims{}

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

func (s *AuthService) RefreshAccessToken(refreshToken string) (string, error) {
	var token models.RefreshToken
	if err := s.db.Where("token = ? AND revoked_at IS NULL", refreshToken).First(&token).Error; err != nil {
		return "", errors.New("invalid refresh token")
	}

	if time.Now().After(token.ExpiresAt) {
		return "", errors.New("refresh token expired")
	}

	// Get user
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

func (s *AuthService) RevokeRefreshToken(refreshToken string) error {
	now := time.Now()
	return s.db.Model(&models.RefreshToken{}).
		Where("token = ?", refreshToken).
		Update("revoked_at", now).Error
}
