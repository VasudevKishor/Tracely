package services

import (
	"backend/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// SettingsService provides business logic for managing user settings.
type SettingsService struct {
	db *gorm.DB
}

// NewSettingsService creates a new instance of SettingsService.
func NewSettingsService(db *gorm.DB) *SettingsService {
	return &SettingsService{db: db}
}

// GetSettings retrieves the settings for a user, creating default settings if none exist.
func (s *SettingsService) GetSettings(userID uuid.UUID) (*models.UserSettings, error) {
	var settings models.UserSettings
	err := s.db.Where("user_id = ?", userID).First(&settings).Error

	if err == gorm.ErrRecordNotFound {
		// Create default settings
		settings = models.UserSettings{
			UserID:               userID,
			Theme:                "light",
			NotificationsEnabled: true,
			EmailNotifications:   true,
			Language:             "en",
			Timezone:             "UTC",
			Preferences:          datatypes.JSON([]byte("{}")),
		}
		s.db.Create(&settings)
		return &settings, nil
	}

	return &settings, err
}

// UpdateSettings updates the settings for a user with the provided field updates.
func (s *SettingsService) UpdateSettings(userID uuid.UUID, updates map[string]interface{}) (*models.UserSettings, error) {
	settings, err := s.GetSettings(userID)
	if err != nil {
		return nil, err
	}

	if err := s.db.Model(settings).Updates(updates).Error; err != nil {
		return nil, err
	}

	return settings, nil
}
