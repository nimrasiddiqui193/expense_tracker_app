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

  String _formatAmount(num amount) => 'Rs. ${amount.toStringAsFixed(2)}';

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
            title: const Text('Delete Transaction?'),
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

  Widget _buildTransactionCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final type = data['type']?.toString() ?? 'Expense';
    final category = data['category']?.toString() ?? 'Uncategorized';
    final notes = data['notes']?.toString() ?? '';
    final amount = (data['amount'] as num?) ?? 0;
    final date = _readDate(data['date']);
    final isIncome = type == 'Income';
    final theme = Theme.of(context);
    final color = isIncome ? Colors.green.shade700 : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
          ),
        ),
        title: Text(
          category,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_formatDate(date)} • $type'),
              if (notes.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
        trailing: SizedBox(
          width: 126,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'), centerTitle: false),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
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
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SegmentedButton<String>(
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
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestoreService.streamTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load transactions.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final documents = snapshot.data?.docs ?? [];
                  final transactions = _filterTransactions(documents);

                  if (transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              documents.isEmpty
                                  ? 'No transactions yet'
                                  : 'No matching transactions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              documents.isEmpty
                                  ? 'Add your first income or expense from the Home tab.'
                                  : 'Try another search term or filter.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: transactions.length,
                    itemBuilder:
                        (context, index) =>
                            _buildTransactionCard(transactions[index]),
                  );
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

    _amountController = TextEditingController(
      text: ((widget.transaction['amount'] as num?) ?? 0).toString(),
    );
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
    if (!_formKey.currentState!.validate()) return;

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
    return AlertDialog(
      title: const Text('Edit Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
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
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');

                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Enter a valid amount greater than zero';
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
                    return 'Enter a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(_formatDate(_selectedDate)),
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
                  : const Text('Save Changes'),
        ),
      ],
    );
  }
}
