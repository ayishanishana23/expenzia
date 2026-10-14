import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  String _dateLabel() {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (DateUtils.isSameDay(expense.date, today)) {
      return 'Today';
    }

    if (DateUtils.isSameDay(expense.date, yesterday)) {
      return 'Yesterday';
    }

    return DateFormat('MMM dd, yyyy').format(expense.date);
  }

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    ).format(expense.amount);

    final color = expense.isInward
        ? const Color(0xFF00A86B)
        : const Color(0xFFFF4545);

    final sign = expense.isInward ? '+' : '−';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _dateLabel(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const SizedBox(height: 3),


                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$sign $amount',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 6),
            Column(
              children: [
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit transaction',
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF555555),
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete transaction',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFFF4545),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}