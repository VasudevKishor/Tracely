package services

import (
	"backend/models"
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// GovernanceService handles the business logic for workspace policies and compliance.
type GovernanceService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

// NewGovernanceService creates a new instance of GovernanceService.
func NewGovernanceService(db *gorm.DB) *GovernanceService {
	return &GovernanceService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

// GetPolicies retrieves all policies for a given workspace, checking user access first.
func (s *GovernanceService) GetPolicies(workspaceID, userID uuid.UUID) ([]models.Policy, error) {
	// Verify the user has access to the workspace
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	var policies []models.Policy
	err := s.db.Where("workspace_id = ?", workspaceID).Find(&policies).Error
	return policies, err
}

// CreatePolicy adds a new policy to the workspace if the user has admin permissions.
func (s *GovernanceService) CreatePolicy(workspaceID, userID uuid.UUID, name, description, rules string, enabled bool) (*models.Policy, error) {
	// Only administrators can create new policies
	if !s.workspaceService.IsAdmin(workspaceID, userID) {
		return nil, errors.New("permission denied")
	}

	policy := models.Policy{
		WorkspaceID: workspaceID,
		Name:        name,
		Description: description,
		Rules:       rules,
		Enabled:     enabled,
	}

	if err := s.db.Create(&policy).Error; err != nil {
		return nil, err
	}

	return &policy, nil
}

// UpdatePolicy modifies an existing policy after verifying admin permissions.
func (s *GovernanceService) UpdatePolicy(policyID, userID uuid.UUID, updates map[string]interface{}) (*models.Policy, error) {
	var policy models.Policy
	// Fetch the existing policy to identify its workspace
	if err := s.db.First(&policy, policyID).Error; err != nil {
		return nil, err
	}

	// Verify the user is an admin of the workspace where the policy resides
	if !s.workspaceService.IsAdmin(policy.WorkspaceID, userID) {
		return nil, errors.New("permission denied")
	}

	if err := s.db.Model(&policy).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &policy, nil
}

// DeletePolicy removes a policy from the database after verifying admin permissions.
func (s *GovernanceService) DeletePolicy(policyID, userID uuid.UUID) error {
	var policy models.Policy
	// Fetch the policy to verify existence and check workspace ownership
	if err := s.db.First(&policy, policyID).Error; err != nil {
		return err
	}

	// Verify the user has administrative rights in the policy's workspace
	if !s.workspaceService.IsAdmin(policy.WorkspaceID, userID) {
		return errors.New("permission denied")
	}

	return s.db.Delete(&policy).Error
}
