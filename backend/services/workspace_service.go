package services

import (
	"backend/models"
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// WorkspaceService provides business logic for workspace lifecycle and membership management.
type WorkspaceService struct {
	db *gorm.DB
}

// NewWorkspaceService creates a new instance of WorkspaceService with a database connection.
func NewWorkspaceService(db *gorm.DB) *WorkspaceService {
	return &WorkspaceService{db: db}
}

// Create initializes a new workspace and assigns the creator as the owner and an admin.
func (s *WorkspaceService) Create(name, description string, ownerID uuid.UUID) (*models.Workspace, error) {
	workspace := models.Workspace{
		Name:        name,
		Description: description,
		OwnerID:     ownerID,
	}

	if err := s.db.Create(&workspace).Error; err != nil {
		return nil, err
	}

	// Add owner as admin member
	member := models.WorkspaceMember{
		WorkspaceID: workspace.ID,
		UserID:      ownerID,
		Role:        "admin",
	}
	if err := s.db.Create(&member).Error; err != nil {
		return nil, err
	}
	if err := s.db.
		Preload("Owner").
		Preload("Members").
		Preload("Members.User").
		First(&workspace, workspace.ID).Error; err != nil {
		return nil, err
	}

	return &workspace, nil
}

// GetAll returns all workspaces where the given user is a member.
func (s *WorkspaceService) GetAll(userID uuid.UUID) ([]models.Workspace, error) {
	var workspaces []models.Workspace

	// Get workspaces where user is a member
	err := s.db.
		Joins("JOIN workspace_members ON workspace_members.workspace_id = workspaces.id").
		Where("workspace_members.user_id = ?", userID).
		Preload("Owner").
		Preload("Members").
		Preload("Members.User").
		Find(&workspaces).Error

	return workspaces, err
}

// GetByID retrieves a workspace by ID, ensuring the user has access.
func (s *WorkspaceService) GetByID(workspaceID, userID uuid.UUID) (*models.Workspace, error) {
	var workspace models.Workspace
	if err := s.db.First(&workspace, workspaceID).Error; err != nil {
		return nil, err // gorm.ErrRecordNotFound → 404
	}
	// Check if user has access to workspace
	if !s.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	err := s.db.
		Preload("Owner").
		Preload("Members").
		Preload("Members.User").
		First(&workspace, workspaceID).Error

	if err != nil {
		return nil, err
	}

	return &workspace, nil
}

// Update modifies workspace details if the user has administrative privileges.
func (s *WorkspaceService) Update(workspaceID, userID uuid.UUID, name, description string) (*models.Workspace, error) {
	var workspace models.Workspace

	// Check if user is admin
	if !s.IsAdmin(workspaceID, userID) {
		return nil, errors.New("permission denied")
	}

	if err := s.db.First(&workspace, workspaceID).Error; err != nil {
		return nil, err
	}

	workspace.Name = name
	workspace.Description = description

	if err := s.db.Save(&workspace).Error; err != nil {
		return nil, err
	}

	return &workspace, nil
}

// Delete removes a workspace from the system, restricted to the workspace owner.
func (s *WorkspaceService) Delete(workspaceID, userID uuid.UUID) error {
	// Check if user is owner
	var workspace models.Workspace
	if err := s.db.First(&workspace, workspaceID).Error; err != nil {
		return err
	}

	if workspace.OwnerID != userID {
		return errors.New("only owner can delete workspace")
	}

	return s.db.Delete(&workspace).Error
}

// HasAccess checks if a user is a member of the specified workspace.
func (s *WorkspaceService) HasAccess(workspaceID, userID uuid.UUID) bool {
	var count int64
	s.db.Model(&models.WorkspaceMember{}).
		Where("workspace_id = ? AND user_id = ?", workspaceID, userID).
		Count(&count)
	return count > 0
}

// IsAdmin checks if a user has an administrative role within a workspace.
func (s *WorkspaceService) IsAdmin(workspaceID, userID uuid.UUID) bool {
	var count int64
	s.db.Model(&models.WorkspaceMember{}).
		Where("workspace_id = ? AND user_id = ? AND role = ?", workspaceID, userID, "admin").
		Count(&count)
	return count > 0
}

func (s *WorkspaceService) AddMember(workspaceID, userID, memberUserID uuid.UUID, role string) error {
	if !s.IsAdmin(workspaceID, userID) {
		return errors.New("permission denied")
	}

	member := models.WorkspaceMember{
		WorkspaceID: workspaceID,
		UserID:      memberUserID,
		Role:        role,
	}

	return s.db.Create(&member).Error
}

func (s *WorkspaceService) RemoveMember(workspaceID, userID, memberUserID uuid.UUID) error {
	if !s.IsAdmin(workspaceID, userID) {
		return errors.New("permission denied")
	}

	return s.db.Where("workspace_id = ? AND user_id = ?", workspaceID, memberUserID).
		Delete(&models.WorkspaceMember{}).Error
}
