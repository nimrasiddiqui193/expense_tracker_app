import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), centerTitle: false),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().streamTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load statistics. Please check your connection.',
                  textAlign: TextAlign.center,
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Your Financial Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _summaryCard(
                context,
                title: 'Net Balance',
                amount: _money(netBalance),
                icon: Icons.account_balance_wallet_rounded,
                color: netBalance >= 0 ? Colors.green : theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      context,
                      title: 'Total Income',
                      amount: _money(totalIncome),
                      icon: Icons.trending_up_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      context,
                      title: 'Total Expenses',
                      amount: _money(totalExpenses),
                      icon: Icons.trending_down_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'This Month',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _monthlyRow(
                        context,
                        title: 'Income',
                        amount: monthlyIncome,
                        maximum:
                            monthlyIncome > monthlyExpenses
                                ? monthlyIncome
                                : monthlyExpenses,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 22),
                      _monthlyRow(
                        context,
                        title: 'Expenses',
                        amount: monthlyExpenses,
                        maximum:
                            monthlyIncome > monthlyExpenses
                                ? monthlyIncome
                                : monthlyExpenses,
                        color: theme.colorScheme.error,
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monthly difference'),
                          Flexible(
                            child: Text(
                              _money(monthlyIncome - monthlyExpenses),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    monthlyIncome >= monthlyExpenses
                                        ? Colors.green
                                        : theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Expenses by Category',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (sortedCategories.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Your expense categories will appear here '
                        'when you add expenses.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < sortedCategories.length; i++) ...[
                          if (i > 0) const SizedBox(height: 18),
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
              const SizedBox(height: 20),
              Text(
                'Statistics update automatically when transactions change.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              amount,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
  }) {
    final theme = Theme.of(context);
    final progress = maximum > 0 ? amount / maximum : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title)),
            Flexible(
              child: Text(
                _money(amount),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
    final percentage = total > 0 ? amount / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(category, style: theme.textTheme.titleSmall)),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _money(amount),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
