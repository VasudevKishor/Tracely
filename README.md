# Tracely

A beautiful Flutter mobile app for API debugging, distributed tracing, and scenario automation.

## Features

- **Material 3** design with dark mode (default) and light mode
- **Authentication** – Login, OTP verification, logout confirmation
- **Home** – Environment selector, summary cards, service status
- **Alerts** – Filterable alerts by severity and service
- **Traces** – List, search, filter, infinite scroll, trace details with timeline
- **Request/Response** – JSON viewer with copy, expand/collapse
- **Tests** – Test runs list, failure details, diff viewer
- **Logs** – Severity-filtered log viewer
- **Settings** – Theme toggle, notifications, account, logout

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.5+)
- Dart 3.5+

### Setup

1. Ensure Flutter is installed and in your PATH:
   ```bash
   flutter doctor
   ```

2. Add platform files (if not present):
   ```bash
   flutter create . --org com.tracely --project-name tracely
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Targets

- **iOS**: `flutter run -d ios`
- **Android**: `flutter run -d android`
- **Web**: `flutter run -d chrome`

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # Main shell with bottom navigation
├── core/
│   ├── theme/             # Light & dark themes
│   ├── providers/         # Theme, app state
│   └── widgets/           # Shared components
└── screens/
    ├── auth/              # Login, OTP
    ├── home/              # Dashboard
    ├── alerts/            # Alerts list
    ├── traces/            # Traces, details, timeline
    ├── tests/             # Test runs, details
    ├── logs/              # Logs viewer
    └── settings/          # Settings, logout
```

## UI Components

- Toast notifications
- Loading skeletons
- Error banners
- Empty states
- Confirmation dialogs
- Bottom navigation (Home, Alerts, Traces, Tests, Settings)
