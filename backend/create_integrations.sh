#!/bin/bash

# CI/CD Integration
cat > integrations/cicd_integration.go << 'EOF'
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
EOF

# Postman Importer
cat > integrations/postman_importer.go << 'EOF'
package integrations

import (
	"encoding/json"
	"io/ioutil"
)

type PostmanCollection struct {
	Info struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	} `json:"info"`
	Item []PostmanItem `json:"item"`
}

type PostmanItem struct {
	Name    string         `json:"name"`
	Request PostmanRequest `json:"request"`
}

type PostmanRequest struct {
	Method string `json:"method"`
	URL    struct {
		Raw string `json:"raw"`
	} `json:"url"`
	Header []struct {
		Key   string `json:"key"`
		Value string `json:"value"`
	} `json:"header"`
	Body struct {
		Mode string `json:"mode"`
		Raw  string `json:"raw"`
	} `json:"body"`
}

type PostmanImporter struct{}

func NewPostmanImporter() *PostmanImporter {
	return &PostmanImporter{}
}

func (p *PostmanImporter) ImportFromFile(filepath string) (*PostmanCollection, error) {
	data, err := ioutil.ReadFile(filepath)
	if err != nil {
		return nil, err
	}

	var collection PostmanCollection
	if err := json.Unmarshal(data, &collection); err != nil {
		return nil, err
	}

	return &collection, nil
}

func (p *PostmanImporter) ConvertToRequests(collection *PostmanCollection) []map[string]interface{} {
	requests := []map[string]interface{}{}

	for _, item := range collection.Item {
		headers := make(map[string]string)
		for _, h := range item.Request.Header {
			headers[h.Key] = h.Value
		}

		request := map[string]interface{}{
			"name":    item.Name,
			"method":  item.Request.Method,
			"url":     item.Request.URL.Raw,
			"headers": headers,
			"body":    item.Request.Body.Raw,
		}

		requests = append(requests, request)
	}

	return requests
}
EOF

# Slack Integration
cat > integrations/slack_integration.go << 'EOF'
package integrations

import (
	"bytes"
	"encoding/json"
	"net/http"
)

type SlackIntegration struct {
	webhookURL string
}

func NewSlackIntegration(webhookURL string) *SlackIntegration {
	return &SlackIntegration{webhookURL: webhookURL}
}

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
				"color":  color,
				"title":  title,
				"text":   message,
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
EOF

echo "Integrations created!"
