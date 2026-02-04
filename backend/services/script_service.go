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

    // pm.test implementation similar to Postman: collects test results
    pm := vm.NewObject()
    _ = pm.Set("test", func(call goja.FunctionCall) goja.Value {
        name := ""
        if len(call.Arguments) > 0 {
            name = call.Argument(0).String()
        }

        pass := false
        msg := ""

        if len(call.Arguments) > 1 {
            // second arg should be a function
            if fn, ok := goja.AssertFunction(call.Argument(1)); ok {
                // call it
                defer func() {
                    if r := recover(); r != nil {
                        pass = false
                        msg = fmt.Sprint(r)
                    }
                }()
                res := fn(goja.FunctionCall{})
                // Evaluate returned value truthiness using JS-like rules (crude)
                exported := res.Export()
                if exported == nil {
                    pass = false
                } else {
                    switch v := exported.(type) {
                    case bool:
                        pass = v
                    case float64:
                        pass = v != 0
                    case int:
                        pass = v != 0
                    case string:
                        pass = v != ""
                    default:
                        pass = true
                    }
                }
            } else {
                msg = "second argument to pm.test must be a function"
            }
        } else {
            msg = "pm.test requires a name and a function"
        }

        testEntry := map[string]interface{}{
            "name": name,
            "pass": pass,
        }
        if msg != "" {
            testEntry["message"] = msg
        }
        result.Tests = append(result.Tests, testEntry)

        return goja.Undefined()
    })
    _ = vm.Set("pm", pm)

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
