package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WorkflowHandler handles HTTP requests related to workflows.
type WorkflowHandler struct {
	workflowService *services.WorkflowService
}

// NewWorkflowHandler creates a new instance of WorkflowHandler.
func NewWorkflowHandler(workflowService *services.WorkflowService) *WorkflowHandler {
	return &WorkflowHandler{workflowService: workflowService}
}

// CreateWorkflowRequest defines the payload for creating a new workflow.
type CreateWorkflowRequest struct {
	Name        string                  `json:"name" binding:"required"`
	Description string                  `json:"description"`
	Steps       []services.WorkflowStep `json:"steps" binding:"required"`
}

// Create handles the creation of a new workflow in a workspace.
func (h *WorkflowHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	var req CreateWorkflowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	workflow, err := h.workflowService.CreateWorkflow(
		workspaceID, userID, req.Name, req.Description, req.Steps,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, workflow)
}

// Execute triggers the execution of an existing workflow.
func (h *WorkflowHandler) Execute(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workflowID, _ := uuid.Parse(c.Param("workflow_id"))

	execution, err := h.workflowService.ExecuteWorkflow(workflowID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, execution)
}
