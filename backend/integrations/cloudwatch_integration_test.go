package integrations

import (
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
)

func TestNewCloudWatchIntegration(t *testing.T) {
	cfg := aws.Config{}
	c := NewCloudWatchIntegration(cfg, "TestNamespace")
	if c == nil {
		t.Fatal("NewCloudWatchIntegration() returned nil")
	}
}
