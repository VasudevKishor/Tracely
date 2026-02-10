package integrations

import (
	"bytes"
	"encoding/json"
	"net/http"
)

type CICDIntegration struct {
	webhookURL string
}

// NewCICDIntegration creates a new CICDIntegration configured with the provided webhook URL.
func NewCICDIntegration(webhookURL string) *CICDIntegration {
	return &CICDIntegration{webhookURL: webhookURL}
}

// TriggerPipeline triggers a CI/CD pipeline for the specified repository and branch.
// The request is sent as a JSON payload to the configured webhook endpoint.
func (c *CICDIntegration) TriggerPipeline(repoName, branch string, tests []string) error {
	payload := map[string]interface{}{
		"repo":   repoName,
		"branch": branch,
		"tests":  tests,
	}

	data, _ := json.Marshal(payload)
	resp, err := http.Post(c.webhookURL, "application/json", bytes.NewBuffer(data))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}
