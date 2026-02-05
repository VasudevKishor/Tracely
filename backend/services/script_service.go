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

    // Define pm.test in VM using the Go helper. Also attach environment object later.
    _, _ = vm.RunString(`
        if (typeof pm === 'undefined') { pm = {}; }
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

    // Attach environment helper to pm (if variables were provided in ctx)
    envVars := map[string]interface{}{}
    if ctx != nil {
        if v, ok := ctx["variables"].(map[string]interface{}); ok {
            for kk, vv := range v {
                envVars[kk] = vv
            }
        }
    }

    envObj := vm.NewObject()
    _ = envObj.Set("get", func(call goja.FunctionCall) goja.Value {
        key := ""
        if len(call.Arguments) > 0 {
            key = call.Argument(0).String()
        }
        if val, ok := envVars[key]; ok {
            return vm.ToValue(val)
        }
        return goja.Undefined()
    })
    _ = envObj.Set("set", func(call goja.FunctionCall) goja.Value {
        if len(call.Arguments) > 0 {
            key := call.Argument(0).String()
            var val interface{} = nil
            if len(call.Arguments) > 1 {
                val = call.Argument(1).Export()
            }
            envVars[key] = val
        }
        return goja.Undefined()
    })
    _ = envObj.Set("toObject", func(call goja.FunctionCall) goja.Value {
        return vm.ToValue(envVars)
    })

    _ = vm.Set("_pm_env", envObj)
    _, _ = vm.RunString(`
        if (typeof pm === 'undefined') { pm = {}; }
        pm.environment = _pm_env;
    `)

    // Run the script
    _, err := vm.RunString(script)
    if err != nil {
        result.Error = err.Error()
        return result, nil
    }

    return result, nil
}
