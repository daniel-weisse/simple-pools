import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

abstract interface class FileService {
  Future<String?> importJson();
  Future<void> export(String filename, Uint8List bytes, String extension);
}

class LocalFileService implements FileService {
  @override
  Future<String?> importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > 20 * 1024 * 1024) {
      throw const FormatException('Backup exceeds 20 MB');
    }
    return utf8.decode(file.bytes!);
  }

  @override
  Future<void> export(
    String filename,
    Uint8List bytes,
    String extension,
  ) async {
    await FilePicker.platform.saveFile(
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
  }
}
