package services

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"io"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Secret struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Key         string    `gorm:"not null"`
	Value       string    `gorm:"type:text;not null"` // Encrypted
	Description string
	CreatedBy   uuid.UUID `gorm:"type:uuid"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
	ExpiresAt   *time.Time
}

type SecretsService struct {
	db            *gorm.DB
	encryptionKey []byte
}

func NewSecretsService(db *gorm.DB, key string) *SecretsService {
	// In production, use proper key management (AWS KMS, HashiCorp Vault, etc.)
	keyBytes := []byte(key)
	if len(keyBytes) < 32 {
		// Pad key to 32 bytes for AES-256
		padded := make([]byte, 32)
		copy(padded, keyBytes)
		keyBytes = padded
	}
	return &SecretsService{
		db:            db,
		encryptionKey: keyBytes[:32],
	}
}

func (s *SecretsService) encrypt(plaintext string) (string, error) {
	block, err := aes.NewCipher(s.encryptionKey)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

func (s *SecretsService) decrypt(ciphertext string) (string, error) {
	data, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(s.encryptionKey)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	if len(data) < gcm.NonceSize() {
		return "", errors.New("ciphertext too short")
	}

	nonce, cipherBytes := data[:gcm.NonceSize()], data[gcm.NonceSize():]
	plaintext, err := gcm.Open(nil, nonce, cipherBytes, nil)

	if err != nil {
		return "", err
	}

	return string(plaintext), nil
}

func (s *SecretsService) CreateSecret(workspaceID, userID uuid.UUID, key, value, description string) (*Secret, error) {
	encrypted, err := s.encrypt(value)
	if err != nil {
		return nil, err
	}

	secret := Secret{
		ID:          uuid.New(),
		WorkspaceID: workspaceID,
		Key:         key,
		Value:       encrypted,
		Description: description,
		CreatedBy:   userID,
	}

	if err := s.db.Create(&secret).Error; err != nil {
		return nil, err
	}

	return &secret, nil
}

func (s *SecretsService) GetSecret(secretID, workspaceID uuid.UUID) (string, error) {
	var secret Secret
	if err := s.db.Where("id = ? AND workspace_id = ?", secretID, workspaceID).First(&secret).Error; err != nil {
		return "", err
	}

	// Check if expired
	if secret.ExpiresAt != nil && time.Now().After(*secret.ExpiresAt) {
		return "", errors.New("secret expired")
	}

	return s.decrypt(secret.Value)
}

func (s *SecretsService) RotateSecret(secretID, workspaceID uuid.UUID, newValue string) error {
	encrypted, err := s.encrypt(newValue)
	if err != nil {
		return err
	}

	return s.db.Model(&Secret{}).
		Where("id = ? AND workspace_id = ?", secretID, workspaceID).
		Update("value", encrypted).Error
}
