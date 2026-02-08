package integrations

import (
	"bytes"
	"encoding/json"
	"net/http"
)

type CICDIntegration struct {
	webhookURL string
}

func NewCICDIntegration(webhookURL string) *CICDIntegration {
	return &CICDIntegration{webhookURL: webhookURL}
}

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
