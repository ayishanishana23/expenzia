import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/expense_database.dart';
import '../models/expense.dart';
import 'credit_screen.dart';
import 'profile_screen.dart';
import 'expense_form_screen.dart';
import 'home_screen.dart';
import 'transaction_history_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _teal = Color(0xFF2D807C);
  static const _barColor = Color(0xFF438F8B);
  static const _inactiveColor = Color(0xFF286F6C);

  int _selectedIndex = 0;
  int _loadRequest = 0;
  int _creditRevision = 0;

  List<Expense> _expenses = [];
  bool _loading = true;
  bool _deletingTransaction = false;
  String? _error;

  static const _titles = [
    'Home',
    'Transaction History',
    'Credit',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _onStorageCleared() async {
    await _loadExpenses();

    if (!mounted) return;

    setState(() {
      _creditRevision++;
    });
  }

  Future<void> _loadExpenses() async {
    final request = ++_loadRequest;

    try {
      final expenses = await ExpenseDatabase.instance.getExpenses();

      if (!mounted || request != _loadRequest) return;

      setState(() {
        _expenses = expenses;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || request != _loadRequest) return;

      setState(() {
        _loading = false;
        _error = 'Could not load your expenses. Please try again.';
      });
    }
  }
  Future<void> _deleteTransaction(Expense expense) async {
    if (_deletingTransaction) return;
    _deletingTransaction = true;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text(
              'Delete "${expense.title}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;

      await ExpenseDatabase.instance.deleteExpense(expense.id!);

      if (!mounted) return;

      await _loadExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _error == null
                ? 'Transaction deleted'
                : 'Transaction deleted. Tap Retry to refresh the list.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete the transaction. Please try again.',
          ),
        ),
      );
    } finally {
      _deletingTransaction = false;
    }
  }

  Future<void> _addTransaction() {
    return _openTransaction();
  }

  Future<void> _openTransaction([Expense? expense]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(expense: expense),
      ),
    );

    if (!mounted || saved != true) return;

    await _loadExpenses();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _error != null
              ? 'Transaction saved. Tap Retry to refresh the list.'
              : expense == null
              ? 'Transaction added'
              : 'Transaction updated',
        ),
      ),
    );
  }

  Widget _expenseContent(Widget child) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _teal),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: _teal,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _loadExpenses();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }

  Widget _navigationItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Semantics(
        selected: _selectedIndex == index,
        label: label,
        child: IconButton(
          tooltip: label,
          onPressed: () {
            setState(() => _selectedIndex = index);
          },
          icon: Icon(
            icon,
            size: 25,
            color: _selectedIndex == index
                ? Colors.white
                : _inactiveColor,
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(double bottomInset) {
    return SizedBox(
      height: 86 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 26,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: _barColor,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Row(
                children: [
                  _navigationItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    label: 'Home',
                  ),
                  _navigationItem(
                    index: 1,
                    icon: Icons.history,
                    label: 'Transaction History',
                  ),
                  const SizedBox(width: 76),
                  _navigationItem(
                    index: 2,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Credit',
                  ),
                  _navigationItem(
                    index: 3,
                    icon: Icons.person_outline,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0EEEC),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: _barColor,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _addTransaction,
                    customBorder: const CircleBorder(),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 32,
                        color: Colors.white,
                        semanticLabel: 'Add transaction',
                      ),
                    ),
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _selectedIndex == 0
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _selectedIndex == 0
            ? null
            : AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          toolbarHeight: 68,
        ),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _expenseContent(
                HomeScreen(
                  expenses: _expenses,
                  onRefresh: _loadExpenses,
                  onSeeAll: () {
                    setState(() => _selectedIndex = 1);
                  },
                ),
              ),
              _expenseContent(
                TransactionHistoryScreen(
                  expenses: _expenses,
                  onRefresh: _loadExpenses,
                  onEdit: (expense) => _openTransaction(expense),
                  onDelete: _deleteTransaction,
                ),
              ),
              CreditScreen(
                key: ValueKey(_creditRevision),
              ),
              ProfileScreen(
                onStorageCleared: _onStorageCleared,
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(bottomInset),
      ),
    );
  }
}