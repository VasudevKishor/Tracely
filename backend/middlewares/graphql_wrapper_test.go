package middlewares

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGraphQLMiddleware_GeneratesTraceIDsWhenMissing(t *testing.T) {
	var capturedTraceID, capturedSpanID string
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedTraceID = r.Context().Value(TraceIDKey).(string)
		capturedSpanID = r.Context().Value(SpanIDKey).(string)
		w.WriteHeader(http.StatusOK)
	})

	handler := GraphQLMiddleware(next)
	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if capturedTraceID == "" {
		t.Error("expected trace_id in context")
	}
	if capturedSpanID == "" {
		t.Error("expected span_id in context")
	}
	if rec.Header().Get("X-Trace-ID") != capturedTraceID {
		t.Error("X-Trace-ID header should match context")
	}
	if rec.Header().Get("X-Span-ID") != capturedSpanID {
		t.Error("X-Span-ID header should match context")
	}
	if rec.Header().Get("X-Parent-Span-ID") != "" {
		t.Error("X-Parent-Span-ID should be empty when not provided")
	}
}

func TestGraphQLMiddleware_PreservesIncomingTraceIDs(t *testing.T) {
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	handler := GraphQLMiddleware(next)
	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	req.Header.Set("X-Trace-ID", "trace-abc")
	req.Header.Set("X-Span-ID", "span-xyz")
	req.Header.Set("X-Parent-Span-ID", "parent-123")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Header().Get("X-Trace-ID") != "trace-abc" {
		t.Errorf("X-Trace-ID = %q; want trace-abc", rec.Header().Get("X-Trace-ID"))
	}
	if rec.Header().Get("X-Span-ID") != "span-xyz" {
		t.Errorf("X-Span-ID = %q; want span-xyz", rec.Header().Get("X-Span-ID"))
	}
	if rec.Header().Get("X-Parent-Span-ID") != "parent-123" {
		t.Errorf("X-Parent-Span-ID = %q; want parent-123", rec.Header().Get("X-Parent-Span-ID"))
	}
}

func TestGetTraceIDFromContext_ReturnsIDWhenPresent(t *testing.T) {
	ctx := context.WithValue(context.Background(), TraceIDKey, "my-trace-id")
	got := GetTraceIDFromContext(ctx)
	if got != "my-trace-id" {
		t.Errorf("GetTraceIDFromContext = %q; want my-trace-id", got)
	}
}

func TestGetTraceIDFromContext_GeneratesNewWhenMissing(t *testing.T) {
	got := GetTraceIDFromContext(context.Background())
	if got == "" {
		t.Error("GetTraceIDFromContext should return non-empty when key missing")
	}
}
