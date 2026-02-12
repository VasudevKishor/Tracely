package handlers

import (
	"backend/services"
	"encoding/json"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// TestDataGeneratorHandler handles HTTP requests for generating mock data.
type TestDataGeneratorHandler struct {
	generatorService *services.TestDataGenerator
}

// NewTestDataGeneratorHandler creates a new instance of the handler.
func NewTestDataGeneratorHandler(s *services.TestDataGenerator) *TestDataGeneratorHandler {
	return &TestDataGeneratorHandler{generatorService: s}
}

// GenerateFromSchemaRequest defines the input for schema-based generation.
type GenerateFromSchemaRequest struct {
	// We use json.RawMessage to accept a JSON object directly from the client
	Schema json.RawMessage `json:"schema" binding:"required"`
}

// GenerateFromSchema handles the POST request to generate data based on a JSON schema.
func (h *TestDataGeneratorHandler) GenerateFromSchema(c *gin.Context) {
	workspaceID := c.Param("workspace_id") // Extract the ID from the URL

	var req GenerateFromSchemaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid schema format: " + err.Error()})
		return
	}

	log.Printf("Generating data for workspace: %s", workspaceID)

	generatedJSON, err := h.generatorService.GenerateFromSchema(string(req.Schema))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Generation failed: " + err.Error()})
		return
	}

	// We unmarshal the string back to an interface so Gin can send it as a proper JSON object,
	// rather than a string with escaped quotes.
	var response interface{}
	json.Unmarshal([]byte(generatedJSON), &response)

	c.JSON(http.StatusOK, gin.H{
		"data": response,
	})
}

// GenerateRealisticData handles the GET request to generate common entities.
// Example: /generate/realistic/user
func (h *TestDataGeneratorHandler) GenerateRealisticData(c *gin.Context) {
	dataType := c.Param("type") // e.g., "user", "product", "order"

	data := h.generatorService.GenerateRealisticData(dataType)
	if data == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Unsupported data type: " + dataType})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"type": dataType,
		"data": data,
	})
}
