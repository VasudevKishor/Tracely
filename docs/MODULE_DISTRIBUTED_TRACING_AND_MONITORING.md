# Your Module: Distributed Tracing & Monitoring

**Prepared for:** Vasudev Kishor  
**Use this to explain your part when mam asks.**

---

## 1. What is this module about? (30 seconds)

This module does two things:

1. **Distributed Tracing** – When a request goes through many services (API → Auth → Database → Cache), we record each step as a **span** under one **trace**. So we can see the full journey of a request and find where time is spent or where it failed.
2. **Monitoring** – We show dashboards (request counts, success/fail, latency), **service topology** (which service calls which), **latency percentiles** (P50, P95, P99), **load testing**, and **alerts** when something goes wrong.

---

## 2. High-level flow (what you can say)

- **HTTP/gRPC/GraphQL** requests get **trace IDs and span IDs** via middlewares so that all services can correlate their work.
- **Tracing config** is per workspace and per service: we can enable/disable tracing, set sampling rate, exclude paths, and control whether we propagate context to downstream calls.
- **Traces and spans** are stored in the DB; we can list traces, get trace details with spans, add **annotations** on spans, compute the **critical path** (longest chain), and generate **waterfall** view for the UI.
- **Monitoring** uses execution and trace data to build dashboard stats, topology graph, and per-service latencies (with a **percentile calculator**).
- **Load testing** runs a saved request with concurrency and total requests, then records success/failure and response time percentiles.
- **Alerts** are rules (e.g. latency or error rate above threshold); when triggered they create an alert and can notify via Slack/Email/PagerDuty (stub implementations).
- **Failure injection** (in services) can simulate timeout, error, latency, or unavailability for testing resilience.

---

## 3. Handlers (HTTP API layer)

| Handler | File | What it does |
|--------|------|----------------|
| **TraceHandler** | `handlers/trace_handler.go` | `GetTraces` – list traces (filter by service, time, pagination). `GetTraceDetails` – one trace + its spans. `AddAnnotation` – add comment/highlight on a span. `GetCriticalPath` – longest chain of spans. `GetWaterfall` – tree of spans for waterfall chart. |
| **TracingConfigHandler** | `handlers/tracing_config_handler.go` | CRUD for tracing config per service: Create, Update, Delete, GetByID, GetByServiceName, GetAll. Toggle (enable/disable one config), BulkToggle (many services). GetEnabledServices, GetDisabledServices, Check (is tracing enabled for a service?). |
| **MonitoringHandler** | `handlers/monitoring_handler.go` | `GetDashboard` – total/success/fail requests, avg response time, error rate, top endpoints, services. `GetTopology` – nodes and edges for service dependency graph. `GetServiceLatencies` – per-service count, avg, P50/P95/P99. `GetMetrics` – placeholder. |
| **LoadTestHandler** | `handlers/loadtest_handler.go` | `Create` – create a load test (name, request_id, concurrency, total_requests, ramp_up); starts execution in background and returns the load test record. |
| **AlertHandler** | `handlers/alert_handler.go` | `CreateRule` – create alert rule (name, condition, threshold, time_window, channel). `GetActiveAlerts` – list active alerts for workspace. `AcknowledgeAlert` – mark alert as acknowledged. |

---

## 4. Services (business logic)

| Service | File | What it does |
|---------|------|----------------|
| **TraceService** | `services/trace_service.go` | CreateTrace, AddSpan (with parent_span_id for hierarchy). GetTraces (with workspace access check, filters). GetTraceDetails. AddAnnotation. GetCriticalPath – finds longest chain of parent-child spans. |
| **WaterfallService** | `services/waterfall_service.go` | Builds a **tree** from a trace’s spans (root = no parent). Each node has span_id, name, service_name, start/end, duration, offset from trace start, depth, children, tags. Used for UI waterfall chart. |
| **MonitoringService** | `services/monitoring_service.go` | GetDashboard – from Executions: total/success/fail, error rate, avg response time; from Traces: services list. GetTopology – from Spans: which service calls which (parent span’s service → child span’s service). GetServiceLatencies – aggregate span durations by service, use PercentileCalculator for P50/P95/P99. |
| **LoadTestService** | `services/load_test_service.go` | CreateLoadTest – inserts LoadTest (pending), then runs executeLoadTest in a goroutine. executeLoadTest – runs concurrent workers that call RequestService.Execute for the given request_id, collects success/fail and response times, then updates LoadTest with status, success_count, failure_count, avg/P95/P99. |
| **FailureInjectionService** | `services/failure_injection_service.go` | InjectFailure – for a workspace, loads enabled rules, applies by probability; types: timeout (sleep 35s), error (from config status_code/message), latency (sleep delay_ms), unavailable (503). CreateRule – store a new rule. |
| **PercentileCalculator** | `services/percentile_calculator.go` | Calculate(values, percentile) – sort values, compute percentile index with linear interpolation. CalculatePercentiles(values, []float64) – returns map e.g. p50, p95, p99. Used by MonitoringService and LoadTestService. |
| **AlertingService** | `services/alerting_service.go` | CreateRule – store AlertRule (condition e.g. latency_threshold/error_rate, threshold, time_window, channel). CheckLatencyThreshold / CheckErrorRate – evaluate rules, TriggerAlert if exceeded. TriggerAlert – create Alert, send to Slack/Email/PagerDuty (stubs). AcknowledgeAlert, ResolveAlert, GetActiveAlerts. |

