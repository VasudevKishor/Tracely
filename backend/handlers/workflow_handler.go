package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WorkflowHandler handles HTTP requests related to workflow creation and execution within a workspace.
type WorkflowHandler struct {
	// workflowService contains business logic for workflows
	workflowService *services.WorkflowService
}

func NewWorkflowHandler(workflowService *services.WorkflowService) *WorkflowHandler {
	return &WorkflowHandler{workflowService: workflowService}
}

// CreateWorkflowRequest represents the request payload for creating a new workflow definition.
type CreateWorkflowRequest struct {
	Name        string                  `json:"name" binding:"required"`
	Description string                  `json:"description"`
	Steps       []services.WorkflowStep `json:"steps" binding:"required"`
}

// Create creates a new workflow within the specified workspace.
// It validates the request payload, associates the workflow with the authenticated user, and delegates creation to the service layer.
func (h *WorkflowHandler) Create(c *gin.Context) {
	// Retrieve authenticated user ID.
	userID, _ := middlewares.GetUserID(c)

	// Parse workspace ID from URL parameters
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	// Bind and validate request body.
	var req CreateWorkflowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Create workflow via service layer.
	workflow, err := h.workflowService.CreateWorkflow(
		workspaceID, userID, req.Name, req.Description, req.Steps,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	// Return newly created workflow.
	c.JSON(http.StatusCreated, workflow)
}

// Execute triggers execution of an existing workflow.
// The execution is performed on behalf of the authenticated user and returns execution metadata and results.
func (h *WorkflowHandler) Execute(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workflowID, _ := uuid.Parse(c.Param("workflow_id"))

	execution, err := h.workflowService.ExecuteWorkflow(workflowID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	//Return workflow execution results.
	c.JSON(http.StatusOK, execution)
}
