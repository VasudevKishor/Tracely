package services

import (
	"backend/models"
	"errors"
	"math/rand"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// TracingConfigService handles per-service tracing configuration operations
type TracingConfigService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

// NewTracingConfigService creates a new TracingConfigService
func NewTracingConfigService(db *gorm.DB) *TracingConfigService {
	return &TracingConfigService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

// CreateConfig creates a new service tracing configuration
func (s *TracingConfigService) CreateConfig(workspaceID, userID uuid.UUID, config *models.ServiceTracingConfig) (*models.ServiceTracingConfig, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Check if config already exists for this service in workspace
	var existingConfig models.ServiceTracingConfig
	if err := s.db.Where("workspace_id = ? AND service_name = ?", workspaceID, config.ServiceName).First(&existingConfig).Error; err == nil {
		return nil, errors.New("tracing configuration already exists for this service")
	}

	config.WorkspaceID = workspaceID

	// Set defaults if not provided
	if config.SamplingRate == 0 {
		config.SamplingRate = 1.0
	}
	if config.MaxBodySizeBytes == 0 {
		config.MaxBodySizeBytes = 10240
	}
	if config.ExcludePaths == "" {
		config.ExcludePaths = "[]"
	}
	if config.CustomTags == "" {
		config.CustomTags = "{}"
	}

	if err := s.db.Create(config).Error; err != nil {
		return nil, err
	}

	return config, nil
}

// GetConfigByID retrieves a tracing configuration by ID
func (s *TracingConfigService) GetConfigByID(configID, userID uuid.UUID) (*models.ServiceTracingConfig, error) {
	var config models.ServiceTracingConfig
	if err := s.db.First(&config, "id = ?", configID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(config.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	return &config, nil
}

// GetConfigByServiceName retrieves tracing config for a specific service in a workspace
func (s *TracingConfigService) GetConfigByServiceName(workspaceID uuid.UUID, serviceName string) (*models.ServiceTracingConfig, error) {
	var config models.ServiceTracingConfig
	if err := s.db.Where("workspace_id = ? AND service_name = ?", workspaceID, serviceName).First(&config).Error; err != nil {
		return nil, err
	}
	return &config, nil
}

// GetAllConfigs retrieves all tracing configurations for a workspace
func (s *TracingConfigService) GetAllConfigs(workspaceID, userID uuid.UUID) ([]models.ServiceTracingConfig, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	var configs []models.ServiceTracingConfig
	if err := s.db.Where("workspace_id = ?", workspaceID).Order("service_name ASC").Find(&configs).Error; err != nil {
		return nil, err
	}

	return configs, nil
}

// UpdateConfig updates an existing tracing configuration
func (s *TracingConfigService) UpdateConfig(configID, userID uuid.UUID, updates map[string]interface{}) (*models.ServiceTracingConfig, error) {
	var config models.ServiceTracingConfig
	if err := s.db.First(&config, "id = ?", configID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(config.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Validate sampling_rate if provided
	if samplingRate, ok := updates["sampling_rate"].(float64); ok {
		if samplingRate < 0 || samplingRate > 1 {
			return nil, errors.New("sampling_rate must be between 0 and 1")
		}
	}

	if err := s.db.Model(&config).Updates(updates).Error; err != nil {
		return nil, err
	}

	// Reload to get updated values
	if err := s.db.First(&config, "id = ?", configID).Error; err != nil {
		return nil, err
	}

	return &config, nil
}

// DeleteConfig deletes a tracing configuration
func (s *TracingConfigService) DeleteConfig(configID, userID uuid.UUID) error {
	var config models.ServiceTracingConfig
	if err := s.db.First(&config, "id = ?", configID).Error; err != nil {
		return err
	}

	if !s.workspaceService.HasAccess(config.WorkspaceID, userID) {
		return errors.New("access denied")
	}

	return s.db.Delete(&config).Error
}

// ToggleTracing enables or disables tracing for a service
func (s *TracingConfigService) ToggleTracing(configID, userID uuid.UUID, enabled bool) (*models.ServiceTracingConfig, error) {
	return s.UpdateConfig(configID, userID, map[string]interface{}{"enabled": enabled})
}

// IsTracingEnabled checks if tracing is enabled for a service in a workspace
// Returns true if no config exists (default behavior) or if config exists and is enabled
func (s *TracingConfigService) IsTracingEnabled(workspaceID uuid.UUID, serviceName string) bool {
	config, err := s.GetConfigByServiceName(workspaceID, serviceName)
	if err != nil {
		// No config found - tracing is enabled by default
		return true
	}
	return config.Enabled
}

// ShouldSample determines whether a request should be sampled based on sampling rate
func (s *TracingConfigService) ShouldSample(workspaceID uuid.UUID, serviceName string) bool {
	config, err := s.GetConfigByServiceName(workspaceID, serviceName)
	if err != nil {
		// No config found - sample all requests by default
		return true
	}

	if !config.Enabled {
		return false
	}

	// Sample based on sampling rate
	return rand.Float64() < config.SamplingRate
}

// GetTracingSettings returns all tracing settings for a service
// Returns default settings if no config exists
func (s *TracingConfigService) GetTracingSettings(workspaceID uuid.UUID, serviceName string) *models.ServiceTracingConfig {
	config, err := s.GetConfigByServiceName(workspaceID, serviceName)
	if err != nil {
		// Return default config
		return &models.ServiceTracingConfig{
			ServiceName:         serviceName,
			Enabled:             true,
			SamplingRate:        1.0,
			LogTraceHeaders:     true,
			PropagateContext:    true,
			CaptureRequestBody:  false,
			CaptureResponseBody: false,
			MaxBodySizeBytes:    10240,
			ExcludePaths:        "[]",
			CustomTags:          "{}",
		}
	}
	return config
}

// BulkUpdateEnabled updates the enabled status for multiple services
func (s *TracingConfigService) BulkUpdateEnabled(workspaceID, userID uuid.UUID, serviceNames []string, enabled bool) (int64, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return 0, errors.New("access denied")
	}

	result := s.db.Model(&models.ServiceTracingConfig{}).
		Where("workspace_id = ? AND service_name IN ?", workspaceID, serviceNames).
		Update("enabled", enabled)

	return result.RowsAffected, result.Error
}

// GetEnabledServices returns a list of services with tracing enabled in a workspace
func (s *TracingConfigService) GetEnabledServices(workspaceID uuid.UUID) ([]string, error) {
	var configs []models.ServiceTracingConfig
	if err := s.db.Where("workspace_id = ? AND enabled = ?", workspaceID, true).Select("service_name").Find(&configs).Error; err != nil {
		return nil, err
	}

	services := make([]string, len(configs))
	for i, config := range configs {
		services[i] = config.ServiceName
	}
	return services, nil
}

// GetDisabledServices returns a list of services with tracing disabled in a workspace
func (s *TracingConfigService) GetDisabledServices(workspaceID uuid.UUID) ([]string, error) {
	var configs []models.ServiceTracingConfig
	if err := s.db.Where("workspace_id = ? AND enabled = ?", workspaceID, false).Select("service_name").Find(&configs).Error; err != nil {
		return nil, err
	}

	services := make([]string, len(configs))
	for i, config := range configs {
		services[i] = config.ServiceName
	}
	return services, nil
}
