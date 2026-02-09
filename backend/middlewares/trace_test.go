package middlewares

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestTraceIDMiddleware_GeneratesSpanContext(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.Use(TraceID())
	router.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"trace_id":       c.GetString("trace_id"),
			"span_id":        c.GetString("span_id"),
			"parent_span_id": c.GetString("parent_span_id"),
		})
	})

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	resp := httptest.NewRecorder()
	router.ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", resp.Code)
	}

	if resp.Header().Get("X-Trace-ID") == "" {
		t.Fatal("expected X-Trace-ID header to be set")
	}
	if resp.Header().Get("X-Span-ID") == "" {
		t.Fatal("expected X-Span-ID header to be set")
	}
	if resp.Header().Get("X-Parent-Span-ID") != "" {
		t.Fatal("expected X-Parent-Span-ID header to be empty when not provided")
	}

	var payload map[string]string
	if err := json.Unmarshal(resp.Body.Bytes(), &payload); err != nil {
		t.Fatalf("failed to unmarshal response: %v", err)
	}
	if payload["trace_id"] == "" {
		t.Fatal("expected trace_id in response payload")
	}
	if payload["span_id"] == "" {
		t.Fatal("expected span_id in response payload")
	}
	if payload["parent_span_id"] != "" {
		t.Fatal("expected parent_span_id in response payload to be empty")
	}
}

func TestTraceIDMiddleware_PreservesSpanContext(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.Use(TraceID())
	router.GET("/test", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.Header.Set("X-Trace-ID", "trace-123")
	req.Header.Set("X-Span-ID", "span-456")
	req.Header.Set("X-Parent-Span-ID", "parent-789")

	resp := httptest.NewRecorder()
	router.ServeHTTP(resp, req)

	if resp.Header().Get("X-Trace-ID") != "trace-123" {
		t.Fatal("expected X-Trace-ID to match request header")
	}
	if resp.Header().Get("X-Span-ID") != "span-456" {
		t.Fatal("expected X-Span-ID to match request header")
	}
	if resp.Header().Get("X-Parent-Span-ID") != "parent-789" {
		t.Fatal("expected X-Parent-Span-ID to match request header")
	}
}
