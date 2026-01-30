package services

import (
	"errors"
	"backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CollectionService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

func NewCollectionService(db *gorm.DB) *CollectionService {
	return &CollectionService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

func (s *CollectionService) Create(workspaceID uuid.UUID, name, description string, userID uuid.UUID) (*models.Collection, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	collection := models.Collection{
		Name:        name,
		Description: description,
		WorkspaceID: workspaceID,
	}

	if err := s.db.Create(&collection).Error; err != nil {
		return nil, err
	}

	return &collection, nil
}

func (s *CollectionService) GetAll(workspaceID, userID uuid.UUID) ([]models.Collection, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	var collections []models.Collection
	err := s.db.Where("workspace_id = ?", workspaceID).Find(&collections).Error
	return collections, err
}

func (s *CollectionService) GetByID(collectionID, userID uuid.UUID) (*models.Collection, error) {
	var collection models.Collection
	if err := s.db.First(&collection, collectionID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(collection.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	return &collection, nil
}

func (s *CollectionService) Update(collectionID, userID uuid.UUID, name, description string) (*models.Collection, error) {
	var collection models.Collection
	if err := s.db.First(&collection, collectionID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(collection.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	collection.Name = name
	collection.Description = description

	if err := s.db.Save(&collection).Error; err != nil {
		return nil, err
	}

	return &collection, nil
}

func (s *CollectionService) Delete(collectionID, userID uuid.UUID) error {
	var collection models.Collection
	if err := s.db.First(&collection, collectionID).Error; err != nil {
		return err
	}

	if !s.workspaceService.HasAccess(collection.WorkspaceID, userID) {
		return errors.New("access denied")
	}

	return s.db.Delete(&collection).Error
}
