import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/seed/category_seed.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../providers/money_provider.dart';

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTransactionSheet(),
  );
}

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet();

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  bool _isExpense = true;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedSlug;
  DateTime _date = DateTime.now();

  List<MoneyCategory> get _categories =>
      _isExpense ? kDefaultExpenseCategories : kDefaultIncomeCategories;

  @override
  void initState() {
    super.initState();
    _selectedSlug = kDefaultExpenseCategories.first.slug;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: kBgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kTextHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Add Transaction',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Expense / Income toggle
          Container(
            decoration: BoxDecoration(
              color: kBgTertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _TypeTab(
                  label: 'Expense',
                  selected: _isExpense,
                  color: const Color(0xFFF87171),
                  onTap: () {
                    setState(() {
                      _isExpense = true;
                      _selectedSlug = kDefaultExpenseCategories.first.slug;
                    });
                  },
                ),
                _TypeTab(
                  label: 'Income',
                  selected: !_isExpense,
                  color: const Color(0xFF34D399),
                  onTap: () {
                    setState(() {
                      _isExpense = false;
                      _selectedSlug = kDefaultIncomeCategories.first.slug;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Amount input
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            style: const TextStyle(
                color: kTextPrimary, fontSize: 28, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700),
              hintText: '0',
              hintStyle: const TextStyle(color: kTextHint, fontSize: 28),
              filled: true,
              fillColor: kBgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Category grid
          const Text('Category',
              style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = cat.slug == _selectedSlug;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlug = cat.slug),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withAlpha(40)
                        : kBgTertiary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? cat.color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, color: cat.color, size: 16),
                      const SizedBox(width: 6),
                      Text(cat.name,
                          style: TextStyle(
                              color: isSelected ? cat.color : kTextSecondary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Note + date row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Note (optional)',
                    hintStyle: const TextStyle(color: kTextHint),
                    filled: true,
                    fillColor: kBgTertiary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: kBgTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: kTextSecondary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _dateLabel(_date),
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: kAccentPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Transaction',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kAccentPurple,
            surface: kBgSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final raw = double.tryParse(_amountCtrl.text.trim());
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final note = _noteCtrl.text.trim();
    final tx = MoneyTransaction(
      id: 0,
      amount: raw,
      isExpense: _isExpense,
      categorySlug: _selectedSlug ?? (_isExpense ? 'other_exp' : 'other_inc'),
      note: note.isEmpty ? null : note,
      date: _date,
      createdAt: DateTime.now(),
    );
    ref.read(transactionsProvider.notifier).add(tx);
    Navigator.of(context).pop();
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    return '${d.day} ${_mon(d.month)}';
  }

  static String _mon(int m) => const [
        '',
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
        'Dec'
      ][m];
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: color.withAlpha(80), width: 1)
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : kTextSecondary,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
