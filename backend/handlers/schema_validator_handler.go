package handlers

import (
	"backend/middlewares"
	"backend/services"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
)

type SchemaValidatorHandler struct {
	schemaValidatorService *services.SchemaValidator
}

func NewSchemaValidatorHandler(s *services.SchemaValidator) *SchemaValidatorHandler {
	return &SchemaValidatorHandler{schemaValidatorService: s}
}

// We use json.RawMessage to delay unmarshaling and keep data as raw bytes
type ValidateSchemaRequest struct {
	Data   json.RawMessage `json:"data" binding:"required"`
	Schema json.RawMessage `json:"schema" binding:"required"`
}

func (h *SchemaValidatorHandler) ValidateSchema(c *gin.Context) {
	_, _ = middlewares.GetUserID(c)

	var req ValidateSchemaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Your service: ValidateAgainstOpenAPI(responseBody string, schemaJSON string)
	// We convert the raw messages to strings to match your service signature.
	result, err := h.schemaValidatorService.ValidateAgainstOpenAPI(
		string(req.Data),
		string(req.Schema),
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Validation process failed: " + err.Error()})
		return
	}

	// Returning the full result object which contains 'valid' and 'errors'
	c.JSON(http.StatusOK, result)
}
