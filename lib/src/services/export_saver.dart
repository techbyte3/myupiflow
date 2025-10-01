export 'package:myupiflow/src/services/export_saver_interface.dart';

import 'package:myupiflow/src/services/export_saver_stub.dart'
    if (dart.library.io) 'package:myupiflow/src/services/export_saver_io.dart'
    if (dart.library.html) 'package:myupiflow/src/services/export_saver_web.dart'
    as saver;

import 'package:myupiflow/src/services/export_saver_interface.dart';

Future<ExportSavedFile> saveStringToFile(String data, String extension) =>
    saver.saveStringToFile(data, extension);
