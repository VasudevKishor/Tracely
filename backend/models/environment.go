package models

import (
    "time"

    "github.com/google/uuid"
    "gorm.io/datatypes"
    "gorm.io/gorm"
)

// Environment represents a set of variables for a workspace
type Environment struct {
    ID          uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
    WorkspaceID uuid.UUID      `gorm:"type:uuid;not null" json:"workspace_id"`
    Name        string         `gorm:"not null" json:"name"`
    Description string         `json:"description"`
    Variables   datatypes.JSON `gorm:"type:jsonb;default:'{}'" json:"variables"`
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`
}
