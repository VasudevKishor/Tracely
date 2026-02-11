import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tracely/core/config/env_config.dart';
import 'package:tracely/services/api_service.dart';

enum HttpMethod { get, post, put, delete, patch }

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  // Real test runs populated from backend (empty until backend supports it)
  final List<_TestRun> _runs = [];

  HttpMethod _method = HttpMethod.get;
  final _urlController =
      TextEditingController(text: '/health');
  final _bodyController = TextEditingController();
  bool _sending = false;
  String? _responseStatus;
  String? _responseBody;
  String? _responseError;

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  /// Build the final URL from user input.
  /// - If the input starts with '/', treat it as a path relative to BASE_URL.
  /// - If the input is a full URL (http:// or https://), use it as-is.
  String _buildUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    // Relative path — prepend BASE_URL
    final base = EnvConfig.baseUrl;
    // Avoid double slashes: if base ends with '/' and input starts with '/'
    if (base.endsWith('/') && input.startsWith('/')) {
      return '$base${input.substring(1)}';
    }
    if (!base.endsWith('/') && !input.startsWith('/')) {
      return '$base/$input';
    }
    return '$base$input';
  }

  /// Determine if the URL targets our own backend (needs auth header).
  bool _isBackendUrl(String url) {
    final base = EnvConfig.baseUrl;
    return url.startsWith(base);
  }

  Future<void> _sendRequest() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _responseError = 'Enter a URL or path (e.g. /health)';
        _responseStatus = null;
        _responseBody = null;
      });
      return;
    }

    setState(() {
      _sending = true;
      _responseError = null;
      _responseStatus = null;
      _responseBody = null;
    });

    try {
      final url = _buildUrl(rawUrl);
      final uri = Uri.parse(url);
      final hasBody =
          _method == HttpMethod.post || _method == HttpMethod.put || _method == HttpMethod.patch;

      String? body;
      if (hasBody && _bodyController.text.trim().isNotEmpty) {
        body = _bodyController.text.trim();
        try {
          json.decode(body);
        } catch (_) {
          body = json.encode({'raw': body});
        }
      }

      // Build headers: always include Content-Type, add auth for backend URLs
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_isBackendUrl(url)) {
        final token = ApiService().accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      debugPrint('[TestsScreen] ${_methodLabel(_method)} $url');

      http.Response response;

      switch (_method) {
        case HttpMethod.get:
          response = await http.get(uri, headers: headers);
          break;
        case HttpMethod.post:
          response = await http.post(uri, headers: headers, body: body);
          break;
        case HttpMethod.put:
          response = await http.put(uri, headers: headers, body: body);
          break;
        case HttpMethod.delete:
          response = await http.delete(uri, headers: headers);
          break;
        case HttpMethod.patch:
          response = await http.patch(uri, headers: headers, body: body);
          break;
      }

      if (!mounted) return;
      setState(() {
        _sending = false;
        _responseStatus = '${response.statusCode}';
        try {
          final decoded = json.decode(response.body);
          _responseBody = const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          _responseBody = response.body;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _responseError = e.toString();
      });
    }
  }

  static String _methodLabel(HttpMethod m) {
    return switch (m) {
      HttpMethod.get => 'GET',
      HttpMethod.post => 'POST',
      HttpMethod.put => 'PUT',
      HttpMethod.delete => 'DELETE',
      HttpMethod.patch => 'PATCH',
    };
  }

  static Color _methodColor(HttpMethod m) {
    return switch (m) {
      HttpMethod.get => Colors.green,
      HttpMethod.post => Colors.blue,
      HttpMethod.put => Colors.amber,
      HttpMethod.delete => Colors.red,
      HttpMethod.patch => Colors.orange,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Tests')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSendRequestCard(theme),
              const SizedBox(height: 24),
              Text(
                'Test Runs',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (_runs.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No test runs yet.',
                          style: theme.textTheme.bodyMedium),
                    ),
                  ),
                )
              else
                ..._runs.map(
                  (run) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        run.passed ? Icons.check_circle : Icons.cancel,
                        color: run.passed ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      title: Text(run.name),
                      subtitle: Text(run.duration),
                      trailing: Chip(
                        label: Text(run.passed ? 'Passed' : 'Failed',
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: run.passed
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSendRequestCard(ThemeData theme) {
    final hasBody =
        _method == HttpMethod.post || _method == HttpMethod.put || _method == HttpMethod.patch;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Send HTTP Request',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Method', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HttpMethod.values.map((m) {
                  final selected = _method == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_methodLabel(m)),
                      selected: selected,
                      onSelected: (_) => setState(() => _method = m),
                      selectedColor: _methodColor(m).withOpacity(0.25),
                      checkmarkColor: _methodColor(m),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('URL', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: '/health or https://api.example.com/endpoint',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            if (hasBody) ...[
              const SizedBox(height: 16),
              Text('Body (JSON)', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '{\"key\": \"value\"}',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendRequest,
                icon: _sending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_sending ? 'Sending...' : 'Send Request'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_responseError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _responseError!,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_responseStatus != null && _responseBody != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text('Status: $_responseStatus'),
                    backgroundColor: _responseStatus!.startsWith('2')
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _responseBody!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestRun {
  final String name;
  final bool passed;
  final String duration;

  _TestRun(this.name, this.passed, this.duration);
}
