package integrations

import (
	"bytes"
	"encoding/json"
	"net/http"
)

type PagerDutyIntegration struct {
	integrationKey string
	client         *http.Client
}

func NewPagerDutyIntegration(integrationKey string) *PagerDutyIntegration {
	return &PagerDutyIntegration{
		integrationKey: integrationKey,
		client:         &http.Client{},
	}
}

// TriggerIncident creates a new incident in PagerDuty.
// It sends a "trigger" event with the provided summary, severity level and source identifier
func (p *PagerDutyIntegration) TriggerIncident(summary, severity, source string) error {
	payload := map[string]interface{}{
		"routing_key":  p.integrationKey,
		"event_action": "trigger",
		"payload": map[string]interface{}{
			"summary":  summary,
			"severity": severity,
			"source":   source,
		},
	}

	data, _ := json.Marshal(payload)
	resp, err := p.client.Post(
		"https://events.pagerduty.com/v2/enqueue",
		"application/json",
		bytes.NewBuffer(data),
	)

	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// ResolveIncident resolves an existing PagerDuty incident.
// It sends a "resolve" event associated with the given deduplication key,
// which PagerDuty uses to identify and close the previously triggered incident
// linked to the same integration and event stream.
func (p *PagerDutyIntegration) ResolveIncident(dedupKey string) error {
	payload := map[string]interface{}{
		"routing_key":  p.integrationKey,
		"event_action": "resolve",
		"dedup_key":    dedupKey,
	}

	data, _ := json.Marshal(payload)
	resp, err := p.client.Post(
		"https://events.pagerduty.com/v2/enqueue",
		"application/json",
		bytes.NewBuffer(data),
	)

	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}
