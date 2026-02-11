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

func traceHandlerTestDB(t *testing.T) *gorm.DB {
	db, err := services.OpenTestSQLite()
	if err != nil {
		t.Fatalf("OpenTestSQLite: %v", err)
	}
	return db
}

func TestTraceHandler_GetTraces_InvalidWorkspaceID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := traceHandlerTestDB(t)
	th := NewTraceHandler(services.NewTraceService(db), services.NewWaterfallService(db))
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/workspaces/bad-uuid/traces", nil)
	c.Params = gin.Params{{Key: "workspace_id", Value: "bad-uuid"}}
	c.Set("user_id", uuid.New())
	th.GetTraces(c)
	if w.Code != http.StatusBadRequest {
		t.Errorf("code = %d; want 400", w.Code)
	}
}

func TestTraceHandler_GetTraces_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := traceHandlerTestDB(t)
	userID := uuid.New()
	wsID := uuid.New()
	db.Create(&models.User{ID: userID, Email: "u@test.com", Password: "x", Name: "U"})
	db.Create(&models.Workspace{ID: wsID, Name: "WS", OwnerID: userID})
	db.Create(&models.WorkspaceMember{ID: uuid.New(), WorkspaceID: wsID, UserID: userID, Role: "admin"})

	svc := services.NewTraceService(db)
	tr, _ := svc.CreateTrace(wsID, "api", "success")
	if tr == nil {
		t.Fatal("create trace failed")
	}

	th := NewTraceHandler(svc, services.NewWaterfallService(db))
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/workspaces/"+wsID.String()+"/traces", nil)
	c.Params = gin.Params{{Key: "workspace_id", Value: wsID.String()}}
	c.Set("user_id", userID)
	th.GetTraces(c)
	if w.Code != http.StatusOK {
		t.Errorf("code = %d; body = %s", w.Code, w.Body.String())
	}
}

func TestTraceHandler_GetTraceDetails_InvalidTraceID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := traceHandlerTestDB(t)
	th := NewTraceHandler(services.NewTraceService(db), services.NewWaterfallService(db))
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/traces/bad", nil)
	c.Params = gin.Params{{Key: "trace_id", Value: "bad"}}
	c.Set("user_id", uuid.New())
	th.GetTraceDetails(c)
	if w.Code != http.StatusBadRequest {
		t.Errorf("code = %d; want 400", w.Code)
	}
}
