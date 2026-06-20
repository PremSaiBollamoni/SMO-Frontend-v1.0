import 'package:flutter/material.dart';

void showQrManualEntry(BuildContext context, String title, void Function(String) onSubmit) {
  final ctrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(hintText: 'Type or paste QR code', prefixIcon: Icon(Icons.qr_code)),
        autofocus: true,
        onSubmitted: (_) { Navigator.pop(ctx); onSubmit(ctrl.text.trim()); },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); onSubmit(ctrl.text.trim()); }, child: const Text('Submit')),
      ],
    ),
  );
}
