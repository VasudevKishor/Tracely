package services

import (
	"backend/models"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type EnvironmentService struct {
	db *gorm.DB
}

func NewEnvironmentService(db *gorm.DB) *EnvironmentService {
	return &EnvironmentService{db: db}
}

// Create creates a new environment
func (s *EnvironmentService) Create(workspaceID uuid.UUID, name, envType, description string, isActive bool, userID uuid.UUID) (*models.Environment, error) {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check if environment with same name exists
	var existingEnv models.Environment
	if err := s.db.Where("workspace_id = ? AND name = ?", workspaceID, name).First(&existingEnv).Error; err == nil {
		return nil, gorm.ErrDuplicatedKey
	}

	environment := &models.Environment{
		WorkspaceID: workspaceID,
		Name:        name,
		Type:        envType,
		Description: description,
		IsActive:    isActive,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := s.db.Create(environment).Error; err != nil {
		return nil, err
	}

	return environment, nil
}

// GetByID gets an environment by ID
func (s *EnvironmentService) GetByID(workspaceID, environmentID uuid.UUID, userID uuid.UUID) (*models.Environment, error) {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return nil, err
	}

	// Preload variables and secrets
	s.db.Model(&environment).Association("Variables").Find(&environment.Variables)
	s.db.Model(&environment).Association("Secrets").Find(&environment.Secrets)

	return &environment, nil
}

// GetAll gets all environments for a workspace
func (s *EnvironmentService) GetAll(workspaceID uuid.UUID, userID uuid.UUID) ([]models.Environment, error) {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	var environments []models.Environment
	if err := s.db.Where("workspace_id = ?", workspaceID).Find(&environments).Error; err != nil {
		return nil, err
	}

	// Preload variables and secrets for each environment
	for i := range environments {
		s.db.Model(&environments[i]).Association("Variables").Find(&environments[i].Variables)
		s.db.Model(&environments[i]).Association("Secrets").Find(&environments[i].Secrets)
	}

	return environments, nil
}

// Update updates an environment
func (s *EnvironmentService) Update(workspaceID, environmentID uuid.UUID, userID uuid.UUID, updates map[string]interface{}) (*models.Environment, error) {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check if environment exists
	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return nil, err
	}

	updates["updated_at"] = time.Now()

	if err := s.db.Model(&environment).Updates(updates).Error; err != nil {
		return nil, err
	}

	// Reload with associations
	s.db.Model(&environment).Association("Variables").Find(&environment.Variables)
	s.db.Model(&environment).Association("Secrets").Find(&environment.Secrets)

	return &environment, nil
}

// Delete deletes an environment
func (s *EnvironmentService) Delete(workspaceID, environmentID uuid.UUID, userID uuid.UUID) error {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return err
	}

	// Check if environment exists
	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return err
	}

	// Delete associated variables and secrets
	if err := s.db.Where("environment_id = ?", environmentID).Delete(&models.EnvironmentVariable{}).Error; err != nil {
		return err
	}
	if err := s.db.Where("environment_id = ?", environmentID).Delete(&models.EnvironmentSecret{}).Error; err != nil {
		return err
	}

	// Delete environment
	return s.db.Delete(&environment).Error
}

// AddVariable adds a variable to an environment
func (s *EnvironmentService) AddVariable(workspaceID, environmentID uuid.UUID, key, value, varType, description string, userID uuid.UUID) (*models.EnvironmentVariable, error) {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check if environment exists
	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return nil, err
	}

	// Check if variable with same key exists
	var existingVar models.EnvironmentVariable
	if err := s.db.Where("environment_id = ? AND key = ?", environmentID, key).First(&existingVar).Error; err == nil {
		return nil, gorm.ErrDuplicatedKey
	}

	variable := &models.EnvironmentVariable{
		EnvironmentID: environmentID,
		Key:           key,
		Value:         value,
		Type:          varType,
		Description:   description,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	if err := s.db.Create(variable).Error; err != nil {
		return nil, err
	}

	return variable, nil
}

// UpdateVariable updates a variable
func (s *EnvironmentService) UpdateVariable(workspaceID, environmentID, variableID uuid.UUID, userID uuid.UUID, updates map[string]interface{}) (*models.EnvironmentVariable, error) {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check if variable exists
	var variable models.EnvironmentVariable
	if err := s.db.Where("id = ? AND environment_id = ?", variableID, environmentID).First(&variable).Error; err != nil {
		return nil, err
	}

	updates["updated_at"] = time.Now()

	if err := s.db.Model(&variable).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &variable, nil
}

// DeleteVariable deletes a variable
func (s *EnvironmentService) DeleteVariable(workspaceID, environmentID, variableID uuid.UUID, userID uuid.UUID) error {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return err
	}

	// Check if variable exists
	var variable models.EnvironmentVariable
	if err := s.db.Where("id = ? AND environment_id = ?", variableID, environmentID).First(&variable).Error; err != nil {
		return err
	}

	return s.db.Delete(&variable).Error
}

// GetVariables gets all variables for an environment
func (s *EnvironmentService) GetVariables(workspaceID, environmentID uuid.UUID, userID uuid.UUID) ([]models.EnvironmentVariable, error) {
	// Check if user has access to workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check if environment exists
	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return nil, err
	}

	var variables []models.EnvironmentVariable
	if err := s.db.Where("environment_id = ?", environmentID).Find(&variables).Error; err != nil {
		return nil, err
	}

	return variables, nil
}
