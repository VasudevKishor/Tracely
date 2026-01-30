# Software Requirements Specification (SRS)

**Project Name:** Unified API debugging , Distributed Tracing and scenario automation platform (beyond postman/ hoppscotch)
**Version:** 1.0
**Status:** Draft
**Date:** 2025-12-09

---
## 1. Introduction

### 1.1 Purpose
The purpose of this document is to define the requirements for the **Unified API Observability & Automation Platform**. This platform is designed to transcend traditional manual API testing tools (like Postman or Hoppscotch) by offering automated traffic recording, zero-code test generation, and distributed tracing.

### 1.2 Scope
The system will function as a middleware or sidecar agent that:
* **Intercepts** real-time API traffic (requests/responses) from application environments.
* **Converts** captured traffic into automated test cases.
* **Mocks** downstream dependencies (Databases, External APIs) automatically.
* **Visualizes** request flows via Distributed Tracing.
* **Replays** traffic for regression testing without writing manual scripts.

### 1.3 Definitions and Acronyms
| Term | Definition |
| :--- | :--- |
| **eBPF** | Extended Berkeley Packet Filter (technology for non-intrusive monitoring) |
| **Mocking** | Simulating the behavior of real dependencies (e.g., a database) |
| **Trace** | A record of the path a request takes through various services |
| **Regression** | A software bug introduced by a new change |

---

## 2. Overall Description

### 2.1 Product Perspective
Unlike standard HTTP clients, this platform integrates directly into the software development lifecycle (SDLC). It sits between the user and the backend services to capture "real-world" usage data and convert it into "test data."

### 2.2 User Classes and Characteristics
* **Backend Developer:** Uses the tool to debug failed requests and generate tests for their code.
* **QA Engineer:** Uses the regression replay feature to validate releases.
* **DevOps Engineer:** Configures the tracing agent and monitors system latency.

### 2.3 Operating Environment
* **Agent Compatibility:** Docker, Kubernetes, Linux (Systemd).
* **Language Support:** Go, Node.js, Python, Java.
* **User Interface:** Web-based Dashboard (React/Next.js).

---

## 3. System Features (Functional Requirements)

### 3.1 Traffic Capture & Recording
**Description:** The core ability to record interactions without code changes.

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| **FR-01** | The system shall capture HTTP/gRPC requests and responses via a proxy or SDK. | High |
| **FR-02** | The system shall record timestamp, headers, body, and status codes for every transaction. | High |
| **FR-03** | The system shall allow filtering of captured traffic (e.g., exclude `/health-check` endpoints). | Medium |

### 3.2 Automated Test Generation (Zero-Code)
**Description:** Converting recorded traffic into reusable test suites.

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| **FR-04** | The system shall automatically generate a test case file (YAML/JSON) from a recorded session. | High |
| **FR-05** | The system shall allow users to edit the expected response assertions in the generated test. | Medium |
| **FR-06** | The system shall support "Noise Filtering" (ignoring dynamic fields like timestamps or random IDs during comparison). | High |

### 3.3 Dependency Mocking
**Description:** Isolating the service under test.

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| **FR-07** | The system shall record interactions with downstream databases (SQL, Mongo) and external APIs. | High |
| **FR-08** | The system shall automatically mock these dependencies during test replay, removing the need for a live database connection. | High |

### 3.4 Distributed Tracing
**Description:** Visualizing the life of a request.

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| **FR-09** | The system shall generate a visual "Flame Graph" showing the latency of every span in a request. | Medium |
| **FR-10** | The system shall correlate logs with traces for unified debugging. | Medium |

---

## 4. Non-Functional Requirements

### 4.1 Performance
* **Latency Overhead:** The recording agent must add no more than **10ms** of latency to the application request.
* **Throughput:** The system must handle capturing **1,000 requests per second** per instance.

### 4.2 Security & Privacy
* **Data Sanitization:** The system must automatically redact sensitive PII (e.g., Credit Card numbers, Auth Tokens) from logs and recordings.
* **Access Control:** Only authenticated users can view production traces.

### 4.3 Scalability
* The architecture must rely on a horizontally scalable NoSQL store (e.g., ElasticSearch or MongoDB) for storing trace data.

---

## 5. Interface Requirements

### 5.1 User Interface (Dashboard)
* **Trace Explorer:** A search interface to query requests by Method, Status, or Duration.
* **Test Runner:** A UI to trigger regression suites and view Pass/Fail reports.

### 5.2 External Interfaces
* **CI/CD Integration:** The system shall provide a CLI tool to run tests within GitHub Actions or Jenkins.
* **Alerting:** Integration with Slack/Email for test failures.

---

## 6. User Stories

### 6.1 Debugging & Tracing

| ID | User Story | Acceptance Criteria | Priority |
| :--- | :--- | :--- | :--- |
| **US-01** | **As a** Developer,<br>**I want to** see a visual graph of my API request,<br>**So that** I can identify which database query is slowing down the response. | 1. User views a Gantt-chart style trace.<br>2. Clicking a span shows the raw SQL query. | High |
| **US-02** | **As a** Developer,<br>**I want to** replay a specific failed request locally,<br>**So that** I can debug it without reproducing the data setup manually. | 1. "Replay" button sends the exact same payload.<br>2. Mocks are used for DB calls. | High |

### 6.2 Automation

| ID | User Story | Acceptance Criteria | Priority |
| :--- | :--- | :--- | :--- |
| **US-03** | **As a** QA Engineer,<br>**I want to** convert live user traffic into a regression suite,<br>**So that** we have 100% test coverage of real-world scenarios. | 1. User selects a time range of traffic.<br>2. System generates a Test Suite file.<br>3. Tests pass/fail based on response diffs. | High |
| **US-04** | **As a** DevOps Engineer,<br>**I want to** filter out noise (like Dates/UUIDs) from tests,<br>**So that** tests don't fail falsely due to dynamic data. | 1. System suggests fields to ignore.<br>2. User can mark fields as "wildcards". | Medium |

---

## 7. Appendices
* **Appendix A:** Architecture Diagram (Agent vs. Server)
* **Appendix B:** Installation Guide (Docker Compose)
* **Appendix C:** CLI Command Reference
