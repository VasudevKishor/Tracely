import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import 'request_studio_screen.dart';

class CreateWorkspaceScreen extends StatefulWidget {
  const CreateWorkspaceScreen({Key? key}) : super(key: key);

  @override
  State<CreateWorkspaceScreen> createState() => _CreateWorkspaceScreenState();
}

class _CreateWorkspaceScreenState extends State<CreateWorkspaceScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form data
  String _workspaceName = '';
  WorkspaceType _selectedType = WorkspaceType.internal;
  bool _isPublic = false;
  AccessType _accessType = AccessType.teamOnly;
  
  // Color scheme - Custom elegant palette
  final Color _primaryColor = const Color(0xFF7C3AED); // Vibrant purple
  final Color _secondaryColor = const Color(0xFF10B981); // Emerald green
  final Color _accentColor = const Color(0xFFF59E0B); // Amber gold
  final Color _darkColor = const Color(0xFF111827); // Dark slate
  final Color _lightColor = const Color(0xFFF9FAFB); // Light background
  final Color _cardColor = const Color(0xFFFFFFFF); // White cards
  final Color _borderColor = const Color(0xFFE5E7EB); // Subtle borders

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _createWorkspace();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _createWorkspace() async {
    if (_workspaceName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a workspace name'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);

    try {
      await workspaceProvider.createWorkspace(
        name: _workspaceName,
        type: _selectedType,
        isPublic: _isPublic,
        accessType: _accessType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Workspace "$_workspaceName" created successfully!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to RequestStudioScreen instead of just popping
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RequestStudioScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating workspace: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightColor,
      body: Column(
        children: [
          // Progress Bar
          Container(
            height: 4,
            color: _borderColor,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * (_currentStep + 1) / 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _accentColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: _cardColor,
              border: Border(bottom: BorderSide(color: _borderColor)),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: _darkColor),
                  splashRadius: 20,
                ),
                const SizedBox(width: 16),
                
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Workspace',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _darkColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentStep == 0 
                          ? 'Set up your new workspace'
                          : _currentStep == 1
                            ? 'Configure visibility settings'
                            : 'Finalize and create',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Step indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Step ${_currentStep + 1} of 3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 1: Basic Information
                _buildStep1(),
                
                // Step 2: Visibility & Access
                _buildStep2(),
                
                // Step 3: Confirmation
                _buildStep3(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: _cardColor,
              border: Border(top: BorderSide(color: _borderColor)),
            ),
            child: Row(
              children: [
                // Back button
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _previousStep,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 18),
                        const SizedBox(width: 8),
                        const Text('Back'),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // Next/Create button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _nextStep,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        child: Row(
                          children: [
                            Text(
                              _currentStep == 2 ? 'Create Workspace' : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentStep == 2 ? Icons.check : Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              Text(
                'Workspace Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _darkColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Give your workspace a name and choose its purpose',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Name Input
              _buildInputSection(
                icon: Icons.badge_outlined,
                title: 'Workspace Name',
                hintText: 'Enter a descriptive name',
                child: TextField(
                  onChanged: (value) => setState(() => _workspaceName = value),
                  decoration: InputDecoration(
                    hintText: 'e.g., Development, Production, Marketing APIs',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: _darkColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Type Selection
              _buildInputSection(
                icon: Icons.category_outlined,
                title: 'Workspace Type',
                hintText: 'Choose how this workspace will be used',
                child: Column(
                  children: [
                    // Internal Option
                    _buildTypeOption(
                      title: 'Internal Team',
                      description: 'Build and test APIs within your organization',
                      icon: Icons.groups_outlined,
                      isSelected: _selectedType == WorkspaceType.internal,
                      color: _primaryColor,
                      onTap: () => setState(() => _selectedType = WorkspaceType.internal),
                    ),
                    const SizedBox(height: 16),

                    // Partner Option
                    _buildTypeOption(
                      title: 'Partner Collaboration',
                      description: 'Share APIs securely with external partners',
                      icon: Icons.handshake_outlined,
                      isSelected: _selectedType == WorkspaceType.partner,
                      color: _secondaryColor,
                      onTap: () => setState(() => _selectedType = WorkspaceType.partner),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Visibility & Access',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure who can access this workspace',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Public/Private Toggle
          _buildInputSection(
            icon: Icons.public_outlined,
            title: 'Public Visibility',
            hintText: 'Make this workspace accessible to everyone',
            child: Container(
              decoration: BoxDecoration(
                color: _lightColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: SwitchListTile(
                title: Text(
                  'Public Workspace',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _darkColor,
                  ),
                ),
                subtitle: Text(
                  'Anyone with the link can view your APIs',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: _primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Access Control
          _buildInputSection(
            icon: Icons.lock_outlined,
            title: 'Access Management',
            hintText: 'Control who can join this workspace',
            child: Column(
              children: [
                // Team Only Option
                _buildAccessOption(
                  title: 'Team Members Only',
                  description: 'Only members of your organization can join',
                  icon: Icons.business_outlined,
                  isSelected: _accessType == AccessType.teamOnly,
                  color: _primaryColor,
                  onTap: () => setState(() => _accessType = AccessType.teamOnly),
                ),
                const SizedBox(height: 16),
                
                // Invite Only Option
                _buildAccessOption(
                  title: 'Invitation Required',
                  description: 'Only people you invite can join',
                  icon: Icons.mail_outlined,
                  isSelected: _accessType == AccessType.inviteOnly,
                  color: _accentColor,
                  onTap: () => setState(() => _accessType = AccessType.inviteOnly),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preview Card
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isPublic
                      ? 'Your workspace will be publicly accessible. Anyone can view your APIs.'
                      : 'Your workspace is private. Only authorized members can access it.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _darkColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confirmation Title
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              'Ready to Create!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _darkColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          Center(
            child: Text(
              'Review your workspace configuration',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Workspace Name
                _buildSummaryItem(
                  label: 'Workspace Name',
                  value: _workspaceName.isNotEmpty ? _workspaceName : 'Untitled',
                  icon: Icons.badge_outlined,
                  color: _primaryColor,
                ),
                const Divider(height: 32, color: Color(0xFFF3F4F6)),
                
                // Type
                _buildSummaryItem(
                  label: 'Type',
                  value: _selectedType == WorkspaceType.internal ? 'Internal Team' : 'Partner Collaboration',
                  icon: Icons.category_outlined,
                  color: _secondaryColor,
                ),
                const Divider(height: 32, color: Color(0xFFF3F4F6)),
                
                // Visibility
                _buildSummaryItem(
                  label: 'Visibility',
                  value: _isPublic ? 'Public' : 'Private',
                  icon: Icons.visibility_outlined,
                  color: _accentColor,
                ),
                const Divider(height: 32, color: Color(0xFFF3F4F6)),
                
                // Access
                _buildSummaryItem(
                  label: 'Access Control',
                  value: _accessType == AccessType.teamOnly ? 'Team Members Only' : 'Invitation Required',
                  icon: Icons.lock_outlined,
                  color: _primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Features Preview
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _lightColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What you\'ll get:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _darkColor,
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildFeaturePreview(
                  title: 'API Documentation Hub',
                  description: 'Centralized space for all your API documentation and testing',
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                
                _buildFeaturePreview(
                  title: 'Team Collaboration',
                  description: 'Real-time editing, comments, and version control',
                  icon: Icons.group_work_outlined,
                ),
                const SizedBox(height: 16),
                
                _buildFeaturePreview(
                  title: 'Advanced Analytics',
                  description: 'Track API usage, performance, and team activity',
                  icon: Icons.analytics_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Final Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _secondaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: _secondaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can always change these settings later from workspace settings.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _darkColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection({
    required IconData icon,
    required String title,
    required String hintText,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hintText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : _borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withOpacity(0.05) : _cardColor,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _darkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : _borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withOpacity(0.05) : _cardColor,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _darkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<AccessType>(
                value: _accessType == AccessType.teamOnly ? AccessType.teamOnly : AccessType.inviteOnly,
                groupValue: _accessType,
                onChanged: (_) => onTap(),
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePreview({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: _primaryColor,
          size: 24,
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
                  color: _darkColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: _secondaryColor,
          size: 20,
        ),
      ],
    );
  }
}

