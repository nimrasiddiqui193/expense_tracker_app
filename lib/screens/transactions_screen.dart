import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatAmount(num amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
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

  Future<void> _editTransaction(
    String transactionId,
    Map<String, dynamic> transaction,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => _EditTransactionDialog(
            transaction: transaction,
            onSave: (updatedData) async {
              await _firestoreService.updateTransaction(
                transactionId,
                updatedData,
              );
            },
          ),
    );

    if (!mounted || result != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Transaction updated successfully.')),
      );
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
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await _firestoreService.deleteTransaction(transactionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete transaction: $error')),
      );
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterTransactions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final data = document.data();

      final type = data['type']?.toString() ?? '';
      final category = data['category']?.toString() ?? '';
      final notes = data['notes']?.toString() ?? '';
      final query = _searchQuery.trim().toLowerCase();

      final matchesFilter = _selectedFilter == 'All' || type == _selectedFilter;

      final matchesSearch =
          query.isEmpty ||
          category.toLowerCase().contains(query) ||
          notes.toLowerCase().contains(query) ||
          type.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon:
            _searchQuery.isNotEmpty
                ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                )
                : null,
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildFilterSelector(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: 'All',
            label: Text('All'),
            icon: Icon(Icons.list_rounded),
          ),
          ButtonSegment(
            value: 'Income',
            label: Text('Income'),
            icon: Icon(Icons.south_west_rounded),
          ),
          ButtonSegment(
            value: 'Expense',
            label: Text('Expense'),
            icon: Icon(Icons.north_east_rounded),
          ),
        ],
        selected: {_selectedFilter},
        onSelectionChanged: (selection) {
          setState(() => _selectedFilter = selection.first);
        },
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final type = data['type']?.toString() ?? 'Expense';
    final category = data['category']?.toString() ?? 'Uncategorized';
    final notes = data['notes']?.toString() ?? '';
    final rawAmount = data['amount'];
    final amount = rawAmount is num ? rawAmount : 0;
    final date = _readDate(data['date']);
    final isIncome = type == 'Income';

    final accentColor = isIncome ? const Color(0xFF159B70) : colors.error;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _categoryIcon(category),
                color: accentColor,
                size: 23,
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
                    '${_formatDate(date)}  •  $type',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isIncome ? 'Income' : 'Expense',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 1),
            PopupMenuButton<String>(
              tooltip: 'Transaction options',
              onSelected: (value) {
                if (value == 'edit') {
                  _editTransaction(document.id, data);
                } else if (value == 'delete') {
                  _deleteTransaction(document.id, category);
                }
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool hasTransactions,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasTransactions
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_rounded,
                size: 38,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasTransactions
                  ? 'No matching transactions'
                  : 'No transactions yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasTransactions
                  ? 'Try another search term or choose a different filter.'
                  : 'Add your first income or expense from the Home tab.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final transactions = _filterTransactions(documents);

    if (transactions.isEmpty) {
      return _buildEmptyState(context, hasTransactions: documents.isNotEmpty);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(context, transactions[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'), centerTitle: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Search and manage all your transactions.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 17),
                  _buildSearchField(context),
                  const SizedBox(height: 13),
                  _buildFilterSelector(context),
                ],
              ),
            ),
            Expanded(
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
                              size: 46,
                              color: colors.error,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Could not load transactions.',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check your connection and Firestore rules, '
                              'then try again.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
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

                  final documents = snapshot.data?.docs ?? [];

                  return _buildTransactionList(context, documents);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTransactionDialog extends StatefulWidget {
  const _EditTransactionDialog({
    required this.transaction,
    required this.onSave,
  });

  final Map<String, dynamic> transaction;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;

  late String _selectedType;
  late DateTime _selectedDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final rawAmount = widget.transaction['amount'];
    final amount = rawAmount is num ? rawAmount : 0;

    _amountController = TextEditingController(text: amount.toString());

    _categoryController = TextEditingController(
      text: widget.transaction['category']?.toString() ?? '',
    );

    _notesController = TextEditingController(
      text: widget.transaction['notes']?.toString() ?? '',
    );

    _selectedType =
        widget.transaction['type']?.toString() == 'Income'
            ? 'Income'
            : 'Expense';

    final storedDate = widget.transaction['date'];

    if (storedDate is Timestamp) {
      _selectedDate = storedDate.toDate();
    } else if (storedDate is DateTime) {
      _selectedDate = storedDate;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) return;

    setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      await widget.onSave({
        'type': _selectedType,
        'amount': double.parse(_amountController.text.trim()),
        'category': _categoryController.text.trim(),
        'date': _selectedDate,
        'notes': _notesController.text.trim(),
      });

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update transaction: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: const Text('Edit transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your transaction details below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Transaction type',
                  prefixIcon: Icon(Icons.swap_vert_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'Income', child: Text('Income')),
                  DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                ],
                onChanged:
                    _saving
                        ? null
                        : (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs. ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');

                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Enter a valid amount greater than zero.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a category.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(_formatDate(_selectedDate)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Save changes'),
        ),
      ],
    );
  }
}
