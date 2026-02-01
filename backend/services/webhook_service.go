package services

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Webhook struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Name        string    `gorm:"not null"`
	URL         string    `gorm:"not null"`
	Secret      string    // For signature validation
	Events      string    `gorm:"type:jsonb"` // Which events trigger this webhook
	Enabled     bool      `gorm:"default:true"`
	CreatedAt   time.Time
}

type WebhookEvent struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	WebhookID   uuid.UUID `gorm:"type:uuid;not null"`
	EventType   string    `gorm:"not null"`
	Payload     string    `gorm:"type:jsonb"`
	Status      string    `gorm:"default:'pending'"` // pending, sent, failed
	Attempts    int       `gorm:"default:0"`
	LastAttempt *time.Time
	Response    string
	CreatedAt   time.Time
}

type WebhookService struct {
	db *gorm.DB
}

func NewWebhookService(db *gorm.DB) *WebhookService {
	return &WebhookService{db: db}
}

// CreateWebhook creates a new webhook
func (s *WebhookService) CreateWebhook(workspaceID uuid.UUID, name, url, secret string, events []string) (*Webhook, error) {
	eventsJSON, _ := json.Marshal(events)

	webhook := Webhook{
		ID:          uuid.New(),
		WorkspaceID: workspaceID,
		Name:        name,
		URL:         url,
		Secret:      secret,
		Events:      string(eventsJSON),
		Enabled:     true,
	}

	if err := s.db.Create(&webhook).Error; err != nil {
		return nil, err
	}

	return &webhook, nil
}

// TriggerWebhook triggers webhooks for an event
func (s *WebhookService) TriggerWebhook(workspaceID uuid.UUID, eventType string, payload map[string]interface{}) error {
	var webhooks []Webhook
	s.db.Where("workspace_id = ? AND enabled = true", workspaceID).Find(&webhooks)

	for _, webhook := range webhooks {
		// Check if webhook subscribes to this event
		var events []string
		json.Unmarshal([]byte(webhook.Events), &events)

		subscribed := false
		for _, e := range events {
			if e == eventType || e == "*" {
				subscribed = true
				break
			}
		}

		if !subscribed {
			continue
		}

		// Create webhook event
		payloadJSON, _ := json.Marshal(payload)
		event := WebhookEvent{
			ID:        uuid.New(),
			WebhookID: webhook.ID,
			EventType: eventType,
			Payload:   string(payloadJSON),
			Status:    "pending",
		}

		s.db.Create(&event)

		// Send webhook async
		go s.sendWebhook(&webhook, &event)
	}

	return nil
}

func (s *WebhookService) sendWebhook(webhook *Webhook, event *WebhookEvent) {
	// Implementation would send HTTP POST to webhook.URL with event.Payload
	// For now, just mark as sent
	now := time.Now()
	s.db.Model(event).Updates(map[string]interface{}{
		"status":       "sent",
		"attempts":     event.Attempts + 1,
		"last_attempt": now,
	})
}
