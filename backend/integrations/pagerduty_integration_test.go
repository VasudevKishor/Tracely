package integrations

import (
	"testing"
)

func TestNewPagerDutyIntegration(t *testing.T) {
	p := NewPagerDutyIntegration("test-key")
	if p == nil {
		t.Fatal("NewPagerDutyIntegration() returned nil")
	}
}
