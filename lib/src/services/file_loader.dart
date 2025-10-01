import 'package:myupiflow/src/services/file_loader_stub.dart'
    if (dart.library.io) 'package:myupiflow/src/services/file_loader_io.dart'
    if (dart.library.html) 'package:myupiflow/src/services/file_loader_web.dart'
    as loader;

Future<String> readFileString(String path) => loader.readFileString(path);
