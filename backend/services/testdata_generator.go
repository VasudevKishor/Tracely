/*
Package services provides utility functions for generating test data
from JSON schemas or realistic patterns.
*/
package services

import (
	"encoding/json"
	"math/rand"
	"time"

	"github.com/brianvoe/gofakeit/v6"
)

// TestDataGenerator is responsible for generating test data from JSON schemas
// or generating realistic mock data for common entities like users, products, and orders.
type TestDataGenerator struct{}

// NewTestDataGenerator creates a new TestDataGenerator instance
// and seeds the random generator for gofakeit.
func NewTestDataGenerator() *TestDataGenerator {
	gofakeit.Seed(time.Now().UnixNano())
	return &TestDataGenerator{}
}

/*
GenerateFromSchema generates test data based on a JSON schema.
Parameters:
- schemaJSON: JSON schema as a string.
Returns:
- Generated JSON data as string.
- Error if the schema parsing or generation fails.
*/
func (g *TestDataGenerator) GenerateFromSchema(schemaJSON string) (string, error) {
	var schema map[string]interface{}
	if err := json.Unmarshal([]byte(schemaJSON), &schema); err != nil {
		return "", err
	}

	data := g.generateFromSchemaObject(schema)
	result, _ := json.Marshal(data)
	return string(result), nil
}

// generateFromSchemaObject generates data based on a parsed JSON schema object.
func (g *TestDataGenerator) generateFromSchemaObject(schema map[string]interface{}) interface{} {
	//Figure out what type this schema wants (object, array, string, etc.).
	schemaType, ok := schema["type"].(string)
	if !ok {
		return nil
	}

	switch schemaType {
	case "object":
		return g.generateObject(schema)
	case "array":
		return g.generateArray(schema)
	case "string":
		return g.generateString(schema)
	case "integer":
		return g.generateInteger(schema)
	case "number":
		return g.generateNumber(schema)
	case "boolean":
		return g.generateBoolean()
	default:
		return nil
	}
}

// generateObject generates a map object based on "properties" in the schema.
func (g *TestDataGenerator) generateObject(schema map[string]interface{}) map[string]interface{} {
	obj := make(map[string]interface{})

	if props, ok := schema["properties"].(map[string]interface{}); ok {
		for key, propSchema := range props {
			if ps, ok := propSchema.(map[string]interface{}); ok {
				obj[key] = g.generateFromSchemaObject(ps)
			}
		}
	}

	return obj
}

// generateArray generates an array of items based on "items" in the schema,
// using minItems and maxItems if specified.
func (g *TestDataGenerator) generateArray(schema map[string]interface{}) []interface{} {
	minItems := 1
	maxItems := 5

	if min, ok := schema["minItems"].(float64); ok {
		minItems = int(min)
	}
	if max, ok := schema["maxItems"].(float64); ok {
		maxItems = int(max)
	}

	count := minItems + rand.Intn(maxItems-minItems+1)
	arr := make([]interface{}, count)

	if items, ok := schema["items"].(map[string]interface{}); ok {
		for i := 0; i < count; i++ {
			arr[i] = g.generateFromSchemaObject(items)
		}
	}

	return arr
}

// generateString generates a string based on schema constraints.
// Supports formats (email, date, UUID, URI, IPv4), enum values, or min/max lengths.
func (g *TestDataGenerator) generateString(schema map[string]interface{}) string {
	// 1. Check for specific formats (email, date, etc.)
	if format, ok := schema["format"].(string); ok {
		switch format {
		case "email":
			return gofakeit.Email()
		case "date":
			return gofakeit.Date().Format("2006-01-02")
		case "date-time":
			return gofakeit.Date().Format(time.RFC3339)
		case "uuid":
			return gofakeit.UUID()
		case "uri":
			return gofakeit.URL()
		case "ipv4":
			return gofakeit.IPv4Address()
		}
	}

	// 2. Check for enum values
	if enum, ok := schema["enum"].([]interface{}); ok && len(enum) > 0 {
		return enum[rand.Intn(len(enum))].(string)
	}

	// 3. Default random string logic
	minLength := 5
	maxLength := 20
	if min, ok := schema["minLength"].(float64); ok {
		minLength = int(min)
	}
	if max, ok := schema["maxLength"].(float64); ok {
		maxLength = int(max)
	}

	// --- ADD THE SAFETY CHECK HERE ---
	if minLength > maxLength {
		minLength, maxLength = maxLength, minLength // Swap to prevent rand.Intn panic
	}

	count := uint(minLength)
	if maxLength > minLength {
		// rand.Intn(n) requires n > 0. (maxLength - minLength + 1) is now safe.
		count = uint(minLength + rand.Intn(maxLength-minLength+1))
	}

	return gofakeit.LetterN(count)
}

// generateInteger generates a random integer within min/max constraints if specified.
func (g *TestDataGenerator) generateInteger(schema map[string]interface{}) int {
	min := 0
	max := 100

	if minimum, ok := schema["minimum"].(float64); ok {
		min = int(minimum)
	}
	if maximum, ok := schema["maximum"].(float64); ok {
		max = int(maximum)
	}

	return min + rand.Intn(max-min+1)
}

// generateNumber generates a random float number within min/max constraints.
func (g *TestDataGenerator) generateNumber(schema map[string]interface{}) float64 {
	min := 0.0
	max := 100.0

	if minimum, ok := schema["minimum"].(float64); ok {
		min = minimum
	}
	if maximum, ok := schema["maximum"].(float64); ok {
		max = maximum
	}

	return min + rand.Float64()*(max-min)
}

// generateBoolean generates a random boolean value.
func (g *TestDataGenerator) generateBoolean() bool {
	return rand.Float64() > 0.5
}

// GenerateRealisticData generates realistic mock data for common entities:
// - user: id, name, email, phone, address, created_at
// - product: id, name, price, description, category
// - order: id, customer_id, total, status, created_at
func (g *TestDataGenerator) GenerateRealisticData(dataType string) interface{} {
	switch dataType {
	case "user":
		return map[string]interface{}{
			"id":         gofakeit.UUID(),
			"name":       gofakeit.Name(),
			"email":      gofakeit.Email(),
			"phone":      gofakeit.Phone(),
			"address":    gofakeit.Address().Address,
			"created_at": gofakeit.Date(),
		}
	case "product":
		return map[string]interface{}{
			"id":          gofakeit.UUID(),
			"name":        gofakeit.ProductName(),
			"price":       gofakeit.Price(10, 1000),
			"description": gofakeit.ProductDescription(),
			"category":    gofakeit.ProductCategory(),
		}
	case "order":
		return map[string]interface{}{
			"id":          gofakeit.UUID(),
			"customer_id": gofakeit.UUID(),
			"total":       gofakeit.Price(50, 5000),
			"status":      gofakeit.RandomString([]string{"pending", "processing", "shipped", "delivered"}),
			"created_at":  gofakeit.Date(),
		}
	default:
		return nil
	}
}
