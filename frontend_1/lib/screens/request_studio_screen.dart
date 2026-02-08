import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/workspace_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/request_provider.dart';

class RequestStudioScreen extends StatefulWidget {
  const RequestStudioScreen({Key? key}) : super(key: key);

  @override
  State<RequestStudioScreen> createState() => _RequestStudioScreenState();
}

class _RequestStudioScreenState extends State<RequestStudioScreen>
    with SingleTickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _floatingButtonAnimationController;
  late Animation<double> _floatingButtonScaleAnimation;

  // UI State
  String selectedMethod = 'GET';
  int selectedTab = 0;
  double responseHeight = 300;
  String responseView = 'JSON';
  String selectedEnvironment = 'No Environment';
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // Query Parameters
  final List<Map<String, dynamic>> _queryParams = [
    {'key': '', 'value': '', 'description': '', 'enabled': true}
  ];
  
  // Headers
  final List<Map<String, dynamic>> _headers = [
    {'key': 'Content-Type', 'value': 'application/json', 'description': '', 'enabled': true}
  ];
  
  // Body controller
  final TextEditingController _bodyController = TextEditingController();
  
  // Auth
  String _authType = 'No Auth';
  
  // New UI States
  bool _isSidebarCollapsed = false;
  bool _isDarkMode = false;
  bool _isResponseMaximized = false;
  bool _showQuickSettings = false;
  double _sidebarWidth = 240;
  final double _minSidebarWidth = 180;
  final double _maxSidebarWidth = 320;
  
  // Hover States
  int _hoveredNavItem = -1;
  int _hoveredCollectionItem = -1;
  String _hoveredResponseTab = '';
  
  // Color Scheme
  final Color _primaryColor = const Color(0xFF6366F1);
  final Color _secondaryColor = const Color(0xFF8B5CF6);
  final Color _accentColor = const Color(0xFF10B981);
  final Color _dangerColor = const Color(0xFFEF4444);
  final Color _warningColor = const Color(0xFFF59E0B);
  
  // Controllers for dynamic fields
  final List<TextEditingController> _queryParamKeyControllers = [];
  final List<TextEditingController> _queryParamValueControllers = [];
  final List<TextEditingController> _queryParamDescControllers = [];
  final List<TextEditingController> _headerKeyControllers = [];
  final List<TextEditingController> _headerValueControllers = [];
  final List<TextEditingController> _headerDescControllers = [];
  
  final List<String> methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
  final List<String> tabs = [
    'Parameters',
    'Body',
    'Headers',
    'Authorization',
    'Pre-request Script',
    'Post-request Script',
    'Variables'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _floatingButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _floatingButtonScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(_floatingButtonAnimationController);
    
    // Initialize controllers with default values
    _urlController.text = 'https://jsonplaceholder.typicode.com/todos/1';
    _bodyController.text = '{\n  "title": "New Todo",\n  "completed": false\n}';
    
    // Initialize dynamic field controllers
    _initializeControllers();
    
    // Start animations
    _floatingButtonAnimationController.repeat(reverse: true);
  }

  void _initializeControllers() {
    // Initialize query param controllers
    for (var param in _queryParams) {
      _queryParamKeyControllers.add(TextEditingController(text: param['key']));
      _queryParamValueControllers.add(TextEditingController(text: param['value']));
      _queryParamDescControllers.add(TextEditingController(text: param['description']));
    }
    
    // Initialize header controllers
    for (var header in _headers) {
      _headerKeyControllers.add(TextEditingController(text: header['key']));
      _headerValueControllers.add(TextEditingController(text: header['value']));
      _headerDescControllers.add(TextEditingController(text: header['description']));
    }
  }

  @override
  void dispose() {
    _floatingButtonAnimationController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    _bodyController.dispose();
    
    // Dispose all dynamic field controllers
    for (var controller in _queryParamKeyControllers) {
      controller.dispose();
    }
    for (var controller in _queryParamValueControllers) {
      controller.dispose();
    }
    for (var controller in _queryParamDescControllers) {
      controller.dispose();
    }
    for (var controller in _headerKeyControllers) {
      controller.dispose();
    }
    for (var controller in _headerValueControllers) {
      controller.dispose();
    }
    for (var controller in _headerDescControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _addQueryParam() {
    setState(() {
      _queryParams.add({'key': '', 'value': '', 'description': '', 'enabled': true});
      _queryParamKeyControllers.add(TextEditingController());
      _queryParamValueControllers.add(TextEditingController());
      _queryParamDescControllers.add(TextEditingController());
    });
  }

  void _removeQueryParam(int index) {
    setState(() {
      _queryParams.removeAt(index);
      _queryParamKeyControllers[index].dispose();
      _queryParamValueControllers[index].dispose();
      _queryParamDescControllers[index].dispose();
      _queryParamKeyControllers.removeAt(index);
      _queryParamValueControllers.removeAt(index);
      _queryParamDescControllers.removeAt(index);
    });
  }

  void _addHeader() {
    setState(() {
      _headers.add({'key': '', 'value': '', 'description': '', 'enabled': true});
      _headerKeyControllers.add(TextEditingController());
      _headerValueControllers.add(TextEditingController());
      _headerDescControllers.add(TextEditingController());
    });
  }

  void _removeHeader(int index) {
    setState(() {
      _headers.removeAt(index);
      _headerKeyControllers[index].dispose();
      _headerValueControllers[index].dispose();
      _headerDescControllers[index].dispose();
      _headerKeyControllers.removeAt(index);
      _headerValueControllers.removeAt(index);
      _headerDescControllers.removeAt(index);
    });
  }

  Future<void> _sendRequest() async {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final collectionProvider = Provider.of<CollectionProvider>(context, listen: false);
    
    // Update query params from controllers
    for (int i = 0; i < _queryParams.length; i++) {
      _queryParams[i]['key'] = _queryParamKeyControllers[i].text;
      _queryParams[i]['value'] = _queryParamValueControllers[i].text;
      _queryParams[i]['description'] = _queryParamDescControllers[i].text;
    }
    
    // Update headers from controllers
    for (int i = 0; i < _headers.length; i++) {
      _headers[i]['key'] = _headerKeyControllers[i].text;
      _headers[i]['value'] = _headerValueControllers[i].text;
      _headers[i]['description'] = _headerDescControllers[i].text;
    }
    
    // Build query parameters
    Map<String, dynamic> queryParams = {};
    for (var param in _queryParams) {
      final key = (param['key'] as String).trim();
      final value = (param['value'] as String).trim();
      if (key.isNotEmpty && value.isNotEmpty && param['enabled'] == true) {
        queryParams[key] = value;
      }
    }
    
    // Build headers
    Map<String, String> headers = {};
    for (var header in _headers) {
      final key = (header['key'] as String).trim();
      final value = (header['value'] as String).trim();
      if (key.isNotEmpty && value.isNotEmpty && header['enabled'] == true) {
        headers[key] = value;
      }
    }
    
    // Parse body if provided
    Map<String, dynamic>? body;
    if (selectedTab == 1 && _bodyController.text.trim().isNotEmpty) {
      try {
        body = json.decode(_bodyController.text);
      } catch (e) {
        body = {'raw': _bodyController.text};
      }
    }
    
    try {
      await requestProvider.executeRequest(
        method: selectedMethod,
        url: _urlController.text.trim(),
        body: body,
        headers: headers,
        queryParams: queryParams,
        workspaceId: workspaceProvider.selectedWorkspaceId,
        collectionId: collectionProvider.selectedCollection?['id'],
      );
      
      setState(() {
        responseView = 'JSON';
      });
      
      // Show success notification
      _showAnimatedSnackBar(
        'Request sent successfully!',
        _accentColor,
        Icons.check_circle,
      );
      
    } catch (e) {
      _showAnimatedSnackBar(
        'Error: ${e.toString()}',
        _dangerColor,
        Icons.error,
      );
    }
  }

  void _showAnimatedSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  String _formatJson(dynamic data) {
    try {
      if (data is Map || data is List) {
        return JsonEncoder.withIndent('  ').convert(data);
      } else if (data is String) {
        try {
          final parsed = json.decode(data);
          return JsonEncoder.withIndent('  ').convert(parsed);
        } catch (_) {
          return data;
        }
      }
      return data.toString();
    } catch (e) {
      return 'Error formatting JSON: $e\n\nRaw data: ${data.toString()}';
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
      _sidebarWidth = _isSidebarCollapsed ? _minSidebarWidth : 240;
    });
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _toggleResponsePanel() {
    setState(() {
      _isResponseMaximized = !_isResponseMaximized;
      responseHeight = _isResponseMaximized 
          ? MediaQuery.of(context).size.height * 0.7 
          : 300;
    });
  }

  void _toggleQuickSettings() {
    setState(() {
      _showQuickSettings = !_showQuickSettings;
    });
  }

  void _clearAllParams() {
    showDialog(
      context: context,
      builder: (context) => _buildConfirmationDialog(
        'Clear All Parameters',
        'Are you sure you want to clear all query parameters?',
        () {
          setState(() {
            _queryParams.clear();
            _queryParams.add({'key': '', 'value': '', 'description': '', 'enabled': true});
            
            for (var controller in _queryParamKeyControllers) {
              controller.dispose();
            }
            for (var controller in _queryParamValueControllers) {
              controller.dispose();
            }
            for (var controller in _queryParamDescControllers) {
              controller.dispose();
            }
            
            _queryParamKeyControllers.clear();
            _queryParamValueControllers.clear();
            _queryParamDescControllers.clear();
            
            _queryParamKeyControllers.add(TextEditingController());
            _queryParamValueControllers.add(TextEditingController());
            _queryParamDescControllers.add(TextEditingController());
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _clearAllHeaders() {
    showDialog(
      context: context,
      builder: (context) => _buildConfirmationDialog(
        'Clear All Headers',
        'Are you sure you want to clear all headers?',
        () {
          setState(() {
            _headers.clear();
            _headers.add({'key': 'Content-Type', 'value': 'application/json', 'description': '', 'enabled': true});
            
            for (var controller in _headerKeyControllers) {
              controller.dispose();
            }
            for (var controller in _headerValueControllers) {
              controller.dispose();
            }
            for (var controller in _headerDescControllers) {
              controller.dispose();
            }
            
            _headerKeyControllers.clear();
            _headerValueControllers.clear();
            _headerDescControllers.clear();
            
            _headerKeyControllers.add(TextEditingController(text: 'Content-Type'));
            _headerValueControllers.add(TextEditingController(text: 'application/json'));
            _headerDescControllers.add(TextEditingController());
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildConfirmationDialog(String title, String content, VoidCallback onConfirm) {
    return Dialog(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 24,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _warningColor,
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              textAlign: TextAlign.center,  // This should work for Text widget
              style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dangerColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WorkspaceProvider, CollectionProvider, RequestProvider>(
      builder: (context, workspaceProvider, collectionProvider, requestProvider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: _isDarkMode 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[900]!,
                      Colors.grey[850]!,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                  ),
          ),
          child: Column(
            children: [
              // Modern Top Navigation Bar
              _buildModernTopBar(workspaceProvider),
              
              // Main Content Area with floating action button
              Expanded(
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resizable Sidebar
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _sidebarWidth = (_sidebarWidth + details.delta.dx)
                                    .clamp(_minSidebarWidth, _maxSidebarWidth);
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _sidebarWidth,
                              decoration: BoxDecoration(
                                color: _isDarkMode ? Colors.grey[900] : Colors.white,
                                border: Border(
                                  right: BorderSide(
                                    color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(4, 0),
                                  ),
                                ],
                              ),
                              child: _buildModernSidebar(collectionProvider),
                            ),
                          ),
                        ),
                        
                        // Main Request Area
                        Expanded(
                          child: Container(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                // Modern Request Header
                                _buildModernRequestHeader(requestProvider),
                                
                                // Tab Content Area with glass morphism
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: _isDarkMode 
                                          ? Colors.grey[900]!.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 30,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: _buildModernTabContent(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Floating Action Button for quick actions
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: ScaleTransition(
                        scale: _floatingButtonScaleAnimation,
                        child: FloatingActionButton.extended(
                          onPressed: _sendRequest,
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          icon: requestProvider.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: const Text(
                            'Send Request',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Quick Settings Panel
                    if (_showQuickSettings)
                      Positioned(
                        left: _sidebarWidth + 24,
                        top: 24,
                        child: _buildQuickSettingsPanel(),
                      ),
                  ],
                ),
              ),
              
              // Modern Response Panel
              _buildModernResponsePanel(requestProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernTopBar(WorkspaceProvider workspaceProvider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Logo
          MouseRegion(
            onEnter: (_) => _floatingButtonAnimationController.forward(),
            onExit: (_) => _floatingButtonAnimationController.reverse(),
            child: ScaleTransition(
              scale: _floatingButtonScaleAnimation,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TRACELY',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _isDarkMode ? Colors.white : Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 32),
          
          // Modern Navigation Items with hover effects
          Expanded(
            child: Row(
              children: [
                _buildModernNavItem('Dashboard', Icons.dashboard_rounded, 0, false),
                _buildModernNavItem('Workspaces', Icons.work_rounded, 1, false),
                _buildModernNavItem('Studio', Icons.api_rounded, 2, true),
                _buildModernNavItem('Collections', Icons.folder_rounded, 3, false),
                _buildModernNavItem('Environments', Icons.settings_rounded, 4, false),
                _buildModernNavItem('History', Icons.history_rounded, 5, false),
              ],
            ),
          ),
          
          // Modern User Profile & Settings
          Row(
            children: [
              // Theme Toggle
              IconButton(
                onPressed: _toggleDarkMode,
                icon: Icon(
                  _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: _isDarkMode ? Colors.amber : Colors.grey[600],
                ),
                tooltip: 'Toggle Theme',
              ),
              
              const SizedBox(width: 8),
              
              // Quick Settings Toggle
              IconButton(
                onPressed: _toggleQuickSettings,
                icon: Icon(
                  _showQuickSettings ? Icons.settings_backup_restore : Icons.settings,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
                tooltip: 'Quick Settings',
              ),
              
              const SizedBox(width: 8),
              
              // Workspace Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 16,
                      color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      workspaceProvider.selectedWorkspaceId ?? 'Select Workspace',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Modern User Avatar with menu
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildProfileMenu(),
                  );
                },
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernNavItem(String label, IconData icon, int index, bool isActive) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNavItem = index),
      onExit: (_) => setState(() => _hoveredNavItem = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _primaryColor.withOpacity(0.1)
              : _hoveredNavItem == index
                  ? _isDarkMode ? Colors.grey[800] : Colors.grey[100]
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: _primaryColor.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? _primaryColor
                  : _hoveredNavItem == index
                      ? _primaryColor
                      : _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? _primaryColor
                    : _hoveredNavItem == index
                        ? _primaryColor
                        : _isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernSidebar(CollectionProvider collectionProvider) {
    return Column(
      children: [
        // Modern Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search collections...',
                hintStyle: TextStyle(
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  fontSize: 12,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        
        // Quick Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSidebarActionButton('New Request', Icons.add_rounded, _primaryColor),
              _buildSidebarActionButton('Import', Icons.upload_rounded, _secondaryColor),
              _buildSidebarActionButton('Export', Icons.download_rounded, _accentColor),
              _buildSidebarActionButton('Settings', Icons.settings_rounded, _warningColor),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Sample Section
        _buildModernSectionHeader('Quick Start'),
        _buildModernCollectionItem(
          name: 'Sample API',
          method: 'GET',
          icon: Icons.rocket_launch_rounded,
          color: _accentColor,
        ),
        
        // Collections Section
        _buildModernSectionHeader('Collections'),
        if (collectionProvider.collections.isEmpty)
          _buildModernEmptyState('No collections yet')
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: collectionProvider.collections.length,
              itemBuilder: (context, index) {
                final collection = collectionProvider.collections[index];
                final colors = [_primaryColor, _secondaryColor, _accentColor, _warningColor];
                final color = colors[index % colors.length];
                
                return _buildModernCollectionItem(
                  name: collection['name'] ?? 'Unnamed',
                  method: 'Collection',
                  icon: Icons.folder_rounded,
                  color: color,
                  isHovered: _hoveredCollectionItem == index,
                  onHover: (isHovered) {
                    setState(() {
                      _hoveredCollectionItem = isHovered ? index : -1;
                    });
                  },
                );
              },
            ),
          ),
        
        // Recent Activity Section
        _buildModernSectionHeader('Recent Activity'),
        _buildRecentActivityItem('GET /users', '2 min ago', Icons.check_circle, _accentColor),
        _buildRecentActivityItem('POST /posts', '5 min ago', Icons.timer, _warningColor),
        _buildRecentActivityItem('PUT /todos', '1 hour ago', Icons.error, _dangerColor),
      ],
    );
  }

  Widget _buildSidebarActionButton(String label, IconData icon, Color color) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.add_rounded,
            size: 14,
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
          ),
        ],
      ),
    );
  }

  Widget _buildModernCollectionItem({
    required String name,
    required String method,
    required IconData icon,
    required Color color,
    bool isHovered = false,
    Function(bool)? onHover,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHovered
              ? color.withOpacity(0.1)
              : _isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovered ? color.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 48,
            color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(String title, String time, IconData icon, Color color) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          fontSize: 9,
          color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildModernRequestHeader(RequestProvider requestProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[900]!.withOpacity(0.8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Request Title with Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getMethodColor(selectedMethod).withOpacity(0.1), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getMethodColor(selectedMethod).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMethodColor(selectedMethod),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedMethod,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Untitled Request',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Method Selector
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: selectedMethod,
                underline: const SizedBox(),
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: _getMethodColor(selectedMethod),
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _getMethodColor(selectedMethod),
                ),
                items: methods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getMethodColor(method),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(method),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMethod = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // URL Input with advanced features
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'Enter URL (e.g., https://api.example.com)',
                          hintStyle: TextStyle(
                            color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    // Quick URL actions
                    PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy URL'),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Text('Clear URL'),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Text('URL History'),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Environment Selector
            Container(
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: selectedEnvironment,
                underline: const SizedBox(),
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                items: [
                  'No Environment',
                  'Development',
                  'Staging',
                  'Production',
                  'Testing',
                ].map((env) {
                  return DropdownMenuItem(
                    value: env,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getEnvironmentColor(env),
                          ),
                        ),
                        Text(env),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEnvironment = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Action Buttons
            _buildActionButton(
              'Save',
              Icons.save_rounded,
              _secondaryColor,
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              'Copy',
              Icons.copy_rounded,
              _accentColor,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, {VoidCallback? onPressed}) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabContent() {
    return Column(
      children: [
        // Tab Navigation with indicators
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final isSelected = selectedTab == index;
              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredResponseTab = tabs[index]),
                onExit: (_) => setState(() => _hoveredResponseTab = ''),
                child: InkWell(
                  onTap: () => setState(() => selectedTab = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? _primaryColor : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? _primaryColor
                                : _hoveredResponseTab == tabs[index]
                                    ? _primaryColor
                                    : _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Tab Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildModernTabContentByIndex(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTabContentByIndex() {
    switch (selectedTab) {
      case 0:
        return _buildModernKeyValueTable(
          items: _queryParams,
          keyControllers: _queryParamKeyControllers,
          valueControllers: _queryParamValueControllers,
          descControllers: _queryParamDescControllers,
          onAdd: _addQueryParam,
          onRemove: _removeQueryParam,
          title: 'Query Parameters',
          onClearAll: _clearAllParams,
        );
      case 1:
        return _buildModernBodyContent();
      case 2:
        return _buildModernKeyValueTable(
          items: _headers,
          keyControllers: _headerKeyControllers,
          valueControllers: _headerValueControllers,
          descControllers: _headerDescControllers,
          onAdd: _addHeader,
          onRemove: _removeHeader,
          title: 'Headers',
          onClearAll: _clearAllHeaders,
        );
      case 3:
        return _buildModernAuthContent();
      case 4:
        return _buildModernScriptContent('Pre-request Script');
      case 5:
        return _buildModernScriptContent('Post-request Script');
      case 6:
        return _buildModernVariablesContent();
      default:
        return Container();
    }
  }

  Widget _buildModernKeyValueTable({
    required List<Map<String, dynamic>> items,
    required List<TextEditingController> keyControllers,
    required List<TextEditingController> valueControllers,
    required List<TextEditingController> descControllers,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required String title,
    VoidCallback? onClearAll,
  }) {
    return Column(
      children: [
        // Enhanced Header with actions
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: items.isNotEmpty && items.every((item) => item['enabled'] == true),
                    onChanged: items.isEmpty ? null : (val) {
                      setState(() {
                        for (var item in items) {
                          item['enabled'] = val;
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    fillColor: MaterialStateProperty.all(_primaryColor),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: Text(
                  'KEY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'VALUE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: onClearAll,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11,
                      color: _dangerColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Enhanced Rows with animations
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: index.isEven
                      ? _isDarkMode ? Colors.grey[900] : Colors.white
                      : _isDarkMode ? Colors.grey[850] : Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(
                      color: _isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                    ),
                  ),
                ),
                child: _buildModernKeyValueRow(
                  item: items[index],
                  keyController: keyControllers[index],
                  valueController: valueControllers[index],
                  descController: descControllers[index],
                  index: index,
                  onRemove: onRemove,
                ),
              );
            },
          ),
        ),

        // Enhanced Add Button
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[900] : Colors.white,
            border: Border(
              top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Parameter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernKeyValueRow({
    required Map<String, dynamic> item,
    required TextEditingController keyController,
    required TextEditingController valueController,
    required TextEditingController descController,
    required int index,
    required Function(int) onRemove,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: item['enabled'] ?? true,
                onChanged: (val) {
                  setState(() {
                    item['enabled'] = val;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                fillColor: MaterialStateProperty.all(_primaryColor),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: keyController,
              onChanged: (value) => item['key'] = value,
              decoration: InputDecoration(
                hintText: 'Enter key',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 11,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: valueController,
              onChanged: (value) => item['value'] = value,
              decoration: InputDecoration(
                hintText: 'Enter value',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 11,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: descController,
                    onChanged: (value) => item['description'] = value,
                    decoration: InputDecoration(
                      hintText: 'Optional description',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ),
                if (_queryParams.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_rounded, size: 16, color: _dangerColor),
                    onPressed: () => onRemove(index),
                    splashRadius: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBodyContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body Format Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  'Body Format:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildBodyFormatChip('JSON', true),
                    _buildBodyFormatChip('Text', false),
                    _buildBodyFormatChip('XML', false),
                    _buildBodyFormatChip('HTML', false),
                    _buildBodyFormatChip('JavaScript', false),
                    _buildBodyFormatChip('GraphQL', false),
                  ],
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'prettify', child: Text('Prettify JSON')),
                    const PopupMenuItem(value: 'minify', child: Text('Minify JSON')),
                    const PopupMenuItem(value: 'validate', child: Text('Validate JSON')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Enhanced Code Editor
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                ),
                color: _isDarkMode ? Colors.grey[900] : Colors.white,
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _bodyController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText: '{\n  "key": "value"\n}',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.grey[100] : Colors.black,
                    ),
                  ),
                  
                  // Line numbers
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
                        border: Border(
                          right: BorderSide(
                            color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(top: 16, right: 8),
                      child: ListView.builder(
                        itemCount: 50,
                        itemBuilder: (context, index) {
                          return Text(
                            '${index + 1}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                            ),
                          );
                        },
                      ),
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

  Widget _buildBodyFormatChip(String label, bool isActive) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : _isDarkMode ? Colors.grey[300] : Colors.grey[600],
        ),
      ),
      selected: isActive,
      onSelected: (selected) {},
      backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
      selectedColor: _primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildModernAuthContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authorization',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure authentication for your request',
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Auth Type Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildAuthCard('No Auth', Icons.lock_open_rounded, Colors.grey, true),
              _buildAuthCard('Bearer Token', Icons.vpn_key_rounded, _accentColor, false),
              _buildAuthCard('API Key', Icons.key_rounded, _warningColor, false),
              _buildAuthCard('Basic Auth', Icons.security_rounded, _primaryColor, false),
              _buildAuthCard('OAuth 2.0', Icons.verified_user_rounded, _secondaryColor, false),
              _buildAuthCard('AWS Signature', Icons.cloud_rounded, _dangerColor, false),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Auth Configuration Area
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Authentication',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This request will be sent without any authentication headers.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(String title, IconData icon, Color color, bool isSelected) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _authType = title),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              if (isSelected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernScriptContent(String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code_rounded,
                size: 20,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'examples', child: Text('View Examples')),
                  const PopupMenuItem(value: 'snippets', child: Text('Code Snippets')),
                  const PopupMenuItem(value: 'docs', child: Text('Documentation')),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_rounded,
                    size: 16,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                ),
                color: _isDarkMode ? Colors.grey[900] : Colors.white,
              ),
              child: Stack(
                children: [
                  TextField(
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText: '// $title\n// Write your script here\nconsole.log("Request starting...");',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(48, 16, 16, 16),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.grey[100] : Colors.black,
                    ),
                  ),
                  
                  // Line numbers with gutter
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
                        border: Border(
                          right: BorderSide(
                            color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(top: 16, right: 8),
                      child: ListView.builder(
                        itemCount: 50,
                        itemBuilder: (context, index) {
                          return Text(
                            '${index + 1}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                            ),
                          );
                        },
                      ),
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

  Widget _buildModernVariablesContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environment Variables',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage variables for different environments',
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Environment Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.layers_rounded,
                  size: 18,
                  color: _primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedEnvironment,
                    underline: const SizedBox(),
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    items: [
                      'No Environment',
                      'Development',
                      'Staging',
                      'Production',
                    ].map((env) {
                      return DropdownMenuItem(
                        value: env,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getEnvironmentColor(env),
                              ),
                            ),
                            Text(env),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEnvironment = value!;
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.add_circle_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Variables Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
                color: _isDarkMode ? Colors.grey[900] : Colors.white,
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(
                          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: Text(
                            'VARIABLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'VALUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'TYPE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table Body
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final variables = [
                          {'name': 'API_URL', 'value': 'https://api.dev.com', 'type': 'String'},
                          {'name': 'API_KEY', 'value': 'sk_test_12345', 'type': 'Secret'},
                          {'name': 'TIMEOUT', 'value': '30', 'type': 'Number'},
                          {'name': 'ENVIRONMENT', 'value': 'development', 'type': 'String'},
                          {'name': 'DEBUG', 'value': 'true', 'type': 'Boolean'},
                        ];
                        final variable = variables[index];
                        
                        return Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: Text(
                                  variable['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  variable['type'] == 'Secret' ? '••••••••' : variable['value']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                              Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getVariableTypeColor(variable['type']!).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  variable['type']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getVariableTypeColor(variable['type']!),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Add Variable Button
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Add New Variable',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildQuickSettingsPanel() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900]!.withOpacity(0.9) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleQuickSettings,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickSettingItem('Auto-save requests', true, Icons.save_rounded),
          _buildQuickSettingItem('Syntax highlighting', true, Icons.code_rounded),
          _buildQuickSettingItem('Request timeout (30s)', false, Icons.timer_rounded),
          _buildQuickSettingItem('Follow redirects', true, Icons.directions_rounded),
          _buildQuickSettingItem('SSL verification', true, Icons.security_rounded),
          const SizedBox(height: 24),
          Text(
            'Response Settings',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildQuickSettingItem('Pretty print JSON', true, Icons.format_indent_increase_rounded),
          _buildQuickSettingItem('Wrap long lines', false, Icons.wrap_text_rounded),
        ],
      ),
    );
  }

  Widget _buildQuickSettingItem(String label, bool value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (val) {},
            activeColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildModernResponsePanel(RequestProvider requestProvider) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            responseHeight = (responseHeight - details.delta.dy)
                .clamp(50.0, MediaQuery.of(context).size.height * 0.7);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: responseHeight,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[900] : Colors.white,
            border: Border(
              top: BorderSide(
                color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Response Header with Controls
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[900] : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Response Status
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_circle_right_rounded,
                          size: 20,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Response',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (requestProvider.lastResponse != null) ...[
                          _buildResponseBadge(
                            '${requestProvider.lastResponse!['status'] ?? 0}',
                            _getStatusColor(requestProvider.lastResponse!['status'] ?? 0),
                          ),
                          const SizedBox(width: 8),
                          _buildResponseBadge(
                            '${DateTime.now().difference(DateTime.parse(requestProvider.lastResponse!['time'] ?? DateTime.now().toIso8601String())).inMilliseconds} ms',
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildResponseBadge(
                            '${((requestProvider.lastResponse!['body']?.toString().length ?? 0) / 1024).toStringAsFixed(2)} KB',
                            Colors.purple,
                          ),
                        ] else ...[
                          _buildResponseBadge('200', Colors.green),
                          const SizedBox(width: 8),
                          _buildResponseBadge('1050 ms', Colors.blue),
                          const SizedBox(width: 8),
                          _buildResponseBadge('1.94 KB', Colors.purple),
                        ],
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Response View Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['JSON', 'Raw', 'Headers', 'Tests'].map((view) {
                          final isSelected = responseView == view;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => responseView = view),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  view,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected 
                                        ? Colors.white 
                                        : _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Response Controls
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleResponsePanel,
                          icon: Icon(
                            _isResponseMaximized 
                                ? Icons.fullscreen_exit_rounded 
                                : Icons.fullscreen_rounded,
                            size: 18,
                            color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                          tooltip: _isResponseMaximized ? 'Minimize' : 'Maximize',
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.copy_all_rounded,
                            size: 18,
                            color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                          tooltip: 'Copy Response',
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.download_rounded,
                            size: 18,
                            color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                          tooltip: 'Download Response',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Response Body
              Expanded(
                child: _buildModernResponseBody(requestProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernResponseBody(RequestProvider requestProvider) {
    if (requestProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _primaryColor,
                backgroundColor: _primaryColor.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sending request...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connecting to ${_urlController.text}',
              style: TextStyle(
                fontSize: 11,
                color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }
    
    if (requestProvider.lastResponse == null) {
      return _buildEmptyResponseState();
    }
    
    final response = requestProvider.lastResponse!;
    final status = response['status'] ?? 0;
    final body = response['body'] ?? {};
    
    return _buildResponseContentView(response, body);
  }

  Widget _buildEmptyResponseState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.api_rounded,
            size: 64,
            color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No Response Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a request to see the response here',
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _sendRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Send Your First Request',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseContentView(Map<String, dynamic> response, dynamic body) {
    switch (responseView) {
      case 'JSON':
        return _buildJsonResponseView(body);
      case 'Raw':
        return _buildRawResponseView(body);
      case 'Headers':
        return _buildHeadersResponseView(response['headers'] ?? {});
      case 'Tests':
        return _buildTestsResponseView();
      default:
        return Container();
    }
  }

  Widget _buildJsonResponseView(dynamic body) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code_rounded,
                size: 18,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Response Body',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.copy_all_rounded,
                  size: 16,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                ),
                tooltip: 'Copy JSON',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _formatJson(body),
              style: TextStyle(
                fontSize: 11,
                color: _isDarkMode ? Colors.grey[100] : Colors.black,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawResponseView(dynamic body) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          body.toString(),
          style: TextStyle(
            fontSize: 11,
            color: _isDarkMode ? Colors.grey[100] : Colors.black,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeadersResponseView(Map<String, dynamic> headers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt_rounded,
                size: 18,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Response Headers',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(
                        color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(
                          'HEADER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'VALUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Rows
                ...headers.entries.map((entry) {
                  return Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            entry.value.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsResponseView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 64,
            color: _primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Test Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write tests in the "Tests" tab to validate responses',
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => selectedTab = 5),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Write Tests',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Dialog(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'john@example.com',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...['Profile Settings', 'Account', 'Billing', 'Team', 'Integrations', 'Logout']
                .map((item) => _buildProfileMenuItem(item))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(
                _getProfileMenuIcon(label),
                size: 16,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (label == 'Logout')
                Icon(
                  Icons.logout_rounded,
                  size: 14,
                  color: _dangerColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProfileMenuIcon(String label) {
    switch (label) {
      case 'Profile Settings':
        return Icons.settings_rounded;
      case 'Account':
        return Icons.person_rounded;
      case 'Billing':
        return Icons.credit_card_rounded;
      case 'Team':
        return Icons.people_rounded;
      case 'Integrations':
        return Icons.apps_rounded;
      case 'Logout':
        return Icons.exit_to_app_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getEnvironmentColor(String env) {
    switch (env) {
      case 'Development':
        return _accentColor;
      case 'Staging':
        return _warningColor;
      case 'Production':
        return _dangerColor;
      default:
        return _primaryColor;
    }
  }

  Color _getVariableTypeColor(String type) {
    switch (type) {
      case 'String':
        return _primaryColor;
      case 'Secret':
        return _dangerColor;
      case 'Number':
        return _accentColor;
      case 'Boolean':
        return _warningColor;
      default:
        return _secondaryColor;
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.orange;
      case 'PUT':
        return Colors.purple;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.blue;
      default:
        return _primaryColor;
    }
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 300 && statusCode < 400) return Colors.blue;
    if (statusCode >= 400 && statusCode < 500) return Colors.orange;
    if (statusCode >= 500) return Colors.red;
    return Colors.grey;
  }
}