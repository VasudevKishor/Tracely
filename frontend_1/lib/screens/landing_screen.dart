import 'package:flutter/material.dart';
import '../widgets/footer_widget.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
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
                _buildIconButton(Icons.person_add_outlined),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade900,
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),

          // Hero Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
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
          ),

          // What is Tracely Section
          Container(
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
                  'Tracely is an end-to-end API lifecycle platform that unifies design, testing, documentation, monitoring, and governance. Teams collaborate seamlessly across the entire API journey—from initial concept to production monitoring—with tools that adapt to your workflow, not the other way around.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // Feature Cards - Asymmetrical Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildFeatureCard(
                        'API Toolkit',
                        'Build, test, simulate, and document APIs with powerful integrated tools. From request builders to mock servers, everything you need in one place.',
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
                        'Enforce standards, rules, and compliance across your entire API landscape. Automated checks ensure quality and security at every stage.',
                        300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),

          // Credibility Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 80),
            padding: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              children: [
                Text(
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
                const SizedBox(height: 32),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Top API Platform – 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Read more',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),

          // CTA Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
            child: Column(
              children: [
                Text(
                  'Start building with Tracely',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
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
            ),
          ),

          const SizedBox(height: 60),

          // Footer
          const FooterWidget(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

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
}