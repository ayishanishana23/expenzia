import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../database/expense_database.dart';
import '../models/expense.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  static const _teal = Color(0xFF2D807C);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String _category = 'Other';
  bool _saving = false;

  String _transactionType = 'outward';

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    if (expense != null) {
      _nameController.text = expense.title;

      _amountController.text =
      '${expense.amountPaise ~/ 100}.'
          '${(expense.amountPaise % 100).toString().padLeft(2, '0')}';

      _descriptionController.text = expense.description ?? '';
      _category = expense.category;
      _date = DateUtils.dateOnly(expense.date);
      _transactionType = expense.transactionType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int? _amountInPaise(String input) {
    final text = input.trim();

    if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }

    final parts = text.split('.');
    final rupees = int.parse(parts.first);
    final paise = parts.length == 2
        ? int.parse(parts[1].padRight(2, '0'))
        : 0;

    return rupees * 100 + paise;
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.1,
          color: Color(0xFF666666),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _decoration({
    String? hint,
    bool highlighted = false,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: _teal),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFFAAAAAA),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(
          color: highlighted ? _teal : const Color(0xFFE3E3E3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: _teal, width: 1.2),
      ),
      errorMaxLines: 2,
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );

    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final description = _descriptionController.text.trim();

    final transaction = Expense(
      id: widget.expense?.id,
      title: _nameController.text.trim(),
      amountPaise: _amountInPaise(_amountController.text)!,
      category: _category,
      date: _date,
      description: description.isEmpty ? null : description,
      transactionType: _transactionType,
    );

    try {
      if (_isEditing) {
        await ExpenseDatabase.instance.updateExpense(transaction);
      } else {
        await ExpenseDatabase.instance.addExpense(transaction);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the transaction. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _transactionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TRANSACTION TYPE'),
          DropdownButtonFormField<String>(
            initialValue: _transactionType,
            isExpanded: true,
            decoration: _decoration(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 19,
            ),
            items: const [
              DropdownMenuItem(
                value: 'inward',
                child: Text('Income'),
              ),
              DropdownMenuItem(
                value: 'outward',
                child: Text('Expense'),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) {
              if (value != null) {
                setState(() => _transactionType = value);
              }
            },
          ),
          const SizedBox(height: 20),
          _label('NAME'),
          TextFormField(
            controller: _nameController,
            enabled: !_saving,
            style: const TextStyle(fontSize: 13),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: _decoration(hint: 'Enter expense name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter an expense name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _label('AMOUNT'),
          TextFormField(
            controller: _amountController,
            enabled: !_saving,
            style: const TextStyle(fontSize: 13, color: _teal),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _decoration(
              highlighted: true,
              prefixText: '₹ ',
              hint: '0.00',
              suffixIcon: TextButton(
                onPressed: _saving ? null : _amountController.clear,
                style: TextButton.styleFrom(
                  foregroundColor: _teal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
            validator: (value) {
              final amount = _amountInPaise(value ?? '');

              if (amount == null) {
                return 'Enter a valid amount with up to 2 decimal places';
              }

              if (amount <= 0) {
                return 'Amount must be greater than zero';
              }

              return null;
            },
          ),
          const SizedBox(height: 20),
          _label('DATE'),
          Semantics(
            button: true,
            label: 'Select expense date',
            child: InkWell(
              onTap: _saving ? null : _selectDate,
              borderRadius: BorderRadius.circular(7),
              child: InputDecorator(
                decoration: _decoration(
                  suffixIcon: const Icon(
                    Icons.calendar_month,
                    size: 19,
                    color: Color(0xFF888888),
                  ),
                ),
                child: Text(
                  DateFormat('EEE, dd MMM yyyy').format(_date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          toolbarHeight: 68,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _saving
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left),
          ),
          title: Text(
            _isEditing ? 'Edit Transaction' : 'Transaction',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      children: [
                        _transactionCard(),

                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: _saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}