package integrations

import (
	"bytes"
	"encoding/json"
	"net/http"
)

// SlackIntegration struct handles sending messages to Slack using webhooks.
type SlackIntegration struct {
	webhookURL string
}

// NewSlackIntegration creates a new SlackIntegration instance.
func NewSlackIntegration(webhookURL string) *SlackIntegration {
	return &SlackIntegration{webhookURL: webhookURL}
}

// SendMessage sends a message to using configured webhook URL.
// It constructs a JSON payload and does a HTTP POST request to Slack.
func (s *SlackIntegration) SendMessage(message string) error {
	payload := map[string]interface{}{
		"text": message,
	}

	data, _ := json.Marshal(payload)
	resp, err := http.Post(s.webhookURL, "application/json", bytes.NewBuffer(data))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// SendAlert sends a formatted alert message to Slack with a severity indicator.
// The severity determines the color of the Slack attachment.
func (s *SlackIntegration) SendAlert(title, message, severity string) error {
	color := "good"
	if severity == "critical" {
		color = "danger"
	} else if severity == "warning" {
		color = "warning"
	}

	payload := map[string]interface{}{
		"attachments": []map[string]interface{}{
			{
				"color": color,
				"title": title,
				"text":  message,
				"fields": []map[string]interface{}{
					{
						"title": "Severity",
						"value": severity,
						"short": true,
					},
				},
			},
		},
	}

	data, _ := json.Marshal(payload)
	resp, err := http.Post(s.webhookURL, "application/json", bytes.NewBuffer(data))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}
