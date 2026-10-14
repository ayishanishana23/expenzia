import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../widgets/expense_tile.dart';

class HomeScreen extends StatelessWidget {
  final List<Expense> expenses;
  final Future<void> Function() onRefresh;
  final VoidCallback onSeeAll;

  const HomeScreen({
    super.key,
    required this.expenses,
    required this.onRefresh,
    required this.onSeeAll,
  });

  static const _teal = Color(0xFF2D807C);

  String _money(num paise) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(paise / 100);
  }



  List<Expense> get _outwardTransactions {
    return expenses.where((item) => !item.isInward).toList();
  }

  int get _incomePaise {
    return expenses
        .where((item) => item.isInward)
        .fold(0, (total, item) => total + item.amountPaise);
  }

  int get _expensePaise {
    return _outwardTransactions.fold(
      0,
          (total, item) => total + item.amountPaise,
    );
  }

  int get _balancePaise => _incomePaise - _expensePaise;

  int get _weeklyPaise {
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final tomorrow = today.add(const Duration(days: 1));

    return _outwardTransactions
        .where(
          (item) =>
      !item.date.isBefore(monday) &&
          item.date.isBefore(tomorrow),
    )
        .fold(0, (total, item) => total + item.amountPaise);
  }

  double get _dailyAveragePaise {
    final outward = _outwardTransactions;

    if (outward.isEmpty) return 0;

    var earliest = outward.first.date;

    for (final item in outward) {
      if (item.date.isBefore(earliest)) {
        earliest = item.date;
      }
    }

    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final firstDate = DateTime.utc(
      earliest.year,
      earliest.month,
      earliest.day,
    );

    final days = today.difference(firstDate).inDays + 1;

    return _expensePaise / (days < 1 ? 1 : days);
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _statCard(String label, num amount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE3E3E3),
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _money(amount),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentExpenses = expenses.take(5).toList();

    return RefreshIndicator(
      color: _teal,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            _greeting,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 3),
          const Text(
            'Expenzia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Expense summary.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _money(_balancePaise),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '↓ Income',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _money(_incomePaise),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '↑ Expenses',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _money(_expensePaise),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statCard('DAILY AVERAGE', _dailyAveragePaise),
              const SizedBox(width: 12),
              _statCard('THIS WEEK', _weeklyPaise),
            ],
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transactions History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF777777),
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          if (recentExpenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Color(0xFF438F8B),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap + to add your first expense.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...recentExpenses.map(
                  (expense) => ExpenseTile(
                key: ValueKey(expense.id),
                expense: expense,
              ),
            ),
        ],
      ),
    );
  }
}