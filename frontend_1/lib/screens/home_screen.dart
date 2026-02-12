import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workspace_provider.dart';
import '../providers/dashboard_provider.dart';
import '../screens/dashboard_view.dart';
import '../screens/request_studio_screen.dart';
import '../screens/trace_screen.dart';
import '../widgets/top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentViewIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  void _loadDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workspaceProvider =
        Provider.of<WorkspaceProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) return;

    if (workspaceProvider.workspaces.isEmpty) {
      workspaceProvider.loadWorkspaces().then((_) {
        if (workspaceProvider.selectedWorkspaceId != null && mounted) {
          Provider.of<DashboardProvider>(context, listen: false)
              .loadDashboard(workspaceProvider.selectedWorkspaceId!);
        }
      });
    } else if (workspaceProvider.selectedWorkspaceId != null && mounted) {
      Provider.of<DashboardProvider>(context, listen: false)
          .loadDashboard(workspaceProvider.selectedWorkspaceId!);
    }
  }

  void _onViewChanged(int index) {
    setState(() {
      _currentViewIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<DashboardProvider, WorkspaceProvider, AuthProvider>(
      builder:
          (context, dashboardProvider, workspaceProvider, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedView();
        }

        if (workspaceProvider.selectedWorkspaceId == null) {
          return _buildNoWorkspaceView();
        }

        return Container(
          color: const Color(0xFFFAFAFA),
          child: Column(
            children: [
              TopBar(
                currentViewIndex: _currentViewIndex,
                onViewChanged: _onViewChanged,
                searchController: _searchController,
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentViewIndex,
                  children: [
                    DashboardView(),
                    RequestStudioScreen(),
                    TracesScreen(onReplayToRequest: () => _onViewChanged(1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnauthenticatedView() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: const Center(
        child: Text('Please log in to continue'),
      ),
    );
  }

  Widget _buildNoWorkspaceView() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No workspace selected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to workspace setup
                Navigator.of(context).pushNamed('/workspace-setup');
              },
              child: const Text('Create or Select Workspace'),
            ),
          ],
        ),
      ),
    );
  }
}
