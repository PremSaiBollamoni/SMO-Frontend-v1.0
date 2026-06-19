import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';

class QrScannerCard extends StatefulWidget {
  final void Function(String) onScanned;
  final String expectedPrefix;

  const QrScannerCard({super.key, required this.onScanned, required this.expectedPrefix});

  @override
  State<QrScannerCard> createState() => _QrScannerCardState();
}

class _QrScannerCardState extends State<QrScannerCard> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;
  String? _warning;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    if (!raw.startsWith(widget.expectedPrefix)) {
      setState(() => _warning = 'Expected ${widget.expectedPrefix}-... QR. Got: $raw');
      return;
    }
    setState(() => _scanned = true);
    _ctrl.stop();
    widget.onScanned(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        clipBehavior: Clip.hardEdge,
        child: MobileScanner(controller: _ctrl, onDetect: _onDetect),
      ),
      if (_warning != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_warning!, style: const TextStyle(fontSize: 12))),
            TextButton(onPressed: () => setState(() => _warning = null), child: const Text('OK')),
          ]),
        ),
      ],
    ]);
  }
}
