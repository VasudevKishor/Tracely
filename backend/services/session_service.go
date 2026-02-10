package services

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Session represents the session state for a workspace
// It stores cookies, tokens, and other variables as a JSON string
type Session struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Name        string    `gorm:"not null"`
	State       string    `gorm:"type:jsonb"` // Cookies, tokens, variables
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// SessionService handles CRUD operations for sessions
type SessionService struct {
	db *gorm.DB
}

// NewSessionService initializes a new SessionService
func NewSessionService(db *gorm.DB) *SessionService {
	return &SessionService{db: db}
}

/*
CaptureSession creates a new session and saves its state (cookies, tokens)
workspaceID: ID of the workspace the session belongs to
name: Name of the session for identification
cookies: Map of cookie name-value pairs
tokens: Map of token name-value pairs
*/
func (s *SessionService) CaptureSession(workspaceID uuid.UUID, name string, cookies map[string]string, tokens map[string]string) (*Session, error) {
	// Construct session state as a map
	state := map[string]interface{}{
		"cookies":     cookies,
		"tokens":      tokens,
		"captured_at": time.Now(),
	}
	// Serialize state to JSON for storage in the database
	stateJSON, _ := json.Marshal(state)
	// Create session object
	session := Session{
		ID:          uuid.New(),
		WorkspaceID: workspaceID,
		Name:        name,
		State:       string(stateJSON),
	}
	// Save session in the database
	if err := s.db.Create(&session).Error; err != nil {
		return nil, err
	}

	return &session, nil
}

// GetSession retrieves a session by its ID and deserializes the state
func (s *SessionService) GetSession(sessionID uuid.UUID) (map[string]interface{}, error) {
	var session Session
	// Fetch session from the database
	if err := s.db.First(&session, sessionID).Error; err != nil {
		return nil, err
	}
	// Deserialize JSON state into a map
	var state map[string]interface{}
	json.Unmarshal([]byte(session.State), &state)

	return state, nil
}

/* ApplySession applies session state (cookies and tokens) to an HTTP request
sessionID: ID of the session to apply
req: HTTP request to which the session should be applied*/

func (s *SessionService) ApplySession(sessionID uuid.UUID, req *http.Request) error {
	// Retrieve session state
	state, err := s.GetSession(sessionID)
	if err != nil {
		return err
	}

	// Apply cookies to the request
	if cookies, ok := state["cookies"].(map[string]interface{}); ok {
		for name, value := range cookies {
			req.AddCookie(&http.Cookie{
				Name:  name,
				Value: value.(string),
			})
		}
	}

	//Apply tokens (e.g., Authorization header)
	if tokens, ok := state["tokens"].(map[string]interface{}); ok {
		if authToken, ok := tokens["auth"].(string); ok {
			req.Header.Set("Authorization", "Bearer "+authToken)
		}
	}

	return nil
}
