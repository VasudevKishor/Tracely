package middlewares

import (
	"context"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

func TestExtractGRPCTraceID_FromMetadata(t *testing.T) {
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("x-trace-id", "grpc-trace-1"))
	got := extractGRPCTraceID(ctx)
	if got != "grpc-trace-1" {
		t.Errorf("extractGRPCTraceID = %q; want grpc-trace-1", got)
	}
}

func TestExtractGRPCTraceID_GeneratesWhenMissing(t *testing.T) {
	got := extractGRPCTraceID(context.Background())
	if got == "" {
		t.Error("extractGRPCTraceID should generate non-empty when missing")
	}
}

func TestExtractGRPCSpanID_FromMetadata(t *testing.T) {
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("x-span-id", "grpc-span-1"))
	got := extractGRPCSpanID(ctx)
	if got != "grpc-span-1" {
		t.Errorf("extractGRPCSpanID = %q; want grpc-span-1", got)
	}
}

func TestExtractGRPCSpanID_GeneratesWhenMissing(t *testing.T) {
	got := extractGRPCSpanID(context.Background())
	if got == "" {
		t.Error("extractGRPCSpanID should generate non-empty when missing")
	}
}

func TestExtractGRPCParentSpanID_FromMetadata(t *testing.T) {
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("x-parent-span-id", "parent-1"))
	got := extractGRPCParentSpanID(ctx)
	if got != "parent-1" {
		t.Errorf("extractGRPCParentSpanID = %q; want parent-1", got)
	}
}

func TestExtractGRPCParentSpanID_EmptyWhenMissing(t *testing.T) {
	got := extractGRPCParentSpanID(context.Background())
	if got != "" {
		t.Errorf("extractGRPCParentSpanID = %q; want empty", got)
	}
}

func TestGRPCUnaryInterceptor_SetsContextAndCallsHandler(t *testing.T) {
	interceptor := GRPCUnaryInterceptor()
	var capturedCtx context.Context
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		capturedCtx = ctx
		return "ok", nil
	}
	info := &grpc.UnaryServerInfo{FullMethod: "/test/Test"}
	ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs("x-trace-id", "t1", "x-span-id", "s1"))
	resp, err := interceptor(ctx, "request", info, handler)
	if err != nil {
		t.Fatalf("handler error: %v", err)
	}
	if resp != "ok" {
		t.Errorf("response = %v; want ok", resp)
	}
	traceID := capturedCtx.Value("trace_id")
	spanID := capturedCtx.Value("span_id")
	if traceID != "t1" {
		t.Errorf("trace_id in context = %v; want t1", traceID)
	}
	if spanID != "s1" {
		t.Errorf("span_id in context = %v; want s1", spanID)
	}
}
