import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../theme.dart';
import '../l10n.dart';

/// Hutengeneza faili, humwomba mtumiaji achague mahali pa kuhifadhi, kisha huonyesha matokeo.
Future<void> runExport(
  BuildContext context,
  String name,
  String ext,
  Future<List<int>> Function() build,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await build();
    final path = await ExportService.save('$name.$ext', bytes, ext);
    if (path != null) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: C.btnGreen,
        content: Text(tr('Imehifadhiwa: $path', 'Saved to: $path')),
      ));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      backgroundColor: const Color(0xFFD64560),
      content: Text(tr('Export imeshindwa: $e', 'Export failed: $e')),
    ));
  }
}
