package services

import (
	"backend/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type SettingsService struct {
	db *gorm.DB
}

func NewSettingsService(db *gorm.DB) *SettingsService {
	return &SettingsService{db: db}
}

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
