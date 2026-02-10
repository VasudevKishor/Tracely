package services

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestTestDataGenerator_GenerateFromSchema(t *testing.T) {
	generator := NewTestDataGenerator()

	t.Run("Generate Simple Object", func(t *testing.T) {
		schema := `{
			"type": "object",
			"properties": {
				"name": {"type": "string"},
				"age": {"type": "integer", "minimum": 18, "maximum": 60},
				"email": {"type": "string", "format": "email"}
			}
		}`

		jsonStr, err := generator.GenerateFromSchema(schema)
		assert.NoError(t, err)

		var result map[string]interface{}
		err = json.Unmarshal([]byte(jsonStr), &result)
		assert.NoError(t, err)

		// Assertions
		assert.IsType(t, "", result["name"])
		assert.True(t, result["age"].(float64) >= 18 && result["age"].(float64) <= 60)
		assert.Contains(t, result["email"].(string), "@")
	})

	t.Run("Generate Array with Constraints", func(t *testing.T) {
		schema := `{
			"type": "array",
			"minItems": 3,
			"maxItems": 3,
			"items": {
				"type": "string",
				"format": "uuid"
			}
		}`

		jsonStr, err := generator.GenerateFromSchema(schema)
		assert.NoError(t, err)

		var result []string
		err = json.Unmarshal([]byte(jsonStr), &result)
		assert.NoError(t, err)

		assert.Len(t, result, 3)
		_, err = uuid.Parse(result[0])
		assert.NoError(t, err, "Should be a valid UUID")
	})

	t.Run("Invalid Schema JSON", func(t *testing.T) {
		_, err := generator.GenerateFromSchema(`{ invalid json }`)
		assert.Error(t, err)
	})
}

func TestTestDataGenerator_GenerateRealisticData(t *testing.T) {
	generator := NewTestDataGenerator()

	t.Run("Generate Realistic User", func(t *testing.T) {
		data := generator.GenerateRealisticData("user")
		user, ok := data.(map[string]interface{})

		assert.True(t, ok)
		assert.NotEmpty(t, user["name"])
		assert.Contains(t, user["email"].(string), "@")
		assert.NotEmpty(t, user["address"])
	})

	t.Run("Generate Realistic Product", func(t *testing.T) {
		data := generator.GenerateRealisticData("product")
		product := data.(map[string]interface{})

		assert.NotEmpty(t, product["name"])
		assert.Greater(t, product["price"].(float64), 0.0)
	})

	t.Run("Unknown DataType", func(t *testing.T) {
		data := generator.GenerateRealisticData("spaceship")
		assert.Nil(t, data)
	})
}

func TestTestDataGenerator_EnumSupport(t *testing.T) {
	generator := NewTestDataGenerator()

	schema := `{
		"type": "string",
		"enum": ["Red", "Green", "Blue"]
	}`

	jsonStr, err := generator.GenerateFromSchema(schema)
	assert.NoError(t, err)

	val := strings.Trim(jsonStr, "\"")
	assert.Contains(t, []string{"Red", "Green", "Blue"}, val)
}
