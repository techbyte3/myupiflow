import 'package:myupiflow/src/services/export_saver_interface.dart';

Future<ExportSavedFile> saveStringToFile(String data, String extension) async {
  // Fallback: pretend we saved somewhere in memory. Useful for tests or unsupported platforms.
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = 'upi_transactions_$timestamp.$extension';
  return ExportSavedFile(path: 'memory://$fileName', size: data.length);
}
