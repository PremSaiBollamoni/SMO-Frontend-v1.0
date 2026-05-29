import 'package:flutter/material.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../data/api/process_planner_api_service.dart';

/// Dialog for renaming an operation within a single routing.
/// Backend will clone the operation if it's shared with other routings,
/// so the rename never leaks. We simply show that note to the user.
class RenameOperationDialog extends StatefulWidget {
  final int routingId;
  final int operationId;
  final String currentName;
  final String currentDescription;

  const RenameOperationDialog({
    super.key,
    required this.routingId,
    required this.operationId,
    required this.currentName,
    this.currentDescription = '',
  });

  @override
  State<RenameOperationDialog> createState() => _RenameOperationDialogState();
}

class _RenameOperationDialogState extends State<RenameOperationDialog> {
  final ProcessPlannerApiService _api = ProcessPlannerApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _descController.text = widget.currentDescription;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newDesc = _descController.text.trim();
    final originalName = widget.currentName.trim();
    final originalDesc = widget.currentDescription.trim();

    if (newName == originalName && newDesc == originalDesc) {
      Navigator.of(context).pop(false); // nothing changed
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _api.renameOperationInRouting(
        routingId: widget.routingId,
        operationId: widget.operationId,
        newName: newName,
        newDescription: newDesc,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiErrorHelper.getMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Edit step name & description',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current name',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.currentName,
                        style:
                            const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current description',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.currentDescription.trim().isEmpty
                            ? '(none)'
                            : widget.currentDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.currentDescription.trim().isEmpty
                              ? Colors.grey.shade500
                              : Colors.black87,
                          fontStyle: widget.currentDescription.trim().isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'New name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'New description',
                        hintText: 'A short description of what happens here',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These changes apply only to this routing. If the same step is used in other routings, those keep the original name and description.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              _submitting ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check),
                          label: Text(_submitting ? 'Saving...' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
