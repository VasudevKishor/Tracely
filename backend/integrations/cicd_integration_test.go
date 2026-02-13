package integrations

import (
	"testing"
)

func TestNewCICDIntegration(t *testing.T) {
	c := NewCICDIntegration("https://ci.example.com/webhook")
	if c == nil {
		t.Fatal("NewCICDIntegration() returned nil")
	}
}
