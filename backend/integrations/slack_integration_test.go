package integrations

import (
	"testing"
)

func TestNewSlackIntegration(t *testing.T) {
	s := NewSlackIntegration("https://hooks.slack.com/test")
	if s == nil {
		t.Fatal("NewSlackIntegration() returned nil")
	}
}
