/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the PercentileCalculatorHandler.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

type PercentileCalculatorHandler struct {
	// Note: Ensure the field name matches your initialization logic
	percentileCalculatorService *services.PercentileCalculator
}

func NewPercentileCalculatorHandler(s *services.PercentileCalculator) *PercentileCalculatorHandler {
	return &PercentileCalculatorHandler{percentileCalculatorService: s}
}

type CalculatePercentilesRequest struct {
	// We receive float64 from JSON
	Data        []float64 `json:"data" binding:"required"`
	Percentiles []float64 `json:"percentiles" binding:"required"`
}

func (h *PercentileCalculatorHandler) CalculatePercentiles(c *gin.Context) {
	// 1. Optional Auth Check
	_, _ = middlewares.GetUserID(c)

	// 2. Bind JSON
	var req CalculatePercentilesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON format: " + err.Error()})
		return
	}

	// 3. Validation: The service will fail/panic if data is empty
	if len(req.Data) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "data array cannot be empty"})
		return
	}

	// 4. Data Conversion: Convert []float64 to []int64 for the service
	// This is necessary because your service explicitly asks for int64
	intData := make([]int64, len(req.Data))
	for i, v := range req.Data {
		intData[i] = int64(v)
	}

	// 5. Call Service
	// Since your service doesn't return an error, we call it directly
	results := h.percentileCalculatorService.CalculatePercentiles(intData, req.Percentiles)

	// 6. Return Response
	c.JSON(http.StatusOK, gin.H{
		"results": results,
		"count":   len(intData),
	})
}
