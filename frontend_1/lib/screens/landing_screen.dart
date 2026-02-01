import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/footer_widget.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If already logged in, show a different message
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(authProvider),
              _buildHeroSection(authProvider),
              _buildWhatIsTracely(),
              _buildFeatureCards(),
              const SizedBox(height: 80),
              _buildCredibilitySection(),
              const SizedBox(height: 80),
              _buildCTASection(authProvider),
              const SizedBox(height: 60),
              const FooterWidget(),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Tracely',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 60),
          _buildNavLink('Platform'),
          _buildNavLink('Teams'),
          _buildNavLink('Network'),
          _buildNavLink('Resources'),
          const Spacer(),
          Container(
            width: 200,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  'Search Tracely',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          if (authProvider.isAuthenticated) ...[
            Text(
              'Welcome, ${authProvider.user?['name'] ?? 'User'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade900,
              child: Text(
                authProvider.user?['name']?[0]?.toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ] else ...[
            _buildIconButton(Icons.person_add_outlined),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade900,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (authProvider.isAuthenticated) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'You\'re logged in!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'APIs, Without the Chaos.',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    height: 1.1,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tracely helps teams design, test, govern, and monitor APIs in one collaborative workspace.',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                    height: 1.6,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 40),
                if (!authProvider.isAuthenticated) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Get started free',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Go to Dashboard →'),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Download desktop app',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildOSIcon(Icons.window),
                    const SizedBox(width: 8),
                    _buildOSIcon(Icons.apple),
                    const SizedBox(width: 8),
                    _buildOSIcon(Icons.android),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 4,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  Icons.api,
                  size: 120,
                  color: Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Keep all your existing widget methods...
  Widget _buildNavLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, size: 18, color: Colors.grey.shade700),
    );
  }

  Widget _buildOSIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: Colors.grey.shade600),
    );
  }

  // ... keep all other methods (buildWhatIsTracely, buildFeatureCards, etc.)
  
  Widget _buildWhatIsTracely() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What is Tracely?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tracely is an end-to-end API lifecycle platform that unifies design, testing, documentation, monitoring, and governance.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildFeatureCard(
                  'API Toolkit',
                  'Build, test, simulate, and document APIs with powerful integrated tools.',
                  400,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildFeatureCard(
                  'Central Repository',
                  'Organize APIs, schemas, and versions in a single source of truth.',
                  400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildFeatureCard(
                  'Team Workspaces',
                  'Shared environments and role-based access for seamless collaboration.',
                  300,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildFeatureCard(
                  'Governance Layer',
                  'Enforce standards, rules, and compliance across your entire API landscape.',
                  300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredibilitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 80),
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            'Built for Scalable API Teams',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Trusted by modern development teams to manage mission-critical APIs at scale.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      child: Column(
        children: [
          Text(
            authProvider.isAuthenticated
                ? 'Continue your journey'
                : 'Start building with Tracely',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          if (!authProvider.isAuthenticated) ...[
            const SizedBox(height: 32),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Center(
                      child: Text(
                        'Get started',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}