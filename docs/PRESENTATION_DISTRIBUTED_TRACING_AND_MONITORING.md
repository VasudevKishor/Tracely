# Presentation: Distributed Tracing & Monitoring  
**Vasudev Kishor — Use this while presenting**

---

## Opening (15 sec)

**“My module is Distributed Tracing and Monitoring.”**

- **Tracing:** One request crossing many services → we record each step as a **span** under one **trace** so we see the full journey and where time is spent or where it failed.
- **Monitoring:** Dashboards, service topology, latency percentiles (P50/P95/P99), load testing, and alerts.

---

## Your components at a glance

| Layer | Files | Role in one line |
|--------|--------|-------------------|
| **Handlers** | trace_handler, tracing_config_handler, monitoring_handler, loadtest_handler, alert_handler | HTTP API: list traces, config CRUD, dashboard/topology/latencies, create load test, alert rules & acknowledge |
| **Services** | trace_service, waterfall_service, monitoring_service, load_test_service, failure_injection_service, percentile_calculator, alerting_service | Business logic: create traces/spans, build waterfall tree, dashboard/topology/latencies, run load test, inject failures, P50/P95/P99, alert rules & trigger |
| **Middlewares** | trace.go, grpc_interceptor.go, graphql_wrapper.go | Set/propagate **trace ID + span ID + parent span ID** on every request (HTTP, gRPC, GraphQL). |

---

## What to say: Tracing

- “We attach a **trace ID** and **span ID** to every request. Our **middlewares** do this for **HTTP, gRPC, and GraphQL**.”
- “When a request goes through multiple services, each hop can send these IDs in headers or metadata, so we see the full path and each step’s duration.”
- “We store **traces** and **spans** in the DB. The UI shows a **waterfall** (tree of spans) and the **critical path** — the longest chain that contributes most to latency.”
- “We have **per-service tracing config**: enable/disable, sampling rate, path exclusions, and whether to propagate context.”

---

## What to say: Monitoring

- “**Monitoring** uses trace and execution data. We have a **dashboard**: total/success/fail requests, average response time, error rate, list of services.”
- “**Topology** shows which service calls which, from parent–child span relationships.”
- “**Per-service latencies** use a **percentile calculator** for P50, P95, P99.”
- “**Load testing**: pick a saved request, set concurrency and total requests; it runs in the background and we store success/failure and response time percentiles.”
- “**Alerting**: rules like ‘latency above X’ or ‘error rate above Y’; when triggered we create an alert and can notify via Slack/Email/PagerDuty — stubs for now. **Failure injection** simulates timeout/error/latency for testing.”

---

## One-sentence summary (for mam)

**“We make every request traceable across HTTP, gRPC, and GraphQL, store traces and spans, visualize them with waterfall and critical path, and provide monitoring with dashboard, topology, per-service latencies, load testing, and alerting.”**

---

## If asked: “How does trace propagation work?”

- “For **HTTP** we use headers: **X-Trace-ID**, **X-Span-ID**, **X-Parent-Span-ID**. Middleware reads them or generates new ones, sets them in context and response headers.”
- “For **gRPC** we use **metadata** (incoming/outgoing). For **GraphQL** we use the same header names and put IDs in the request context.”
- “So the whole chain shares one trace ID; each hop has a span ID and parent span ID. That’s how we build the span tree and the waterfall.”

---

## If asked: “Explain one handler in detail”

**Example — TraceHandler:**

- “It uses **TraceService** and **WaterfallService**.”
- “**GetTraces**: workspace_id from URL, optional filters (service_name, start_time, end_time, limit, offset). Calls TraceService.GetTraces (checks workspace access, returns list + total).”
- “**GetTraceDetails**: trace_id → returns trace + its spans (access checked).”
- “**GetWaterfall**: trace_id → verifies access, then WaterfallService builds a tree (root span, children by parent_span_id) for the UI waterfall chart.”
- “**AddAnnotation**: add a comment/highlight on a span. **GetCriticalPath**: returns the longest chain of spans (critical path).”

---

## If asked: “What is the critical path?”

- “The **critical path** is the longest sequential chain of spans (parent → child) in a trace. It’s the part of the request that contributes most to total latency. We compute it by walking the span tree and picking the path with the maximum total duration.”

---

## If asked: “What is the waterfall?”

- “The **waterfall** is a **tree** of spans: root span (no parent), then children ordered by start time. Each node has name, service, start/end, duration, offset from trace start, depth, and children. The frontend uses this to draw the timeline view.”

---

## Quick file reference (your module only)

**Handlers:**  
`trace_handler.go` · `tracing_config_handler.go` · `monitoring_handler.go` · `loadtest_handler.go` · `alert_handler.go`

**Services:**  
`trace_service.go` · `waterfall_service.go` · `monitoring_service.go` · `load_test_service.go` · `failure_injection_service.go` · `percentile_calculator.go` · `alerting_service.go`  
*(TracingConfigHandler uses `tracing_config_service.go`.)*

**Middlewares:**  
`trace.go` (TraceID + ServiceTracingMiddleware) · `grpc_interceptor.go` · `graphql_wrapper.go`

---

## Flow in 30 seconds

1. Request hits API → **middleware** sets/reads trace ID, span ID, parent span ID (HTTP headers or gRPC/GraphQL context).
2. **TraceService** creates/updates **Trace** and **Spans**; **WaterfallService** turns spans into a tree for the UI.
3. **TracingConfigService** + **ServiceTracingMiddleware** decide per service: enabled, sampling, path exclusions, propagation.
4. **MonitoringService** uses Executions + Spans → dashboard, topology, **PercentileCalculator** → P50/P95/P99.
5. **LoadTestService** runs a request N times with concurrency → stores results and percentiles.
6. **AlertingService** evaluates rules (latency/error rate) → creates alerts, notifies (Slack/Email/PagerDuty stubs).

---

