package services

import (
    "testing"
)

func TestScriptService_Run(t *testing.T) {
    s := NewScriptService()

    script := `console.log("hello", ctx.val); pm.test("isOne", function(){ return ctx.val === 1; });`
    ctx := map[string]interface{}{"val": 1}

    res, err := s.Run(script, ctx)
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }

    if res == nil {
        t.Fatalf("expected result, got nil")
    }

    if len(res.Logs) != 1 {
        t.Fatalf("expected 1 log entry, got %d", len(res.Logs))
    }

    if res.Logs[0] != "hello 1" {
        t.Fatalf("unexpected log content: %q", res.Logs[0])
    }

    if len(res.Tests) != 1 {
        t.Fatalf("expected 1 test entry, got %d", len(res.Tests))
    }

    passVal, ok := res.Tests[0]["pass"].(bool)
    if !ok {
        t.Fatalf("test entry missing pass boolean: %#v", res.Tests[0])
    }
    if !passVal {
        t.Fatalf("expected test to pass")
    }
}
