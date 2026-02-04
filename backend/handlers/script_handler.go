package handlers

import (
    "net/http"

    "backend/middlewares"
    "backend/services"

    "github.com/gin-gonic/gin"
)

type ScriptHandler struct {
    scriptService *services.ScriptService
}

func NewScriptHandler(scriptService *services.ScriptService) *ScriptHandler {
    return &ScriptHandler{scriptService: scriptService}
}

type RunScriptRequest struct {
    Script  string                 `json:"script" binding:"required"`
    Context map[string]interface{} `json:"context"`
}

func (h *ScriptHandler) RunScript(c *gin.Context) {
    _, _ = middlewares.GetUserID(c)

    var req RunScriptRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    res, err := h.scriptService.Run(req.Script, req.Context)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, res)
}
