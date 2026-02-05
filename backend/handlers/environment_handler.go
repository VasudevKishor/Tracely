package handlers

import (
    "net/http"

    "backend/middlewares"
    "backend/services"

    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
)

type EnvironmentHandler struct {
    envService *services.EnvironmentService
}

func NewEnvironmentHandler(envService *services.EnvironmentService) *EnvironmentHandler {
    return &EnvironmentHandler{envService: envService}
}

type CreateEnvironmentRequest struct {
    Name        string                 `json:"name" binding:"required"`
    Description string                 `json:"description"`
    Variables   map[string]interface{} `json:"variables"`
}

func (h *EnvironmentHandler) Create(c *gin.Context) {
    userID, _ := middlewares.GetUserID(c)
    _ = userID

    workspaceID, err := uuid.Parse(c.Param("workspace_id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid workspace id"})
        return
    }

    var req CreateEnvironmentRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    env, err := h.envService.Create(workspaceID, req.Name, req.Description, req.Variables)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, env)
}

func (h *EnvironmentHandler) Get(c *gin.Context) {
    _, _ = middlewares.GetUserID(c)
    envID, err := uuid.Parse(c.Param("env_id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid env id"})
        return
    }
    env, err := h.envService.GetByID(envID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
        return
    }
    c.JSON(http.StatusOK, env)
}

func (h *EnvironmentHandler) List(c *gin.Context) {
    _, _ = middlewares.GetUserID(c)
    workspaceID, err := uuid.Parse(c.Param("workspace_id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid workspace id"})
        return
    }
    envs, err := h.envService.ListByWorkspace(workspaceID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.JSON(http.StatusOK, envs)
}

func (h *EnvironmentHandler) Delete(c *gin.Context) {
    _, _ = middlewares.GetUserID(c)
    envID, err := uuid.Parse(c.Param("env_id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid env id"})
        return
    }
    if err := h.envService.Delete(envID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    c.Status(http.StatusNoContent)
}
