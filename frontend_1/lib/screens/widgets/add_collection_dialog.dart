import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/workspace_provider.dart';

class AddCollectionDialog extends StatefulWidget {
  const AddCollectionDialog({Key? key}) : super(key: key);

  @override
  State<AddCollectionDialog> createState() => _AddCollectionDialogState();
}

class _AddCollectionDialogState extends State<AddCollectionDialog> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final workspaceId = Provider.of<WorkspaceProvider>(context, listen: false).selectedWorkspaceId;
      if (workspaceId == null) {
        throw Exception('No workspace selected');
      }
      await Provider.of<CollectionProvider>(context, listen: false).createCollection(workspaceId, name);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Collection'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Collection Name',
          hintText: 'e.g., My API Project',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Create'),
        ),
      ],
    );
  }
}
