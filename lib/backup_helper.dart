import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';

class BackupHelper {
  static Future<String?> createBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/oshi_app.db');

      final encoder = ZipFileEncoder();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final fileName = 'oshi_backup_$timestamp.zip';
      final tempPath = '${appDir.path}/$fileName';
      encoder.create(tempPath);

      if (dbFile.existsSync()) {
        encoder.addFile(dbFile, 'database/oshi_app.db');
      }

      final imgDir = Directory(appDir.path);
      final images = imgDir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'),
      );
      for (final img in images) {
        encoder.addFile(img, 'images/${img.uri.pathSegments.last}');
      }

      encoder.close();

      // 同时保存到Downloads文件夹
      final oshiDir = Directory('/storage/emulated/0/Download/oshi/backup');
      if (!oshiDir.existsSync()) oshiDir.createSync(recursive: true);
      await File(tempPath).copy('${oshiDir.path}/$fileName');

      return tempPath;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> restoreBackup(
    String? zipPath, {
    String? dialogTitle,
  }) async {
    try {
      // 如果没有传路径，让用户选择文件
      String? path = zipPath;
      if (path == null) {
        final result = await FilePicker.platform.pickFiles(
          dialogTitle: dialogTitle ?? '选择备份文件',
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (result == null || result.files.isEmpty) return false;
        path = result.files.first.path;
        if (path == null) return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();

      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      await DatabaseHelper.instance.close();
      final restoredImageNames = <String>{};

      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          if (file.name.startsWith('database/')) {
            final outFile = File('$dbPath/oshi_app.db');
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(data, flush: true);
          } else if (file.name.startsWith('images/')) {
            final fileName = file.name.split('/').last;
            final outFile = File('${appDir.path}/$fileName');
            await outFile.writeAsBytes(data, flush: true);
            restoredImageNames.add(fileName);
          }
        }
      }
      await _repairRestoredImagePaths(appDir.path, restoredImageNames);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _repairRestoredImagePaths(
    String appDirPath,
    Set<String> restoredImageNames,
  ) async {
    if (restoredImageNames.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    await _repairPathColumn(
      db,
      appDirPath,
      restoredImageNames,
      table: 'cheki',
      column: 'photo_path',
    );
    await _repairPathColumn(
      db,
      appDirPath,
      restoredImageNames,
      table: 'idols',
      column: 'photo_path',
    );
    await _repairPathColumn(
      db,
      appDirPath,
      restoredImageNames,
      table: 'groups',
      column: 'logo_path',
    );
    await _repairPathColumn(
      db,
      appDirPath,
      restoredImageNames,
      table: 'lives',
      column: 'photo_path',
    );
  }

  static Future<void> _repairPathColumn(
    Database db,
    String appDirPath,
    Set<String> restoredImageNames, {
    required String table,
    required String column,
  }) async {
    final rows = await db.query(table, columns: ['id', column]);
    for (final row in rows) {
      final oldPath = row[column] as String?;
      if (oldPath == null || oldPath.isEmpty) continue;

      final fileName = p.basename(oldPath.replaceAll('\\', '/'));
      if (!restoredImageNames.contains(fileName)) continue;

      final newPath = p.join(appDirPath, fileName);
      if (oldPath == newPath || !File(newPath).existsSync()) continue;

      await db.update(
        table,
        {column: newPath},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  static Future<List<String>> listBackups() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(appDir.path)
        .listSync()
        .whereType<File>()
        .where(
          (f) => f.path.contains('oshi_backup_') && f.path.endsWith('.zip'),
        )
        .map((f) => f.path)
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  static Future<bool> deleteBackup(String path) async {
    try {
      await File(path).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
