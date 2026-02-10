import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/workspace_provider.dart';

class SaveRequestDialog extends StatefulWidget {
  final String currentName;
  final String method;
  final String url;
  
  const SaveRequestDialog({
    Key? key,
    this.currentName = '',
    required this.method,
    required this.url,
  }) : super(key: key);

  @override
  State<SaveRequestDialog> createState() => _SaveRequestDialogState();
}

class _SaveRequestDialogState extends State<SaveRequestDialog> {
  late TextEditingController _nameController;
  String? _selectedCollectionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName.isNotEmpty ? widget.currentName : 'My Request');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedCollectionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a collection and enter a name')));
        return;
    }

    setState(() => _isLoading = true);
    try {
      final collectionProvider = Provider.of<CollectionProvider>(context, listen: false);
      final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
      
      await collectionProvider.addRequestToCollection(
        _selectedCollectionId!,
        {
            'name': name,
            'method': widget.method,
            'url': widget.url,
        },
        workspaceProvider.selectedWorkspaceId!
      );
      
      if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final collections = Provider.of<CollectionProvider>(context).collections;

    return AlertDialog(
      title: const Text('Save Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Request Name',
              hintText: 'e.g., Get Todos',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCollectionId,
            hint: const Text('Select Collection'),
            items: collections.map<DropdownMenuItem<String>>((c) {
              return DropdownMenuItem(
                value: c['id'],
                child: Text(c['name'] ?? 'Untitled'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCollectionId = val),
          ),
        ],
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
            : const Text('Save'),
        ),
      ],
    );
  }
}
