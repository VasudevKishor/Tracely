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

		// Add to context
		ctx = context.WithValue(ctx, "trace_id", traceID)

		// Add to response metadata
		grpc.SetHeader(ctx, metadata.Pairs("x-trace-id", traceID))

		// Call handler
		return handler(ctx, req)
	}
}

// StreamServerInterceptor intercepts streaming gRPC calls
func GRPCStreamInterceptor() grpc.StreamServerInterceptor {
	return func(srv interface{}, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		// Extract or generate trace ID
		traceID := extractGRPCTraceID(ss.Context())

		// Wrap stream with trace context
		wrapped := &wrappedStream{
			ServerStream: ss,
			traceID:      traceID,
		}

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

type wrappedStream struct {
	grpc.ServerStream
	traceID string
}

func (w *wrappedStream) Context() context.Context {
	ctx := w.ServerStream.Context()
	return context.WithValue(ctx, "trace_id", w.traceID)
}
