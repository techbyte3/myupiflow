import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:myupiflow/src/services/export_saver_interface.dart';

Future<ExportSavedFile> saveStringToFile(String data, String extension) async {
  final directory = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = 'upi_transactions_$timestamp.$extension';
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(data);
  final size = await file.length();
  return ExportSavedFile(path: file.path, size: size);
}
