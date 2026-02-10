package services

import (
	"errors"
	"backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type GovernanceService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

func NewGovernanceService(db *gorm.DB) *GovernanceService {
	return &GovernanceService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

func (s *GovernanceService) GetPolicies(workspaceID, userID uuid.UUID) ([]models.Policy, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	var policies []models.Policy
	err := s.db.Where("workspace_id = ?", workspaceID).Find(&policies).Error
	return policies, err
}

func (s *GovernanceService) CreatePolicy(workspaceID, userID uuid.UUID, name, description, rules string, enabled bool) (*models.Policy, error) {
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

func (s *GovernanceService) UpdatePolicy(policyID, userID uuid.UUID, updates map[string]interface{}) (*models.Policy, error) {
	var policy models.Policy
	if err := s.db.First(&policy, policyID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.IsAdmin(policy.WorkspaceID, userID) {
		return nil, errors.New("permission denied")
	}

	if err := s.db.Model(&policy).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &policy, nil
}

func (s *GovernanceService) DeletePolicy(policyID, userID uuid.UUID) error {
	var policy models.Policy
	if err := s.db.First(&policy, policyID).Error; err != nil {
		return err
	}

	if !s.workspaceService.IsAdmin(policy.WorkspaceID, userID) {
		return errors.New("permission denied")
	}

	return s.db.Delete(&policy).Error
}
