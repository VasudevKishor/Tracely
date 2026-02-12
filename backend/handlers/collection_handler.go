/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the CollectionHandler, which manages collection-related routes
such as creating, retrieving, updating, and deleting collections within a workspace.
It enforces authentication and authorization by using middlewares to get the user ID
and interacts with the CollectionService to perform the business logic.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CollectionHandler handles HTTP requests related to collections.
type CollectionHandler struct {
	collectionService *services.CollectionService
}

// NewCollectionHandler creates a new instance of CollectionHandler.
func NewCollectionHandler(collectionService *services.CollectionService) *CollectionHandler {
	return &CollectionHandler{collectionService: collectionService}
}

// CreateCollectionRequest represents the payload for creating or updating a collection.
type CreateCollectionRequest struct {
	Name        string `json:"name" binding:"required"` // Collection name is required
	Description string `json:"description"`             // Optional collection description
}

// Create handles POST requests to create a new collection within a workspace.
func (h *CollectionHandler) Create(c *gin.Context) {
	// Get the authenticated user's ID from the middleware
	userID, _ := middlewares.GetUserID(c)

	// Parse workspace ID from URL parameter
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	// Bind JSON request payload
	var req CreateCollectionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Call service to create the collection
	collection, err := h.collectionService.Create(workspaceID, req.Name, req.Description, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, collection)
}

// GetAll handles GET requests to fetch all collections for a workspace.
func (h *CollectionHandler) GetAll(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	collections, err := h.collectionService.GetAll(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"collections": collections})
}

// GetByID handles GET requests to fetch a single collection by its ID.
func (h *CollectionHandler) GetByID(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	collectionID, err := uuid.Parse(c.Param("collection_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	collection, err := h.collectionService.GetByID(collectionID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, collection)
}

// Update handles PUT/PATCH requests to update an existing collection.
func (h *CollectionHandler) Update(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	collectionID, err := uuid.Parse(c.Param("collection_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var req CreateCollectionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	collection, err := h.collectionService.Update(collectionID, userID, req.Name, req.Description)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, collection)
}

// Delete handles DELETE requests to remove a collection by its ID.
func (h *CollectionHandler) Delete(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	collectionID, err := uuid.Parse(c.Param("collection_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	if err := h.collectionService.Delete(collectionID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return HTTP 204 No Content on successful deletion
	c.Status(http.StatusNoContent)
}
