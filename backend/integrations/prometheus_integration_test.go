package integrations

import (
	"testing"
)

func TestNewPrometheusIntegration(t *testing.T) {
	p := NewPrometheusIntegration("http://prometheus:9090")
	if p == nil {
		t.Fatal("NewPrometheusIntegration() returned nil")
	}
}
