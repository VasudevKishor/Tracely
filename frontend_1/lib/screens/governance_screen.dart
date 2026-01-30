import 'package:flutter/material.dart';

class GovernanceScreen extends StatelessWidget {
  const GovernanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Governance Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enforce standards and compliance across your APIs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Compliance Scorecards
                  Row(
                    children: [
                      Expanded(
                        child: _buildComplianceCard(
                          'API Standards',
                          85,
                          Colors.blue,
                          '12/15 rules passed',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildComplianceCard(
                          'Security',
                          92,
                          Colors.green,
                          '23/25 checks passed',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildComplianceCard(
                          'Documentation',
                          78,
                          Colors.orange,
                          '18/22 items complete',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildComplianceCard(
                          'Performance',
                          95,
                          Colors.purple,
                          '19/20 metrics met',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Rule Sets
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Active Rule Sets',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Rule'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildRuleItem(
                          'Authentication Required',
                          'All endpoints must have authentication',
                          true,
                          '142 APIs',
                        ),
                        const SizedBox(height: 12),
                        _buildRuleItem(
                          'Response Time Limit',
                          'Maximum response time: 500ms',
                          true,
                          '138 APIs',
                        ),
                        const SizedBox(height: 12),
                        _buildRuleItem(
                          'Version Control',
                          'APIs must use semantic versioning',
                          true,
                          '142 APIs',
                        ),
                        const SizedBox(height: 12),
                        _buildRuleItem(
                          'Error Handling',
                          'Standardized error response format',
                          false,
                          '125 APIs',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Checks
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Checks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSecurityCheck(
                          'SSL/TLS Enforcement',
                          'Passed',
                          Colors.green,
                          'All endpoints use HTTPS',
                        ),
                        const SizedBox(height: 12),
                        _buildSecurityCheck(
                          'API Key Rotation',
                          'Passed',
                          Colors.green,
                          'Keys rotated every 90 days',
                        ),
                        const SizedBox(height: 12),
                        _buildSecurityCheck(
                          'Rate Limiting',
                          'Warning',
                          Colors.orange,
                          '4 endpoints exceed recommended limits',
                        ),
                        const SizedBox(height: 12),
                        _buildSecurityCheck(
                          'Input Validation',
                          'Passed',
                          Colors.green,
                          'All inputs properly sanitized',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            'Tracely',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(width: 60),
          Text(
            'Governance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade900,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(
      String title, int score, Color color, String details) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>((color is MaterialColor) ? color.shade400 : color),
                  ),
                ),
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            details,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String description, bool enabled, String coverage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled ? Colors.green.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              enabled ? Icons.check_circle : Icons.cancel,
              color: enabled ? Colors.green.shade600 : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              coverage,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCheck(
      String title, String status, Color color, String details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}