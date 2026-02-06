package middlewares

import (
	"context"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

// UnaryServerInterceptor intercepts unary gRPC calls
func GRPCUnaryInterceptor() grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
		// Extract or generate trace ID
		traceID := extractGRPCTraceID(ctx)
		spanID := extractGRPCSpanID(ctx)
		parentSpanID := extractGRPCParentSpanID(ctx)

		// Add to context
		ctx = context.WithValue(ctx, "trace_id", traceID)
		ctx = context.WithValue(ctx, "span_id", spanID)
		if parentSpanID != "" {
			ctx = context.WithValue(ctx, "parent_span_id", parentSpanID)
		}

		// Add to response metadata
		responsePairs := []string{"x-trace-id", traceID, "x-span-id", spanID}
		if parentSpanID != "" {
			responsePairs = append(responsePairs, "x-parent-span-id", parentSpanID)
		}
		grpc.SetHeader(ctx, metadata.Pairs(responsePairs...))

		// Call handler
		return handler(ctx, req)
	}
}

// StreamServerInterceptor intercepts streaming gRPC calls
func GRPCStreamInterceptor() grpc.StreamServerInterceptor {
	return func(srv interface{}, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		// Extract or generate trace ID
		traceID := extractGRPCTraceID(ss.Context())
		spanID := extractGRPCSpanID(ss.Context())
		parentSpanID := extractGRPCParentSpanID(ss.Context())

		// Wrap stream with trace context
		wrapped := &wrappedStream{
			ServerStream: ss,
			traceID:      traceID,
			spanID:       spanID,
			parentSpanID: parentSpanID,
		}

		responsePairs := []string{"x-trace-id", traceID, "x-span-id", spanID}
		if parentSpanID != "" {
			responsePairs = append(responsePairs, "x-parent-span-id", parentSpanID)
		}
		grpc.SetHeader(ss.Context(), metadata.Pairs(responsePairs...))

		return handler(srv, wrapped)
	}
}

func extractGRPCTraceID(ctx context.Context) string {
	md, ok := metadata.FromIncomingContext(ctx)
	if ok {
		if traceIDs := md.Get("x-trace-id"); len(traceIDs) > 0 {
			return traceIDs[0]
		}
	}
	return uuid.New().String()
}

func extractGRPCSpanID(ctx context.Context) string {
	md, ok := metadata.FromIncomingContext(ctx)
	if ok {
		if spanIDs := md.Get("x-span-id"); len(spanIDs) > 0 {
			return spanIDs[0]
		}
	}
	return uuid.New().String()
}

func extractGRPCParentSpanID(ctx context.Context) string {
	md, ok := metadata.FromIncomingContext(ctx)
	if ok {
		if parentSpanIDs := md.Get("x-parent-span-id"); len(parentSpanIDs) > 0 {
			return parentSpanIDs[0]
		}
	}
	return ""
}

type wrappedStream struct {
	grpc.ServerStream
	traceID string
	spanID  string
	parentSpanID string
}

func (w *wrappedStream) Context() context.Context {
	ctx := w.ServerStream.Context()
	ctx = context.WithValue(ctx, "trace_id", w.traceID)
	ctx = context.WithValue(ctx, "span_id", w.spanID)
	if w.parentSpanID != "" {
		ctx = context.WithValue(ctx, "parent_span_id", w.parentSpanID)
	}
	return ctx
}
