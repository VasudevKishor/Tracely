# Tracely

**Tracely** is a unified platform for **API debugging, distributed tracing, and scenario automation**, with a modern **Flutter mobile frontend** and a powerful backend observability engine.

It goes **beyond Postman / Hoppscotch** by capturing real traffic, generating zero-code tests, replaying scenarios, and visualizing distributed traces.

---

## 🚀 Overview

- 📱 **Flutter mobile app** for monitoring, debugging, and quick actions
- 🧠 **Backend observability platform** for traffic capture, mocking, replay, and tracing
- ⚙️ Designed for **developers, QA engineers, and DevOps**

---

## 📱 Flutter Mobile App

A beautiful Flutter mobile app for API debugging, distributed tracing, and scenario automation.

### Features

- **Material 3** design with dark mode (default) and light mode
- **Authentication** – Login, OTP verification, logout confirmation
- **Home** – Environment selector, summary cards, service status
- **Alerts** – Filterable alerts by severity and service
- **Traces** – List, search, filter, infinite scroll, trace details with timeline
- **Request/Response** – JSON viewer with copy, expand/collapse
- **Tests** – Test runs list, failure details, diff viewer
- **Logs** – Severity-filtered log viewer
- **Settings** – Theme toggle, notifications, account, logout

---

## 📂 Mobile App Structure
frontend_1/lib/
├── main.dart
├── providers/
│ ├── auth_provider.dart
│ ├── trace_provider.dart
│ └── workspace_provider.dart
├── screens/
│ ├── auth/
│ ├── home/
│ ├── alerts/
│ ├── traces/
│ ├── tests/
│ ├── logs/
│ └── settings/
├── services/
│ └── api_service.dart
└── widgets/

---

## 🧠 Backend Platform (SRS Summary)

### Purpose
The backend platform provides **automated API observability and testing**, eliminating manual scripting and enabling real-world regression testing.

### Core Capabilities

- **Traffic Capture** – HTTP/gRPC interception
- **Automated Test Generation** – YAML/JSON from live traffic
- **Dependency Mocking** – Databases & external APIs
- **Distributed Tracing** – Span-level latency visualization
- **Replay Engine** – Regression testing without manual setup

---

## 🧩 System Features

### Traffic Capture
- Records request/response, headers, body, timestamps
- Supports filtering noisy endpoints

### Automation
- Zero-code test generation
- Noise filtering for dynamic fields (UUIDs, timestamps)

### Tracing
- End-to-end request visualization
- Log + trace correlation

---

## 👥 Target Users

- **Backend Developers** – Debug and replay failures
- **QA Engineers** – Regression from real traffic
- **DevOps Engineers** – Monitoring, latency, alerts

---

## 🛠️ Getting Started (Flutter)

### Prerequisites
- Flutter SDK **3.5+**
- Dart **3.5+**

### Setup

```bash
flutter doctor
flutter pub get
flutter run
Targets:

Android

iOS

Web (Chrome / Edge)
backend/        # Observability & automation backend
frontend_1/     # Flutter mobile & desktop app
openapi.yaml
📄 Documentation

Backend setup & deployment guides in backend/

API specifications in openapi.yaml

Flutter UI code in frontend_1/
📌 Project Status

Backend: 🚧 In progress

Flutter frontend: 🚧 Active development

CI/CD: ⏳ Planned
Build a developer-first observability and automation platform that replaces manual API testing with real traffic intelligence.

---



