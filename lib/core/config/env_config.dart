import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:8081/api/v1';

  static String? get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'];

  static String? get githubClientId => dotenv.env['GITHUB_CLIENT_ID'];

  static String? get googleAuthApi => dotenv.env['GOOGLE_AUTH_API'];
  static String? get githubAuthApi => dotenv.env['GITHUB_AUTH_API'];

  static bool get hasGoogleAuth =>
      googleClientId != null &&
      googleClientId!.isNotEmpty &&
      !googleClientId!.startsWith('your-');

  static bool get hasGitHubAuth =>
      githubClientId != null &&
      githubClientId!.isNotEmpty &&
      !githubClientId!.startsWith('your-');

  static bool get hasGoogleAuthApi =>
      googleAuthApi != null &&
      googleAuthApi!.isNotEmpty &&
      !googleAuthApi!.startsWith('http://localhost');

  static bool get hasGitHubAuthApi =>
      githubAuthApi != null &&
      githubAuthApi!.isNotEmpty &&
      !githubAuthApi!.startsWith('http://localhost');
}
