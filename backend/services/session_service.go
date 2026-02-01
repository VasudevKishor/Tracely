package services

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Session struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Name        string    `gorm:"not null"`
	State       string    `gorm:"type:jsonb"` // Cookies, tokens, variables
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type SessionService struct {
	db *gorm.DB
}

func NewSessionService(db *gorm.DB) *SessionService {
	return &SessionService{db: db}
}

// CaptureSession captures session state from execution
func (s *SessionService) CaptureSession(workspaceID uuid.UUID, name string, cookies map[string]string, tokens map[string]string) (*Session, error) {
	state := map[string]interface{}{
		"cookies":     cookies,
		"tokens":      tokens,
		"captured_at": time.Now(),
	}

	stateJSON, _ := json.Marshal(state)

	session := Session{
		ID:          uuid.New(),
		WorkspaceID: workspaceID,
		Name:        name,
		State:       string(stateJSON),
	}

	if err := s.db.Create(&session).Error; err != nil {
		return nil, err
	}

	return &session, nil
}

// GetSession retrieves session state
func (s *SessionService) GetSession(sessionID uuid.UUID) (map[string]interface{}, error) {
	var session Session
	if err := s.db.First(&session, sessionID).Error; err != nil {
		return nil, err
	}

	var state map[string]interface{}
	json.Unmarshal([]byte(session.State), &state)

	return state, nil
}

// ApplySession applies session state to request
func (s *SessionService) ApplySession(sessionID uuid.UUID, req *http.Request) error {
	state, err := s.GetSession(sessionID)
	if err != nil {
		return err
	}

	// Apply cookies
	if cookies, ok := state["cookies"].(map[string]interface{}); ok {
		for name, value := range cookies {
			req.AddCookie(&http.Cookie{
				Name:  name,
				Value: value.(string),
			})
		}
	}

	// Apply tokens
	if tokens, ok := state["tokens"].(map[string]interface{}); ok {
		if authToken, ok := tokens["auth"].(string); ok {
			req.Header.Set("Authorization", "Bearer "+authToken)
		}
	}

	return nil
}
