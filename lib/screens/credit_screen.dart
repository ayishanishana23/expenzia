import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/expense_database.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  static const _teal = Color(0xFF2D807C);

  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();

  String _creditType = 'Subscriptions';
  String _planType = 'Monthly';
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  List<Map<String, Object?>> _credits = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _loadCredits() async {
    try {
      final credits = await ExpenseDatabase.instance.getCredits();

      if (!mounted) return;

      setState(() {
        _credits = credits;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load saved credits.';
      });
    }
  }

  InputDecoration _decoration({Widget? suffixIcon}) {
    return InputDecoration(
      isDense: true,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: _teal),
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  int? _parseAmount(String value) {
    final text = value.trim();

    if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }

    final parts = text.split('.');
    final paise = int.parse(parts[0]) * 100 +
        (parts.length == 2
            ? int.parse(parts[1].padRight(2, '0'))
            : 0);

    return paise > 0 ? paise : null;
  }

  Future<int?> _askAmount() {
    final amountFormKey = GlobalKey<FormState>();
    String input = '';

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Payment amount'),
          content: Form(
            key: amountFormKey,
            child: TextFormField(
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => input = value,
              validator: (value) {
                if (_parseAmount(value ?? '') == null) {
                  return 'Enter a positive amount, up to 2 decimals';
                }
                return null;
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
                if (amountFormKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, _parseAmount(input));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final amountPaise = await _askAmount();

      if (!mounted || amountPaise == null) return;

      await ExpenseDatabase.instance.addCredit(
        creditType: _creditType,
        recipient: _recipientController.text,
        dueDate: _date,
        planType: _planType,
        amountPaise: amountPaise,
      );

      if (!mounted) return;

      _recipientController.clear();
      await _loadCredits();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _error == null
                ? 'Credit saved'
                : 'Credit saved. Tap Retry to refresh the list.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save credit. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _savedCredit(Map<String, Object?> credit) {
    final date = DateTime.parse(credit['due_date'] as String);
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDate = DateUtils.dateOnly(date);

    final isToday = dueDate == today;
    final overdue = dueDate.isBefore(today);

    final dueText = isToday
        ? 'Due Today'
        : '${overdue ? 'Overdue' : 'Due On'} '
        '${DateFormat('dd/MM/yy').format(date)}';

    final amount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    ).format((credit['amount_paise'] as int) / 100);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credit['recipient'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueText,
                  style: TextStyle(
                    fontSize: 11,
                    color: isToday || overdue
                        ? Colors.redAccent
                        : const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  credit['plan_type'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCredits,
      child: Form(
        key: _formKey,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          children: [
            _field(
              'CREDIT TYPE',
              DropdownButtonFormField<String>(
                initialValue: _creditType,
                decoration: _decoration(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                items: ['Subscriptions', 'Bills', 'Loan', 'Other']
                    .map(
                      (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ),
                )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                  if (value != null) {
                    setState(() => _creditType = value);
                  }
                },
              ),
            ),
            _field(
              'TO',
              TextFormField(
                controller: _recipientController,
                enabled: !_saving,
                style: const TextStyle(fontSize: 13),
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(),
                validator: (value) {
                  return value == null || value.trim().isEmpty
                      ? 'Enter a recipient'
                      : null;
                },
              ),
            ),
            _field(
              'DATE',
              InkWell(
                onTap: _saving ? null : _pickDate,
                child: InputDecorator(
                  decoration: _decoration(
                    suffixIcon: const Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                  child: Text(
                    DateFormat('EEE, dd MMM yyyy').format(_date),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            _field(
              'PLAN TYPE',
              DropdownButtonFormField<String>(
                initialValue: _planType,
                decoration: _decoration(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                items: ['Monthly', 'One-Time']
                    .map(
                      (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ),
                )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                  if (value != null) {
                    setState(() => _planType = value);
                  }
                },
              ),
            ),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  shape: const StadiumBorder(),
                ),
                child: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save'),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Your Saved Lists',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Column(
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _loadCredits,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (_credits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No saved credits yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._credits.map(_savedCredit),
          ],
        ),
      ),
    );
  }
}