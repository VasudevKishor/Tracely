package services

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestMutationService_ApplyMutations_Replace(t *testing.T) {
	service := NewMutationService()

	url := "http://api.staging.com/v1/users"
	body := `{"env": "staging"}`
	headers := map[string]string{"X-Env": "staging"}

	rules := []MutationRule{
		{
			Type:    "replace",
			Target:  "url",
			Find:    "staging",
			Replace: "production",
		},
		{
			Type:    "replace",
			Target:  "body",
			Find:    "staging",
			Replace: "production",
		},
		{
			Type:    "replace",
			Target:  "header",
			Find:    "staging",
			Replace: "production",
		},
	}

	mutatedURL, mutatedBody, mutatedHeaders, err := service.ApplyMutations(url, body, headers, rules, nil)

	assert.NoError(t, err)
	assert.Equal(t, "http://api.production.com/v1/users", mutatedURL)
	assert.Equal(t, `{"env": "production"}`, mutatedBody)
	assert.Equal(t, "production", mutatedHeaders["X-Env"])
}

func TestMutationService_ApplyMutations_Regex(t *testing.T) {
	service := NewMutationService()

	url := "http://api.com/order/12345"
	rules := []MutationRule{
		{
			Type:    "regex",
			Target:  "url",
			Find:    `order/\d+`,
			Replace: "order/REDACTED",
		},
	}

	mutatedURL, _, _, err := service.ApplyMutations(url, "", nil, rules, nil)

	assert.NoError(t, err)
	assert.Equal(t, "http://api.com/order/REDACTED", mutatedURL)
}

func TestMutationService_ApplyMutations_Template(t *testing.T) {
	service := NewMutationService()

	url := "http://{{host}}/{{path}}"
	body := `{"user_id": "{{user_id}}"}`

	// Variables provided at runtime
	variables := map[string]string{
		"host":    "localhost:8081",
		"user_id": "999",
	}

	// Variables baked into the rule
	rules := []MutationRule{
		{
			Type: "template",
			Variables: map[string]string{
				"path": "v2/login",
			},
		},
	}

	mutatedURL, mutatedBody, _, err := service.ApplyMutations(url, body, nil, rules, variables)

	assert.NoError(t, err)
	assert.Equal(t, "http://localhost:8081/v2/login", mutatedURL)
	assert.Equal(t, `{"user_id": "999"}`, mutatedBody)
}
