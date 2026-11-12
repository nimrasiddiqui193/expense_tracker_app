import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/firestore_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  DateTime _dateOf(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  String _money(num amount) => 'Rs. ${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), centerTitle: false),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().streamTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

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
                      'Unable to load statistics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];
          final transactions = documents.map((doc) => doc.data()).toList();

          double totalIncome = 0;
          double totalExpenses = 0;
          double monthlyIncome = 0;
          double monthlyExpenses = 0;

          final now = DateTime.now();
          final categoryTotals = <String, double>{};

          for (final transaction in transactions) {
            final rawAmount = transaction['amount'];
            final amount = rawAmount is num ? rawAmount.toDouble() : 0.0;

            final type =
                (transaction['type'] ?? 'Expense').toString().toLowerCase();

            final category = (transaction['category'] ?? 'Other').toString();

            final date = _dateOf(transaction['date']);
            final isIncome = type == 'income';

            if (isIncome) {
              totalIncome += amount;
            } else {
              totalExpenses += amount;
              categoryTotals[category] =
                  (categoryTotals[category] ?? 0) + amount;
            }

            if (date.year == now.year && date.month == now.month) {
              if (isIncome) {
                monthlyIncome += amount;
              } else {
                monthlyExpenses += amount;
              }
            }
          }

          final netBalance = totalIncome - totalExpenses;

          final totalCategoryExpenses = categoryTotals.values.fold<double>(
            0,
            (total, amount) => total + amount,
          );

          final sortedCategories =
              categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

          final monthlyDifference = monthlyIncome - monthlyExpenses;

          final monthlyMaximum =
              monthlyIncome > monthlyExpenses ? monthlyIncome : monthlyExpenses;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              Text(
                'Your Financial Overview',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Understand your spending and track your progress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),

              _balanceCard(
                context,
                balance: netBalance,
                income: totalIncome,
                expenses: totalExpenses,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      context,
                      title: 'Total Income',
                      amount: _money(totalIncome),
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.incomeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      context,
                      title: 'Total Expenses',
                      amount: _money(totalExpenses),
                      icon: Icons.trending_down_rounded,
                      color: AppTheme.expenseColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _sectionHeading(
                context,
                title: 'This Month',
                subtitle: 'Your income and spending this month',
              ),
              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _monthlyRow(
                        context,
                        title: 'Income',
                        amount: monthlyIncome,
                        maximum: monthlyMaximum,
                        color: AppTheme.incomeColor,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      const SizedBox(height: 24),
                      _monthlyRow(
                        context,
                        title: 'Expenses',
                        amount: monthlyExpenses,
                        maximum: monthlyMaximum,
                        color: AppTheme.expenseColor,
                        icon: Icons.arrow_upward_rounded,
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly difference',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  monthlyDifference >= 0
                                      ? 'You are saving this month'
                                      : 'Your expenses exceed income',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _money(monthlyDifference),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color:
                                    monthlyDifference >= 0
                                        ? AppTheme.incomeColor
                                        : AppTheme.expenseColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              _sectionHeading(
                context,
                title: 'Expenses by Category',
                subtitle: 'See where your money goes',
              ),
              const SizedBox(height: 14),

              if (sortedCategories.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 30,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No expense data yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your expense breakdown will appear here '
                          'when you add transactions.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        for (var i = 0; i < sortedCategories.length; i++) ...[
                          if (i > 0) const SizedBox(height: 22),
                          _categoryRow(
                            context,
                            category: sortedCategories[i].key,
                            amount: sortedCategories[i].value,
                            total: totalCategoryExpenses,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 22),

              Center(
                child: Text(
                  'Statistics update automatically when transactions change.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeading(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(
    BuildContext context, {
    required double balance,
    required double income,
    required double expenses,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'NET BALANCE',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _money(balance),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            balance >= 0
                ? 'Your income is ahead of your expenses'
                : 'Your expenses are higher than your income',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 22),
          Divider(color: Colors.white.withValues(alpha: 0.20), height: 1),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _balanceDetail(
                  context,
                  label: 'Income',
                  amount: _money(income),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _balanceDetail(
                  context,
                  label: 'Expenses',
                  amount: _money(expenses),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceDetail(
    BuildContext context, {
    required String label,
    required String amount,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.75)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          amount,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyRow(
    BuildContext context, {
    required String title,
    required double amount,
    required double maximum,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final progress = maximum > 0 ? amount / maximum : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: Text(
                _money(amount),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _categoryRow(
    BuildContext context, {
    required String category,
    required double amount,
    required double total,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final percentage = total > 0 ? amount / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _money(amount),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
