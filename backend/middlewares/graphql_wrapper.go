package middlewares

import (
	"context"
	"net/http"

	"github.com/google/uuid"
)

type GraphQLContextKey string

const TraceIDKey GraphQLContextKey = "trace_id"

// GraphQLMiddleware adds tracing to GraphQL requests
func GraphQLMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Extract or generate trace ID
		traceID := r.Header.Get("X-Trace-ID")
		if traceID == "" {
			traceID = uuid.New().String()
		}

		// Add to context
		ctx := context.WithValue(r.Context(), TraceIDKey, traceID)

		// Add to response header
		w.Header().Set("X-Trace-ID", traceID)

		// Call next handler with updated context
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// GetTraceIDFromContext extracts trace ID from GraphQL context
func GetTraceIDFromContext(ctx context.Context) string {
	if traceID, ok := ctx.Value(TraceIDKey).(string); ok {
		return traceID
	}
	return uuid.New().String()
}
