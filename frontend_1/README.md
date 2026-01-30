# Tracely - Flutter Frontend

**Unified API Debugging, Distributed Tracing and Scenario Automation Platform**

A comprehensive Flutter web application for API testing, debugging, and distributed tracing management.

---

## 📱 Platform Support

- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Android** (Mobile)
- ✅ **iOS** (Mobile)
- ✅ **Windows** (Desktop)
- ✅ **macOS** (Desktop)
- ✅ **Linux** (Desktop)

---

## 🎯 Features

### Core Features
- **API Request Builder** - Create and manage API requests
- **Request Studio** - Visual interface for building and testing APIs
- **Collections** - Organize requests into logical collections
- **Workspaces** - Separate projects and teams
- **User Authentication** - Secure login and session management
- **Distributed Tracing** - Visualize and analyze distributed traces
- **Real-time Monitoring** - Dashboard with performance metrics
- **Governance** - Policies and governance controls
- **Settings** - User preferences and configurations

### UI Modules
1. **Landing Screen** - Welcome and information page
2. **Auth Screen** - Login/Register interface
3. **Home Screen** - Dashboard and overview
4. **Workspaces Screen** - Workspace management
5. **Request Studio** - API request testing tool
6. **Collections Screen** - Collection organization
7. **Monitoring Screen** - Real-time monitoring dashboard
8. **Governance Screen** - Policies and settings
9. **Settings Screen** - User preferences

