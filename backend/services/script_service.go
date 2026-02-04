package services

import (
    "fmt"
    "strings"

    "github.com/dop251/goja"
)

// ScriptService runs small JavaScript snippets for pre-request and test scripts.
type ScriptService struct{}

func NewScriptService() *ScriptService {
    return &ScriptService{}
}

type ScriptResult struct {
    Logs  []string               `json:"logs"`
    Tests []map[string]interface{} `json:"tests"`
    Error string                 `json:"error,omitempty"`
}

// Run executes a script with a provided context object. The script can call
// pm.test(name, fn) to register tests and console.log(...) for logging.
func (s *ScriptService) Run(script string, ctx map[string]interface{}) (*ScriptResult, error) {
    vm := goja.New()

    result := &ScriptResult{
        Logs:  []string{},
        Tests: []map[string]interface{}{},
    }

    // Provide a simple console.log that captures logs
    console := vm.NewObject()
    _ = console.Set("log", func(call goja.FunctionCall) goja.Value {
        parts := make([]string, 0, len(call.Arguments))
        for _, a := range call.Arguments {
            parts = append(parts, fmt.Sprint(a.Export()))
        }
        result.Logs = append(result.Logs, strings.Join(parts, " "))
        return goja.Undefined()
    })
    _ = vm.Set("console", console)

    // pm.test implementation: define a small JS wrapper that calls a Go callback
    _ = vm.Set("_go_record_test", func(call goja.FunctionCall) goja.Value {
        name := ""
        if len(call.Arguments) > 0 {
            name = call.Argument(0).String()
        }
        pass := false
        if len(call.Arguments) > 1 {
            pass = call.Argument(1).ToBoolean()
        }
        entry := map[string]interface{}{"name": name, "pass": pass}
        if len(call.Arguments) > 2 {
            entry["message"] = call.Argument(2).String()
        }
        result.Tests = append(result.Tests, entry)
        return goja.Undefined()
    })

    // Define pm.test in VM to use the Go callback; this avoids calling user functions from Go directly.
    _, _ = vm.RunString(`
        var pm = {};
        pm.test = function(name, fn) {
            if (typeof fn !== 'function') {
                _go_record_test(name, false, 'second argument must be function');
                return;
            }
            try {
                var res = fn();
                _go_record_test(name, !!res);
            } catch (e) {
                _go_record_test(name, false, e && e.toString ? e.toString() : String(e));
            }
        };
    `)

    // Provide the user context as `ctx` global
    if ctx != nil {
        _ = vm.Set("ctx", ctx)
    }

    // Run the script
    _, err := vm.RunString(script)
    if err != nil {
        result.Error = err.Error()
        return result, nil
    }

    return result, nil
}
