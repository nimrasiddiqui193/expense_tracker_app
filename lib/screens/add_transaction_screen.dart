import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  String _type = 'Expense';
  String _category = 'Food';

  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  final List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Entertainment',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Other',
  ];

  List<String> get _categories =>
      _type == 'Expense' ? _expenseCategories : _incomeCategories;

  bool get _isExpense => _type == 'Expense';

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (!mounted || _isSaving) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  void _saveTransaction() {
    if (!mounted || _isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || !amount.isFinite || amount <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final transaction = <String, dynamic>{
      'type': _type,
      'amount': amount,
      'category': _category,
      'date': _selectedDate,
      'notes': _notesController.text.trim(),
    };

    Navigator.of(context).pop(transaction);
  }

  String _formattedDate() {
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

    return '${months[_selectedDate.month - 1]} '
        '${_selectedDate.day}, ${_selectedDate.year}';
  }

  Widget _sectionLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _typeButton(String type, IconData icon) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = _type == type;

    final selectedColor =
        type == 'Expense' ? AppTheme.expenseColor : AppTheme.incomeColor;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap:
                _isSaving
                    ? null
                    : () {
                      if (_type == type) return;

                      setState(() {
                        _type = type;
                        _category = _categories.first;
                      });
                    },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: selected ? Colors.white : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    type,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? Colors.white : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final transactionColor =
        _isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction'), centerTitle: false),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                'Track your money',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add the details of your income or expense.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 25),

              // Transaction type
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _typeButton('Expense', Icons.arrow_upward_rounded),
                    _typeButton('Income', Icons.arrow_downward_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Amount card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRANSACTION AMOUNT',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _amountController,
                      enabled: !_isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: transactionColor,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rs. ',
                        hintText: '0.00',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                          color: transactionColor,
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');

                        if (amount == null || !amount.isFinite || amount <= 0) {
                          return 'Enter an amount greater than zero';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Category
              _sectionLabel('Category', theme),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: 'Select category',
                ),
                items:
                    _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged:
                    _isSaving
                        ? null
                        : (value) {
                          if (value == null) return;

                          setState(() {
                            _category = value;
                          });
                        },
              ),
              const SizedBox(height: 23),

              // Date
              _sectionLabel('Transaction Date', theme),
              InkWell(
                onTap: _isSaving ? null : _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    suffixIcon: Icon(Icons.edit_calendar_outlined),
                  ),
                  child: Text(
                    _formattedDate(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 23),

              // Notes
              _sectionLabel('Notes (Optional)', theme),
              TextFormField(
                controller: _notesController,
                enabled: !_isSaving,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'What was this transaction for?',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 25),

              // Save button
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Transaction',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
