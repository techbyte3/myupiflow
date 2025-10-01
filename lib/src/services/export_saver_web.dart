import 'dart:convert' as convert;
// TODO: Migrate to package:web or dart:js_interop for future compatibility.
// This file is intended for Flutter web only.
import 'dart:html' as html; // Web-only usage
import 'package:myupiflow/src/services/export_saver_interface.dart';

Future<ExportSavedFile> saveStringToFile(String data, String extension) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = 'upi_transactions_$timestamp.$extension';
  final bytes = convert.utf8.encode(data);
  final blob =
      html.Blob([bytes], extension == 'csv' ? 'text/csv' : 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = fileName;
  anchor.click();
  html.Url.revokeObjectUrl(url);
  return ExportSavedFile(path: 'download:$fileName', size: bytes.length);
}
