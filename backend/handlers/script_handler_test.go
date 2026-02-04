package handlers

import (
    "bytes"
    "encoding/json"
    "net/http/httptest"
    "testing"

    "backend/services"

    "github.com/gin-gonic/gin"
)

func TestScriptHandler_RunScript(t *testing.T) {
    gin.SetMode(gin.TestMode)

    srv := services.NewScriptService()
    h := NewScriptHandler(srv)

    // Build request body
    payload := map[string]interface{}{
        "script":  `console.log("hi", ctx.x); pm.test("ok", function(){ return ctx.x === 2; });`,
        "context": map[string]interface{}{"x": 2},
    }
    b, _ := json.Marshal(payload)

    w := httptest.NewRecorder()
    c, _ := gin.CreateTestContext(w)
    req := httptest.NewRequest("POST", "/api/v1/scripts/run", bytes.NewBuffer(b))
    req.Header.Set("Content-Type", "application/json")
    c.Request = req

    h.RunScript(c)

    if w.Code != 200 {
        t.Fatalf("expected status 200, got %d: %s", w.Code, w.Body.String())
    }

    // Basic check: response must contain logs and tests fields
    var resp map[string]interface{}
    if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
        t.Fatalf("response not valid JSON: %v", err)
    }

    if _, ok := resp["logs"]; !ok {
        t.Fatalf("response missing logs: %#v", resp)
    }
    if _, ok := resp["tests"]; !ok {
        t.Fatalf("response missing tests: %#v", resp)
    }
}
