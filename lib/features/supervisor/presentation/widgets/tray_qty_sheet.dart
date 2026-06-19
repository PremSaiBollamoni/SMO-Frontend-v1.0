import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TrayQtySheet extends StatefulWidget {
  final String empName;
  final Function(int qty) onSubmit;
  const TrayQtySheet({super.key, required this.empName, required this.onSubmit});

  static Future<int?> show(BuildContext context, String empName) =>
      showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TrayQtySheet(
          empName: empName,
          onSubmit: (qty) => Navigator.pop(context, qty),
        ),
      );

  @override
  State<TrayQtySheet> createState() => _TrayQtySheetState();
}

class _TrayQtySheetState extends State<TrayQtySheet> {
  int _qty = 50;
  final _ctrl = TextEditingController(text: '50');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _update(int val) {
    setState(() { _qty = val.clamp(1, 999); _ctrl.text = _qty.toString(); });
  }

  void _submit() {
    final q = int.tryParse(_ctrl.text.trim());
    if (q == null || q <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    widget.onSubmit(q);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),

        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bundle Quantity',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.onSurface)),
              Text(widget.empName,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 28),

        // Stepper
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _StepBtn(Icons.remove_rounded, () => _update(_qty - 1)),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => _QtyInputDialog(initial: _qty, onSet: _update),
            ),
            child: Container(
              width: 110, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$_qty',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                const Text('pieces', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(width: 20),
          _StepBtn(Icons.add_rounded, () => _update(_qty + 1)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _QuickBtn('-10', () => _update(_qty - 10)),
          const SizedBox(width: 8),
          _QuickBtn('+10', () => _update(_qty + 10)),
          const SizedBox(width: 8),
          _QuickBtn('+25', () => _update(_qty + 25)),
          const SizedBox(width: 8),
          _QuickBtn('+50', () => _update(_qty + 50)),
        ]),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Assign Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primary, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    ),
  );
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.primary.withValues(alpha: 0.05),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13)),
    ),
  );
}

class _QtyInputDialog extends StatefulWidget {
  final int initial;
  final ValueChanged<int> onSet;
  const _QtyInputDialog({required this.initial, required this.onSet});

  @override
  State<_QtyInputDialog> createState() => _QtyInputDialogState();
}

class _QtyInputDialogState extends State<_QtyInputDialog> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: '${widget.initial}');
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Enter quantity'),
    content: TextField(controller: _c, keyboardType: TextInputType.number, autofocus: true,
        decoration: const InputDecoration(suffix: Text('pcs'))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(
        onPressed: () {
          final v = int.tryParse(_c.text.trim());
          if (v != null && v > 0) { widget.onSet(v); Navigator.pop(context); }
        },
        child: const Text('Set'),
      ),
    ],
  );
}
