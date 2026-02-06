package middlewares

import (
	"context"
	"net/http"

	"github.com/google/uuid"
)

type GraphQLContextKey string

const TraceIDKey GraphQLContextKey = "trace_id"
const SpanIDKey GraphQLContextKey = "span_id"
const ParentSpanIDKey GraphQLContextKey = "parent_span_id"

// GraphQLMiddleware adds tracing to GraphQL requests
func GraphQLMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Extract or generate trace ID
		traceID := r.Header.Get("X-Trace-ID")
		spanID := r.Header.Get("X-Span-ID")
		parentSpanID := r.Header.Get("X-Parent-Span-ID")
		if traceID == "" {
			traceID = uuid.New().String()
		}
		if spanID == "" {
			spanID = uuid.New().String()
		}

		// Add to context
		ctx := context.WithValue(r.Context(), TraceIDKey, traceID)
		ctx = context.WithValue(ctx, SpanIDKey, spanID)
		if parentSpanID != "" {
			ctx = context.WithValue(ctx, ParentSpanIDKey, parentSpanID)
		}

		// Add to response header
		w.Header().Set("X-Trace-ID", traceID)
		w.Header().Set("X-Span-ID", spanID)
		if parentSpanID != "" {
			w.Header().Set("X-Parent-Span-ID", parentSpanID)
		}

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
