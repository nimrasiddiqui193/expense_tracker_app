import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/notification_service.dart';

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
      if (mounted) {
        _checkMonthlyBudget();
      }
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

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.month == now.month && date.year == now.year;
  }

  Future<double> _getCurrentMonthExpenseTotal() async {
    final snapshot = await _firestoreService.getTransactions();

    double total = 0;

    for (final document in snapshot.docs) {
      final transaction = document.data();

      if (transaction['type'] == 'Expense' &&
          _isCurrentMonth(_dateOf(transaction))) {
        total += _amountOf(transaction);
      }
    }

    return total;
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
      case 'groceries':
        return Icons.restaurant_rounded;
      case 'shopping':
      case 'clothing':
        return Icons.shopping_bag_rounded;
      case 'transport':
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'health':
      case 'medical':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'salary':
      case 'business':
        return Icons.work_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'home':
        return Icons.home_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _showTransactionDetails(Map<String, dynamic> transaction) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isIncome = transaction['type'] == 'Income';
    final amount = _amountOf(transaction);
    final date = _dateOf(transaction);

    final category =
        transaction['category'] is String
            ? transaction['category'] as String
            : 'Other';

    final notes =
        transaction['notes'] is String
            ? (transaction['notes'] as String).trim()
            : '';

    final accentColor = isIncome ? const Color(0xFF159B70) : colors.error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transaction Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.13),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _categoryIcon(category),
                            color: accentColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            isIncome ? 'Income' : 'Expense',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _detailRow(
                    context,
                    icon: Icons.category_rounded,
                    label: 'Category',
                    value: category,
                  ),
                  _detailRow(
                    context,
                    icon: Icons.calendar_month_rounded,
                    label: 'Date',
                    value: _formatDate(date),
                  ),
                  _detailRow(
                    context,
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value:
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}',
                  ),
                  _detailRow(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transaction type',
                    value: isIncome ? 'Income' : 'Expense',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Notes',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      notes.isEmpty ? 'No notes added.' : notes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            notes.isEmpty
                                ? colors.onSurfaceVariant
                                : colors.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Close details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: colors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isCheckingBudget = false;
    }
  }

  Future<void> _showMonthlyBudgetDialog() async {
    if (!mounted || _isBudgetDialogOpen) return;

    _isBudgetDialogOpen = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => _MonthlyBudgetDialog(
              firestoreService: _firestoreService,
              month: _currentMonth,
              monthName: _monthName(_currentMonth.month),
              onSaved: (amount) {
                if (!mounted) return;
                setState(() => _monthlyBudget = amount);
              },
            ),
      );
    } finally {
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

    double? previousMonthlyExpenses;
    double? budget = _monthlyBudget;

    final isCurrentMonthExpense =
        result['type'] == 'Expense' && _isCurrentMonth(_dateOf(result));

    if (isCurrentMonthExpense) {
      try {
        previousMonthlyExpenses = await _getCurrentMonthExpenseTotal();

        budget ??= await _firestoreService.getMonthlyBudget(_currentMonth);

        if (mounted && budget != _monthlyBudget) {
          setState(() => _monthlyBudget = budget);
        }
      } catch (error) {
        debugPrint('BUDGET THRESHOLD CHECK ERROR: $error');
      }
    }

    try {
      await _firestoreService.addTransaction(result);

      if (!mounted) return;

      if (isCurrentMonthExpense &&
          previousMonthlyExpenses != null &&
          budget != null &&
          budget > 0) {
        final newMonthlyExpenses = previousMonthlyExpenses + _amountOf(result);

        final threshold = budget * 0.80;

        if (previousMonthlyExpenses < threshold &&
            newMonthlyExpenses >= threshold) {
          try {
            await NotificationService.showBudgetThresholdAlert(
              totalSpent: newMonthlyExpenses,
              monthlyBudget: budget,
            );
          } catch (error) {
            debugPrint('BUDGET NOTIFICATION ERROR: $error');
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save transaction: $error'),
          behavior: SnackBarBehavior.floating,
        ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete transaction: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTransactionId = null);
      }
    }
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    String? trailing,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    double income,
    double expenses,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.86),
            const Color(0xFF064E3B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -65,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TOTAL BALANCE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatAmount(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your available balance',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 26),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _BalanceInfo(
                      icon: Icons.south_west_rounded,
                      label: 'Income',
                      amount: _formatAmount(income),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceInfo(
                      icon: Icons.north_east_rounded,
                      label: 'Expenses',
                      amount: _formatAmount(expenses),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: Card(
        elevation: 0,
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
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
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.savings_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly budget',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Keep your spending on track',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showMonthlyBudgetDialog,
                  tooltip: 'Edit monthly budget',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (budget == null) ...[
              Text(
                'No budget has been set for this month.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showMonthlyBudgetDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Set monthly budget'),
                ),
              ),
            ] else ...[
              Text(
                _formatAmount(budget),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_formatAmount(monthlyExpenses)} spent this month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 11,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: overBudget ? colors.error : colors.primary,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(
                    overBudget
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 17,
                    color: overBudget ? colors.error : colors.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      overBudget
                          ? '${_formatAmount(remaining.abs())} over budget'
                          : '${_formatAmount(remaining)} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overBudget ? colors.error : colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(monthlyExpenses / budget * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (overBudget) ...[
                const SizedBox(height: 10),
                Text(
                  'You have exceeded your monthly spending limit.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
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

    final notes =
        transaction['notes'] is String ? transaction['notes'] as String : '';

    final category =
        transaction['category'] is String
            ? transaction['category'] as String
            : 'Other';

    final isDeleting = _deletingTransactionId == transactionId;
    final accentColor = isIncome ? const Color(0xFF159B70) : colors.error;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDeleting ? null : () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDate(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view details',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isIncome ? 'Income' : 'Expense',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
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
                            Icon(Icons.delete_outline_rounded),
                            SizedBox(width: 9),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                icon:
                    isDeleting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 34,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Your financial activity will appear here. '
              'Add your first transaction to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        Text(
          'Good day 👋',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Your financial overview',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 22),
        _buildBalanceCard(context, balance, totalIncome, totalExpenses),
        const SizedBox(height: 22),
        Row(
          children: [
            _buildStatCard(
              context,
              title: 'Total income',
              amount: _formatAmount(totalIncome),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF159B70),
              subtitle: 'All time',
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              context,
              title: 'Total expenses',
              amount: _formatAmount(totalExpenses),
              icon: Icons.trending_down_rounded,
              color: colors.error,
              subtitle: 'All time',
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildSectionTitle(
          context,
          'Budget overview',
          trailing: '${_monthName(now.month)} ${now.year}',
        ),
        const SizedBox(height: 13),
        _buildBudgetCard(context, monthlyExpenses),
        const SizedBox(height: 28),
        _buildSectionTitle(
          context,
          'Spending overview',
          trailing: 'This month',
        ),
        const SizedBox(height: 13),
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: colors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly spending',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatAmount(monthlyExpenses),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthlyExpenses == 0
                            ? 'No expenses recorded this month.'
                            : 'Total expenses recorded this month.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildSectionTitle(
          context,
          'Recent transactions',
          trailing: '${transactions.length} total',
        ),
        const SizedBox(height: 13),
        if (transactions.isEmpty)
          _buildEmptyTransactions(context)
        else
          ...transactions.take(10).map((transaction) {
            final transactionId = transaction['id'] as String;

            return _buildTransactionCard(context, transaction, transactionId);
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: _checkMonthlyBudget,
            tooltip: 'Check monthly budget',
            icon: const Icon(Icons.notifications_none_rounded),
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
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: colors.error,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Could not load your transactions.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection and Firestore rules, '
                        'then try again.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
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

class _MonthlyBudgetDialog extends StatefulWidget {
  const _MonthlyBudgetDialog({
    required this.firestoreService,
    required this.month,
    required this.monthName,
    required this.onSaved,
  });

  final FirestoreService firestoreService;
  final DateTime month;
  final String monthName;
  final ValueChanged<double> onSaved;

  @override
  State<_MonthlyBudgetDialog> createState() => _MonthlyBudgetDialogState();
}

class _MonthlyBudgetDialogState extends State<_MonthlyBudgetDialog> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.parse(_controller.text.trim());

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.firestoreService.saveMonthlyBudget(
        month: widget.month,
        amount: amount,
      );

      if (!mounted) return;

      widget.onSaved(amount);

      Navigator.of(context).pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Monthly budget saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('MONTHLY BUDGET SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _isSaving = false);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Budget save failed: $error'),
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text('Set ${widget.monthName} Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a spending limit for this month. '
              'Your previous budgets and transactions '
              'will remain saved.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly budget',
                hintText: 'e.g. 50000',
                prefixText: 'Rs. ',
              ),
              validator: (value) {
                final amount = double.tryParse((value ?? '').trim());

                if (amount == null || !amount.isFinite || amount <= 0) {
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
          onPressed: _isSaving ? null : _saveBudget,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save budget'),
        ),
      ],
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
            Icon(icon, color: Colors.white70, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