---

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** (v3.6.0 or higher)
- **Dart SDK** (included with Flutter)
- **Git**

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/VasudevKishor/Unified-API-debugging-Distributed-Tracing-and-scenario-automation-platform.git
   cd Unified-API-debugging-Distributed-Tracing-and-scenario-automation-platform/frontend_1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # For web
   flutter run -d chrome

   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios

   # For Windows
   flutter run -d windows

   # For macOS
   flutter run -d macos

   # For Linux
   flutter run -d linux
   ```

---

## 🏗️ Project Structure

```
frontend_1/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── screens/
│   │   ├── landing_screen.dart        # Welcome screen
│   │   ├── auth_screen.dart           # Login/Register
│   │   ├── home_screen.dart           # Dashboard
│   │   ├── workspaces_screen.dart     # Workspace management
│   │   ├── request_studio_screen.dart # API request builder
│   │   ├── collections_screen.dart    # Collections
│   │   ├── monitoring_screen.dart     # Monitoring dashboard
│   │   ├── governance_screen.dart     # Governance
│   │   └── settings_screen.dart       # User settings
│   └── widgets/
│       ├── common_widgets.dart        # Reusable widgets
│       ├── top_bar_widget.dart        # Top navigation
│       └── footer_widget.dart         # Footer
├── test/
│   └── widget_test.dart               # Widget tests
├── web/
│   ├── index.html                     # Web entry point
│   ├── manifest.json                  # Web manifest
│   └── icons/                         # Web icons
├── android/                           # Android native code
├── ios/                               # iOS native code
├── windows/                           # Windows native code
├── macos/                             # macOS native code
├── linux/                             # Linux native code
├── pubspec.yaml                       # Dependencies
├── pubspec.lock                       # Lock file
└── analysis_options.yaml              # Lint rules
```

---

## 📦 Dependencies

- **flutter** - UI framework
- **cupertino_icons** - iOS style icons (v1.0.8)

### Future Dependencies (Recommended)
- **http** - HTTP client for API calls
- **provider** - State management
- **dio** - HTTP networking
- **json_serializable** - JSON parsing
- **get_it** - Dependency injection
- **flutter_secure_storage** - Secure token storage
- **intl** - Internationalization

---

## 🔌 Backend Integration

The frontend connects to a Go backend API.

### Configuration

Update the backend URL in your environment:

**Development:**
```
http://localhost:8080
```

**Production:**
```
https://api.tracely.com
```

### API Endpoints

See `BACKEND_API_DOCUMENTATION.md` for complete API specification.

### Authentication Flow

1. User logs in on Auth Screen
2. Backend returns JWT token
3. Token stored securely (local storage or secure storage)
4. Token sent with all API requests via Authorization header
5. Token refreshed when expired

---

## 🏗️ Building for Production

### Web Build
```bash
flutter build web --release
```
Output: `build/web/`

### Android Build
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Build
```bash
flutter build ipa --release
```

### Windows Build
```bash
flutter build windows --release
```
Output: `build/windows/runner/Release/`

### macOS Build
```bash
flutter build macos --release
```

### Linux Build
```bash
flutter build linux --release
```
Output: `build/linux/x64/release/bundle/`

---

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Specific Test File
```bash
flutter test test/widget_test.dart
```

---

## 🎨 Theme Configuration

The app uses Material Design with customization:

```dart
theme: ThemeData(
  fontFamily: 'SF Pro Display',
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  colorScheme: ColorScheme.light(
    primary: Colors.grey.shade900,
    secondary: Colors.grey.shade700,
    surface: Colors.white,
  ),
)
```

---

## 📱 Screens Overview

### Landing Screen
- Welcome information
- Features overview
- Call to action buttons

### Auth Screen
- Login form
- Registration form
- Password recovery
- Social login (if implemented)

### Home Screen
- Dashboard overview
- Quick stats
- Recent activity
- Quick actions

### Workspaces Screen
- List all workspaces
- Create new workspace
- Manage members
- Switch workspace

### Request Studio
- Build API requests
- Set headers and parameters
- Execute requests
- View responses
- Save requests

### Collections Screen
- Organize requests
- Group by collection
- Search and filter
- Share collections

### Monitoring Screen
- Real-time metrics
- Performance graphs
- Service health
- Error tracking

### Governance Screen
- Manage policies
- Set access controls
- Audit logs
- Compliance settings

### Settings Screen
- User preferences
- Theme selection
- Notifications
- Account settings

---

## 🔐 Security

- **JWT Authentication** - Secure token-based auth
- **Secure Storage** - Tokens stored securely
- **HTTPS** - Use HTTPS in production
- **CORS** - Configured on backend
- **Input Validation** - Validate all user inputs
- **Error Handling** - Safe error messages

---

## 📊 Performance

- **Tree Shaking** - Unused icons are removed (~99% reduction)
- **Code Splitting** - Lazy loading where applicable
- **Optimization** - Compiled for production

### Build Sizes (Approximate)
- Web: 1-3 MB (gzipped)
- Android APK: 50-100 MB
- iOS App: 70-150 MB

---

## 🐛 Troubleshooting

### App won't start
```bash
flutter clean
flutter pub get
flutter run
```

### Hot reload not working
- Restart the app: `r` + Enter
- Full restart: `R` + Enter

### Build errors
```bash
flutter doctor
flutter upgrade
flutter pub get
```

### Backend connection issues
- Check backend is running
- Verify backend URL in config
- Check firewall/proxy settings
- Verify CORS is enabled on backend

---

## 📚 Documentation

- **API Docs:** See `BACKEND_API_DOCUMENTATION.md`
- **Backend Guide:** See `BACKEND_DEVELOPMENT_GUIDE.md`
- **OpenAPI Spec:** See `openapi.yaml`

---

## 🔗 Related Repositories

- **Backend (Go):** [In Development]
- **Main Project:** [Unified-API-debugging-Distributed-Tracing-and-scenario-automation-platform](https://github.com/VasudevKishor/Unified-API-debugging-Distributed-Tracing-and-scenario-automation-platform)

---

## 🛠️ Development Workflow

### 1. Create a Branch
```bash
git checkout -b feature/feature-name
```

### 2. Make Changes
Edit files in `lib/screens/` or `lib/widgets/`

### 3. Run Tests
```bash
flutter test
```

### 4. Format Code
```bash
dart format lib/
```

### 5. Commit Changes
```bash
git add .
git commit -m "Add feature description"
```

### 6. Push and Create PR
```bash
git push origin feature/feature-name
```

---

## 📝 Code Style

- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused
- Use const constructors where possible

### Format Code
```bash
dart format lib/
```

### Analyze Code
```bash
flutter analyze
```

---

## 🚀 Deployment

### Web Deployment

**Using Firebase Hosting:**
```bash
flutter build web
firebase deploy
```

**Using Vercel:**
```bash
flutter build web
vercel deploy build/web
```

**Using Netlify:**
```bash
flutter build web
netlify deploy --prod --dir=build/web
```

### Mobile Deployment

**Android:**
- Build APK/AAB
- Upload to Google Play Store

**iOS:**
- Build IPA
- Upload to App Store

---

## 📞 Support & Contribution

### Report Issues
Create an issue on GitHub with:
- Description of the problem
- Steps to reproduce
- Screenshots/videos
- Device and OS info

### Contribute
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📄 License

This project is part of the Unified API Debugging, Distributed Tracing and Scenario Automation Platform.

---

## 🎓 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)

---

## 📅 Version History

**v1.0.0** (January 30, 2026)
- Initial release
- Core features implemented
- Web build ready
- Multi-platform support

---

## 👥 Team

**Frontend Development:** Flutter Team  
**Backend Development:** Go Team  
**Project:** Unified API Debugging Platform

---

## 🎯 Roadmap

- [ ] Advanced trace visualization
- [ ] Real-time collaboration
- [ ] Plugin system
- [ ] Mobile app enhancements
- [ ] Performance optimization
- [ ] Enhanced UI/UX
- [ ] Dark mode support
- [ ] Multi-language support

---

## 📧 Contact

For questions or support, please contact the development team or create an issue on GitHub.

---

