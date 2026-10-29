import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isAddingTransaction = false;
  bool _isCheckingBudget = false;
  bool _isBudgetDialogOpen = false;
  String? _deletingTransactionId;
  double? _monthlyBudget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMonthlyBudget();
    });
  }

  double _amountOf(Map<String, dynamic> transaction) {
    final amount = transaction['amount'];
    return amount is num ? amount.toDouble() : 0.0;
  }

  DateTime _dateOf(Map<String, dynamic> transaction) {
    final date = transaction['date'];
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    return DateTime.now();
  }

  String _formatAmount(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Future<void> _checkMonthlyBudget() async {
    if (_isCheckingBudget || !mounted) return;

    _isCheckingBudget = true;

    try {
      final budget = await _firestoreService.getMonthlyBudget(_currentMonth);

      if (!mounted) return;

      setState(() => _monthlyBudget = budget);

      if (budget == null) {
        await _showMonthlyBudgetDialog();
      }
    } catch (error, stackTrace) {
      debugPrint('LOAD MONTHLY BUDGET ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load budget: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      _isCheckingBudget = false;
    }
  }

  Future<void> _showMonthlyBudgetDialog() async {
    if (!mounted || _isBudgetDialogOpen) return;

    _isBudgetDialogOpen = true;

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Set ${_monthName(_currentMonth.month)} Budget'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your budget for this month. '
                        'Your previous budgets and transactions '
                        'will remain saved.',
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monthly budget',
                          hintText: 'e.g. 50000',
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final amount = double.tryParse((value ?? '').trim());

                          if (amount == null ||
                              !amount.isFinite ||
                              amount <= 0) {
                            return 'Enter an amount greater than zero.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  FilledButton(
                    onPressed:
                        isSaving
                            ? null
                            : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }

                              final amount = double.parse(
                                controller.text.trim(),
                              );

                              setDialogState(() => isSaving = true);

                              // Capture the messenger before awaiting Firestore.
                              final messenger = ScaffoldMessenger.of(
                                dialogContext,
                              );

                              try {
                                await _firestoreService.saveMonthlyBudget(
                                  month: _currentMonth,
                                  amount: amount,
                                );

                                if (!mounted) return;

                                setState(() => _monthlyBudget = amount);

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }

                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Monthly budget saved successfully.',
                                    ),
                                  ),
                                );
                              } catch (error, stackTrace) {
                                debugPrint('MONTHLY BUDGET SAVE ERROR: $error');
                                debugPrintStack(stackTrace: stackTrace);

                                if (dialogContext.mounted) {
                                  setDialogState(() => isSaving = false);

                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Budget save failed: $error',
                                      ),
                                      duration: const Duration(seconds: 10),
                                    ),
                                  );
                                }
                              }
                            },
                    child:
                        isSaving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save budget'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
      _isBudgetDialogOpen = false;
    }
  }

  Future<void> _addTransaction() async {
    if (_isAddingTransaction) return;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _isAddingTransaction = true);

    try {
      await _firestoreService.addTransaction(result);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingTransaction = false);
      }
    }
  }

  Future<void> _deleteTransaction(String transactionId, String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text(
              'Are you sure you want to delete "$category"? '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingTransactionId = transactionId);

    try {
      await _firestoreService.deleteTransaction(transactionId);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete transaction: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTransactionId = null);
      }
    }
  }

  Widget _buildTransactionCard(
    BuildContext context,
    Map<String, dynamic> transaction,
    String transactionId,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isIncome = transaction['type'] == 'Income';
    final amount = _amountOf(transaction);
    final date = _dateOf(transaction);
    final notes = transaction['notes'] as String? ?? '';
    final category = transaction['category'] as String? ?? 'Other';
    final isDeleting = _deletingTransactionId == transactionId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.only(
          left: 16,
          right: 4,
          top: 4,
          bottom: 4,
        ),
        leading: CircleAvatar(
          backgroundColor:
              isIncome
                  ? Colors.green.withValues(alpha: 0.12)
                  : colors.error.withValues(alpha: 0.12),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: isIncome ? Colors.green : colors.error,
          ),
        ),
        title: Text(category),
        subtitle: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}'
          '${notes.isNotEmpty ? ' • $notes' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : colors.error,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Transaction options',
              enabled: !isDeleting,
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteTransaction(transactionId, category);
                }
              },
              itemBuilder:
                  (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, double monthlyExpenses) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final budget = _monthlyBudget;

    final progress =
        budget == null || budget <= 0
            ? 0.0
            : (monthlyExpenses / budget).clamp(0.0, 1.0).toDouble();

    final remaining = budget == null ? 0.0 : budget - monthlyExpenses;
    final overBudget = budget != null && remaining < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Monthly budget',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showMonthlyBudgetDialog,
                  tooltip: 'Edit monthly budget',
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (budget == null) ...[
              const Text('No budget set for this month yet.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _showMonthlyBudgetDialog,
                icon: const Icon(Icons.add),
                label: const Text('Set monthly budget'),
              ),
            ] else ...[
              Text(
                _formatAmount(budget),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatAmount(monthlyExpenses)} spent this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: overBudget ? colors.error : colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      overBudget
                          ? '${_formatAmount(remaining.abs())} over budget'
                          : '${_formatAmount(remaining)} remaining',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: overBudget ? colors.error : colors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${(monthlyExpenses / budget * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (overBudget) ...[
                const SizedBox(height: 8),
                Text(
                  'You have exceeded your monthly budget.',
                  style: TextStyle(color: colors.error),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<Map<String, dynamic>> transactions,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final now = DateTime.now();

    final totalIncome = transactions
        .where((transaction) => transaction['type'] == 'Income')
        .fold<double>(
          0,
          (total, transaction) => total + _amountOf(transaction),
        );

    final totalExpenses = transactions
        .where((transaction) => transaction['type'] == 'Expense')
        .fold<double>(
          0,
          (total, transaction) => total + _amountOf(transaction),
        );

    final balance = totalIncome - totalExpenses;

    final monthlyExpenses = transactions
        .where((transaction) {
          final date = _dateOf(transaction);
          return transaction['type'] == 'Expense' &&
              date.month == now.month &&
              date.year == now.year;
        })
        .fold<double>(
          0,
          (total, transaction) => total + _amountOf(transaction),
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Good day 👋',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your financial overview',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primary.withValues(alpha: 0.78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total balance',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Text(
                _formatAmount(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _BalanceInfo(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Income',
                      amount: _formatAmount(totalIncome),
                    ),
                  ),
                  Expanded(
                    child: _BalanceInfo(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Expenses',
                      amount: _formatAmount(totalExpenses),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_monthName(now.month)} ${now.year}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBudgetCard(context, monthlyExpenses),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'This month',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 42,
                  color: colors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatAmount(monthlyExpenses)} spent',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  monthlyExpenses == 0
                      ? 'Your expense breakdown will appear here.'
                      : 'Your spending this month.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Recent transactions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 42,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add your first transaction to get started.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.take(10).map((transaction) {
            final transactionId = transaction['id'] as String;
            return _buildTransactionCard(context, transaction, transactionId);
          }),
        const SizedBox(height: 100),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: _checkMonthlyBudget,
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Check monthly budget',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.streamTransactions(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load your transactions.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection and Firestore rules, '
                        'then try again.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactions =
                (snapshot.data?.docs ?? []).map((document) {
                  return <String, dynamic>{
                    ...document.data(),
                    'id': document.id,
                  };
                }).toList();

            return _buildDashboard(context, transactions);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAddingTransaction ? null : _addTransaction,
        icon:
            _isAddingTransaction
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.add_rounded),
        label: Text(_isAddingTransaction ? 'Saving...' : 'Add transaction'),
      ),
    );
  }
}

class _BalanceInfo extends StatelessWidget {
  const _BalanceInfo({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
