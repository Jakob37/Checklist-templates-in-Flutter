import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/export_bundle.dart';

class IoService {
  static Future<void> exportJson(ExportBundle bundle) async {
    final jsonStr = jsonEncode(bundle.toJson());
    final fileName =
        'Checklist-templates-${DateTime.now().millisecondsSinceEpoch}.json';

    if (Platform.isAndroid) {
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonStr);
        return;
      }
    }

    // iOS and fallback: write to temp then share
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonStr);
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        text: fileName,
      ),
    );
  }

  static Future<ExportBundle?> importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return ExportBundle.fromJson(json);
  }
}
