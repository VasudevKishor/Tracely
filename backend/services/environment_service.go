/*
Package services contains business logic for the application.
This file implements the EnvironmentService, which provides CRUD operations
for managing environments, variables, and secrets within a workspace.
*/
package services

import (
	"backend/models"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// EnvironmentService handles operations on environments, variables, and secrets.
type EnvironmentService struct {
	db *gorm.DB
}

// NewEnvironmentService creates a new EnvironmentService instance.
func NewEnvironmentService(db *gorm.DB) *EnvironmentService {
	return &EnvironmentService{db: db}
}

// Create creates a new environment in a workspace.
// It checks if the user has access and ensures no duplicate environment names.
func (s *EnvironmentService) Create(workspaceID uuid.UUID, name, envType, description string, isActive bool, userID uuid.UUID) (*models.Environment, error) {
	// Check if user is a member of the workspace
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check for duplicate environment name
	var existingEnv models.Environment
	if err := s.db.Where("workspace_id = ? AND name = ?", workspaceID, name).First(&existingEnv).Error; err == nil {
		return nil, gorm.ErrDuplicatedKey
	}

	// Create new environment record
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

// GetByID retrieves an environment by its ID within a workspace.
// Preloads associated variables and secrets.
func (s *EnvironmentService) GetByID(workspaceID, environmentID uuid.UUID, userID uuid.UUID) (*models.Environment, error) {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Get environment
	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return nil, err
	}

	// Load related variables and secrets
	s.db.Model(&environment).Association("Variables").Find(&environment.Variables)
	s.db.Model(&environment).Association("Secrets").Find(&environment.Secrets)

	return &environment, nil
}

// GetAll retrieves all environments for a workspace.
// Preloads variables and secrets for each environment.
func (s *EnvironmentService) GetAll(workspaceID uuid.UUID, userID uuid.UUID) ([]models.Environment, error) {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	var environments []models.Environment
	if err := s.db.Where("workspace_id = ?", workspaceID).Find(&environments).Error; err != nil {
		return nil, err
	}

	// Load associated variables and secrets
	for i := range environments {
		s.db.Model(&environments[i]).Association("Variables").Find(&environments[i].Variables)
		s.db.Model(&environments[i]).Association("Secrets").Find(&environments[i].Secrets)
	}

	return environments, nil
}

// Update updates an environment's fields based on the provided updates map.
// Updates the "updated_at" timestamp automatically.
func (s *EnvironmentService) Update(workspaceID, environmentID uuid.UUID, userID uuid.UUID, updates map[string]interface{}) (*models.Environment, error) {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Get environment
	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return nil, err
	}

	updates["updated_at"] = time.Now()

	// Apply updates
	if err := s.db.Model(&environment).Updates(updates).Error; err != nil {
		return nil, err
	}

	// Reload associations
	s.db.Model(&environment).Association("Variables").Find(&environment.Variables)
	s.db.Model(&environment).Association("Secrets").Find(&environment.Secrets)

	return &environment, nil
}

// Delete deletes an environment and its associated variables and secrets.
func (s *EnvironmentService) Delete(workspaceID, environmentID uuid.UUID, userID uuid.UUID) error {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return err
	}

	// Get environment
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

// AddVariable adds a variable to an environment, ensuring no duplicate keys.
func (s *EnvironmentService) AddVariable(workspaceID, environmentID uuid.UUID, key, value, varType, description string, userID uuid.UUID) (*models.EnvironmentVariable, error) {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check environment exists
	var environment models.Environment
	if err := s.db.Where("id = ? AND workspace_id = ?", environmentID, workspaceID).First(&environment).Error; err != nil {
		return nil, err
	}

	// Check for duplicate variable key
	var existingVar models.EnvironmentVariable
	if err := s.db.Where("environment_id = ? AND key = ?", environmentID, key).First(&existingVar).Error; err == nil {
		return nil, gorm.ErrDuplicatedKey
	}

	// Create new variable
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

// UpdateVariable updates fields of a variable in an environment.
func (s *EnvironmentService) UpdateVariable(workspaceID, environmentID, variableID uuid.UUID, userID uuid.UUID, updates map[string]interface{}) (*models.EnvironmentVariable, error) {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Get variable
	var variable models.EnvironmentVariable
	if err := s.db.Where("id = ? AND environment_id = ?", variableID, environmentID).First(&variable).Error; err != nil {
		return nil, err
	}

	updates["updated_at"] = time.Now()

	// Apply updates
	if err := s.db.Model(&variable).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &variable, nil
}

// DeleteVariable deletes a variable from an environment.
func (s *EnvironmentService) DeleteVariable(workspaceID, environmentID, variableID uuid.UUID, userID uuid.UUID) error {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return err
	}

	// Get variable
	var variable models.EnvironmentVariable
	if err := s.db.Where("id = ? AND environment_id = ?", variableID, environmentID).First(&variable).Error; err != nil {
		return err
	}

	// Delete variable
	return s.db.Delete(&variable).Error
}

// GetVariables retrieves all variables for a given environment.
func (s *EnvironmentService) GetVariables(workspaceID, environmentID uuid.UUID, userID uuid.UUID) ([]models.EnvironmentVariable, error) {
	// Verify user access
	var workspaceMember models.WorkspaceMember
	if err := s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, userID).First(&workspaceMember).Error; err != nil {
		return nil, err
	}

	// Check environment exists
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
