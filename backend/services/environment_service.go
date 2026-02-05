package services

import (
    "encoding/json"

    "backend/models"

    "github.com/google/uuid"
    "gorm.io/gorm"
)

type EnvironmentService struct {
    db *gorm.DB
}

func NewEnvironmentService(db *gorm.DB) *EnvironmentService {
    return &EnvironmentService{db: db}
}

func (s *EnvironmentService) Create(workspaceID uuid.UUID, name, description string, variables map[string]interface{}) (*models.Environment, error) {
    varsJSON, _ := json.Marshal(variables)
    env := models.Environment{
        ID:          uuid.New(),
        WorkspaceID: workspaceID,
        Name:        name,
        Description: description,
        Variables:   varsJSON,
    }
    if err := s.db.Create(&env).Error; err != nil {
        return nil, err
    }
    return &env, nil
}

func (s *EnvironmentService) GetByID(id uuid.UUID) (*models.Environment, error) {
    var env models.Environment
    if err := s.db.First(&env, id).Error; err != nil {
        return nil, err
    }
    return &env, nil
}

func (s *EnvironmentService) Update(id uuid.UUID, name, description string, variables map[string]interface{}) (*models.Environment, error) {
    env, err := s.GetByID(id)
    if err != nil {
        return nil, err
    }
    if name != "" {
        env.Name = name
    }
    if description != "" {
        env.Description = description
    }
    if variables != nil {
        b, _ := json.Marshal(variables)
        env.Variables = b
    }
    if err := s.db.Save(env).Error; err != nil {
        return nil, err
    }
    return env, nil
}

func (s *EnvironmentService) Delete(id uuid.UUID) error {
    return s.db.Delete(&models.Environment{}, id).Error
}

func (s *EnvironmentService) ListByWorkspace(workspaceID uuid.UUID) ([]models.Environment, error) {
    var envs []models.Environment
    if err := s.db.Where("workspace_id = ?", workspaceID).Find(&envs).Error; err != nil {
        return nil, err
    }
    return envs, nil
}

func (s *EnvironmentService) ParseVariables(env *models.Environment) (map[string]interface{}, error) {
    var m map[string]interface{}
    if env == nil {
        return map[string]interface{}{}, nil
    }
    if err := json.Unmarshal(env.Variables, &m); err != nil {
        return nil, err
    }
    return m, nil
}