*(TracingConfigHandler uses TracingConfigService in `services/tracing_config_service.go` – same module, CRUD + toggle + enabled/disabled lists + IsTracingEnabled.)*

---

## 5. Middlewares (trace context propagation)

| Middleware | File | What it does |
|------------|------|----------------|
| **TraceID** | `middlewares/trace.go` | HTTP: read or generate X-Trace-ID, X-Span-ID, X-Parent-Span-ID; set in gin context and response headers. So every request has a trace context. |
| **ServiceTracingMiddleware** | `middlewares/trace.go` | Uses DB: gets workspace_id and X-Service-Name, loads per-service tracing config. If disabled or path excluded or not sampled → sets tracing_enabled false. Otherwise propagates trace/span/parent-span IDs like TraceID. Helper: IsTracingEnabled(c), GetTracingConfig(c). |
| **GRPCUnaryInterceptor / GRPCStreamInterceptor** | `middlewares/grpc_interceptor.go` | gRPC: read x-trace-id, x-span-id, x-parent-span-id from metadata (or generate). Put in context and in response metadata. For streams, wrap stream so Context() returns context with trace IDs. |
| **GraphQLMiddleware** | `middlewares/graphql_wrapper.go` | HTTP for GraphQL: same idea – read or generate trace/span/parent-span, put in request context and response headers. GetTraceIDFromContext(ctx) for resolvers. |

**One-liner for mam:** “We have one middleware for normal HTTP, one that also respects per-service tracing config from the DB, one for gRPC (unary and stream), and one for GraphQL, so trace context is consistent across HTTP, gRPC, and GraphQL.”

---

## 6. How the pieces connect

- **Request comes in** → TraceID or ServiceTracingMiddleware sets trace_id, span_id (and optional parent_span_id) in context and headers.
- **Downstream HTTP/gRPC/GraphQL** calls should send these headers/metadata so the next service continues the same trace and creates child spans.
- **TraceService** creates Trace and Spans (e.g. when request is executed or when middleware records spans); **WaterfallService** turns a trace’s spans into a tree for the UI.
- **TracingConfigService** stores per-service settings; **ServiceTracingMiddleware** uses them to decide whether to trace and whether to propagate.
- **MonitoringService** reads Executions and Spans to build dashboard and topology; uses **PercentileCalculator** for P50/P95/P99 in GetServiceLatencies.
- **LoadTestService** runs many executions of a request and uses the same idea (percentiles) for load test results.
- **AlertingService** evaluates rules on execution data and creates alerts; **AlertHandler** exposes create rule, list active alerts, acknowledge.

---

## 7. Short “explain like I’m presenting” script

You can say something like:

- “My module is **Distributed Tracing and Monitoring**.”
- “**Tracing** means we attach a trace ID and span IDs to every request. Our middlewares do this for HTTP, gRPC, and GraphQL. So when a request goes through multiple services, we can see the full path and each step’s duration. We store traces and spans in the DB. The UI can show a **waterfall** view and the **critical path** – the longest chain that contributes most to latency. We also support **per-service config**: enable/disable tracing, sampling rate, and path exclusions.”
- “**Monitoring** uses this data plus execution records. We have a **dashboard** with request counts, success/failure, average response time, error rate, and a list of services. We have a **topology** view that shows which service calls which, derived from parent-child span relationships. We also expose **per-service latencies** with P50, P95, P99 using a small **percentile calculator**.”
- “We have **load testing**: you pick a saved request and run it with a given concurrency and total number of requests; it runs in the background and we store success/failure counts and response time percentiles. We also have **alerting**: you define rules like ‘latency above X’ or ‘error rate above Y’ in a time window; when triggered we create an alert and can notify via Slack, email, or PagerDuty – those are stubs for now. There’s also a **failure injection** service used to simulate timeouts or errors for testing.”
- “So in one sentence: **we make every request traceable across services, visualize it, and monitor health and latency with dashboards, topology, load tests, and alerts.**”

---

## 8. If asked “Explain one handler in detail”

**Example: TraceHandler**

- “TraceHandler has two dependencies: TraceService and WaterfallService. GetTraces takes workspace_id from the URL and optional query params like service_name, start_time, end_time, limit, offset. It calls TraceService.GetTraces, which checks workspace access, then queries the traces table with those filters and returns the list and total count. GetTraceDetails takes trace_id, verifies access via GetTraceDetails, and returns the trace and its spans. GetWaterfall also takes trace_id, first verifies access via GetTraceDetails, then asks WaterfallService to build a tree from the trace’s spans – root span, then children by parent_span_id – and returns that tree for the frontend waterfall chart. AddAnnotation and GetCriticalPath are the other two endpoints: one adds a user comment on a span, the other returns the critical path computed by TraceService from the span tree.”

---

## 9. If asked “How does trace propagation work?”

- “For HTTP, we have a middleware that looks at headers X-Trace-ID, X-Span-ID, X-Parent-Span-ID. If they’re missing, we generate new IDs. We set these in the request context and in the response headers so the client or next service can send them on. For gRPC we do the same but using gRPC metadata (incoming and outgoing). For GraphQL we use the same header names and put the IDs in the request context. So as long as each service sends these headers in outgoing HTTP calls or metadata in gRPC calls, the whole chain shares one trace ID and each hop has a span ID and a parent span ID, which is how we build the tree and the waterfall.”

---

Good luck for your explanation.
