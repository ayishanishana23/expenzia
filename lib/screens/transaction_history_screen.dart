import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../widgets/expense_tile.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final List<Expense> expenses;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Expense) onEdit;
  final Future<void> Function(Expense) onDelete;

  const TransactionHistoryScreen({
    super.key,
    required this.expenses,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF2D807C),
      onRefresh: onRefresh,
      child: expenses.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: const [
          SizedBox(height: 90),
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Color(0xFF438F8B),
          ),
          SizedBox(height: 18),
          Center(
            child: Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text('Tap + to add a transaction.'),
          ),
        ],
      )
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];

          return ExpenseTile(
            key: ValueKey(expense.id),
            expense: expense,
            onEdit: () {
              onEdit(expense);
            },
            onDelete: () {
              onDelete(expense);
            },
          );
        },
      ),
    );
  }
}