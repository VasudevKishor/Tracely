/*
Package services contains the business logic layer for the application.
This file implements the SettingsService, which manages user-specific settings
and preferences such as theme, notifications, language, and timezone. It provides
CRUD operations for user settings, creating default settings if none exist,
and integrates with the database to persist user preferences for a personalized experience.
*/
package services

import (
	"backend/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// SettingsService provides methods to manage user settings in the database
type SettingsService struct {
	db *gorm.DB
}

// NewSettingsService initializes a new SettingsService with the given database connection.
func NewSettingsService(db *gorm.DB) *SettingsService {
	return &SettingsService{db: db}
}

// userID: the UUID of the user whose settings are being fetched.
func (s *SettingsService) GetSettings(userID uuid.UUID) (*models.UserSettings, error) {
	var settings models.UserSettings
	// Attempt to find existing settings for the user
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
		// Save default settings to the database
		s.db.Create(&settings)
		return &settings, nil
	}
	// Return existing settings or any other error
	return &settings, err
}

// UpdateSettings updates the user's settings with the given updates.
func (s *SettingsService) UpdateSettings(userID uuid.UUID, updates map[string]interface{}) (*models.UserSettings, error) {
	// Retrieve existing settings (or create default if none exist)
	settings, err := s.GetSettings(userID)
	if err != nil {
		return nil, err
	}
	// Apply updates to the settings in the database
	if err := s.db.Model(settings).Updates(updates).Error; err != nil {
		return nil, err
	}
	// Return the updated settings
	return settings, nil
}
