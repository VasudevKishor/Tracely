package handlers

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"backend/models"
	"backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func monitoringHandlerTestDB(t *testing.T) *gorm.DB {
	db, err := services.OpenTestSQLite()
	if err != nil {
		t.Fatalf("OpenTestSQLite: %v", err)
	}
	return db
}

func TestMonitoringHandler_GetDashboard_InvalidWorkspaceID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := monitoringHandlerTestDB(t)
	mh := NewMonitoringHandler(services.NewMonitoringService(db))
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/workspaces/not-uuid/monitoring/dashboard", nil)
	c.Params = gin.Params{{Key: "workspace_id", Value: "not-uuid"}}
	c.Set("user_id", uuid.New())
	mh.GetDashboard(c)
	if w.Code != http.StatusBadRequest {
		t.Errorf("code = %d; want 400", w.Code)
	}
}

func TestMonitoringHandler_GetDashboard_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := monitoringHandlerTestDB(t)
	userID := uuid.New()
	wsID := uuid.New()
	db.Create(&models.User{ID: userID, Email: "u@test.com", Password: "x", Name: "U"})
	db.Create(&models.Workspace{ID: wsID, Name: "WS", OwnerID: userID})
	db.Create(&models.WorkspaceMember{ID: uuid.New(), WorkspaceID: wsID, UserID: userID, Role: "admin"})

	mh := NewMonitoringHandler(services.NewMonitoringService(db))
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/workspaces/"+wsID.String()+"/monitoring/dashboard?time_range=last_hour", nil)
	c.Params = gin.Params{{Key: "workspace_id", Value: wsID.String()}}
	c.Set("user_id", userID)
	mh.GetDashboard(c)
	if w.Code != http.StatusOK {
		t.Errorf("code = %d; body = %s", w.Code, w.Body.String())
	}
}
