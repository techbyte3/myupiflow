Future<String> readFileString(String path) async {
  // Not meaningful on web without a picked file handle; use file_picker and pass content instead.
  throw UnsupportedError('Reading local file paths is not supported on web.');
}
