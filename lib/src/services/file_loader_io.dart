import 'dart:io';

Future<String> readFileString(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('File not found');
  }
  return file.readAsString();
}
