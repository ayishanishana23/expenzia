import 'package:flutter/material.dart';

import '../database/expense_database.dart';

class ProfileScreen extends StatefulWidget {
  final Future<void> Function() onStorageCleared;

  const ProfileScreen({
    super.key,
    required this.onStorageCleared,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _teal = Color(0xFF2D807C);

  String _name = 'Your name';
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final name = await ExpenseDatabase.instance.getProfileName();

      if (!mounted) return;

      setState(() {
        _name = name;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load your profile.';
      });
    }
  }

  Future<void> _editName() async {
    if (_busy) return;

    final formKey = GlobalKey<FormState>();
    String enteredName = _name == 'Your name' ? '' : _name;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: enteredName,
              autofocus: true,
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => enteredName = value,
              validator: (value) {
                return value == null || value.trim().isEmpty
                    ? 'Enter your name'
                    : null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, enteredName.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() => _busy = true);

    try {
      await ExpenseDatabase.instance.saveProfileName(result);

      if (!mounted) return;

      setState(() => _name = result);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your name.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _clearStorage() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear storage?'),
          content: const Text(
            'This permanently deletes all expenses, saved credits, '
                'and your profile name from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      await ExpenseDatabase.instance.clearStorage();

      if (!mounted) return;

      setState(() => _name = 'Your name');

      // Refresh Home, History, and Credit after clearing.
      await widget.onStorageCleared();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage cleared')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not finish clearing storage. Please retry.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48)
                  .clamp(0.0, double.infinity)
                  .toDouble(),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 52,
                    backgroundColor: Color(0xFFB5B5B5),
                    child: Icon(
                      Icons.person,
                      size: 94,
                      color: Color(0xFFE8E8E8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _busy ? null : _editName,
                        tooltip: 'Edit name',
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 17,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: _busy ? null : _clearStorage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      side: const BorderSide(
                        color: Color(0xFFE0E0E0),
                      ),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                    child: const Text(
                      'Clear Storage',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _teal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}