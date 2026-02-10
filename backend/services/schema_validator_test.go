package services

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSchemaValidator_ValidateAgainstOpenAPI_Valid(t *testing.T) {
	validator := NewSchemaValidator()

	schema := `{
		"type": "object",
		"properties": {
			"id": {"type": "integer"},
			"name": {"type": "string"}
		},
		"required": ["id", "name"]
	}`

	document := `{"id": 1, "name": "John Doe"}`

	result, err := validator.ValidateAgainstOpenAPI(document, schema)

	assert.NoError(t, err)
	assert.True(t, result.Valid)
	assert.Empty(t, result.Errors)
}

func TestSchemaValidator_ValidateAgainstOpenAPI_Invalid(t *testing.T) {
	validator := NewSchemaValidator()

	schema := `{
		"type": "object",
		"properties": {
			"age": {"type": "integer", "minimum": 18}
		}
	}`

	// Invalid: age is a string and less than 18
	document := `{"age": "seventeen"}`

	result, err := validator.ValidateAgainstOpenAPI(document, schema)

	assert.NoError(t, err)
	assert.False(t, result.Valid)
	assert.NotEmpty(t, result.Errors)

	// Check if the specific error is captured
	assert.Equal(t, "age", result.Errors[0].Field)
	assert.Equal(t, "invalid_type", result.Errors[0].Type)
}

func TestSchemaValidator_ValidateContract(t *testing.T) {
	validator := NewSchemaValidator()

	contract := Contract{
		RequestSchema: `{
			"type": "object",
			"properties": { "query": { "type": "string" } }
		}`,
		ResponseSchema: `{
			"type": "object",
			"properties": { "status": { "type": "string" } }
		}`,
	}

	t.Run("Full Valid Contract", func(t *testing.T) {
		req := `{"query": "test"}`
		resp := `{"status": "ok"}`
		result, err := validator.ValidateContract(req, resp, contract)
		assert.NoError(t, err)
		assert.True(t, result.Valid)
	})

	t.Run("Invalid Response in Contract", func(t *testing.T) {
		req := `{"query": "test"}`
		resp := `{"status": 123}` // Should be string
		result, err := validator.ValidateContract(req, resp, contract)
		assert.NoError(t, err)
		assert.False(t, result.Valid)
		assert.Equal(t, "status", result.Errors[0].Field)
	})
}
