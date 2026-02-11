import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:tracely/core/config/env_config.dart';
import 'package:tracely/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= EMAIL / PASSWORD LOGIN =================

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ApiService()
          .login(_emailController.text.trim(), _passwordController.text);

      if (mounted) widget.onLoginSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ================= GOOGLE SIGN IN =================

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile', 'openid'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Google sign-in failed: missing ID token');
      }

      final endpoint = EnvConfig.googleAuthApi;
      if (endpoint == null || endpoint.isEmpty) {
        throw Exception('GOOGLE_AUTH_API not configured');
      }

      final resp = await http.post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Google auth failed: ${resp.body}');
      }

      final data = json.decode(resp.body);
      await ApiService().saveTokens(
        data['access_token'],
        data['refresh_token'],
      );

      if (mounted) widget.onLoginSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ================= GITHUB SIGN IN (DISABLED SAFELY) =================

  void _signInWithGitHub() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'GitHub login will be enabled later',
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                _buildLogo(theme),
                const SizedBox(height: 24),
                _buildEmailField(theme),
                const SizedBox(height: 16),
                _buildPasswordField(theme),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(theme),
                ],
                const SizedBox(height: 24),
                _buildSignInButton(theme),
                const SizedBox(height: 24),
                _buildDivider(theme),
                const SizedBox(height: 24),
                _buildSocialButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Center(
      child: Text(
        'Tracely',
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmailField(ThemeData theme) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Email'),
      validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Text(
      _errorMessage!,
      style: TextStyle(color: theme.colorScheme.error),
    );
  }

  Widget _buildSignInButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Sign in'),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return const Divider();
  }

  Widget _buildSocialButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            child: const Text('Google'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _signInWithGitHub,
            child: const Text('GitHub'),
          ),
        ),
      ],
    );
  }
}
