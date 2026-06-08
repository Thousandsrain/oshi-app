import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'app_language.dart';
import 'pages/edge_detection_page.dart';
import 'database_helper.dart';

class ImageHelper {
  // 上传已扫描图片+普通裁剪（跳过边缘检测）
  static Future<String?> pickScannedPhoto({
    required BuildContext context,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (picked == null) return null;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppLanguageScope.textOf(context).cropPhoto,
            toolbarColor: const Color(0xFFD4537E),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFD4537E),
            lockAspectRatio: false,
            statusBarColor: const Color(0xFFB03060),
            backgroundColor: Colors.black,
            showCropGrid: true,
          ),
        ],
      );
      if (cropped == null) return null;
      return await _saveToAppDir(cropped.path);
    } catch (e) {
      return null;
    }
  }

  // 相机拍摄+手动裁剪（跳过边缘检测）
  static Future<String?> captureAndCropManually({
    required BuildContext context,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (picked == null) return null;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppLanguageScope.textOf(context).cropPhoto,
            toolbarColor: const Color(0xFFD4537E),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFD4537E),
            lockAspectRatio: false,
            statusBarColor: const Color(0xFFB03060),
            backgroundColor: Colors.black,
            showCropGrid: true,
          ),
        ],
      );
      if (cropped == null) return null;
      return await _saveToAppDir(cropped.path);
    } catch (e) {
      return null;
    }
  }

  // 头像用：普通裁剪（1:1）
  static Future<String?> pickAndCropAvatar({
    required BuildContext context,
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked == null) return null;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppLanguageScope.textOf(context).adjustPhoto,
            toolbarColor: const Color(0xFFD4537E),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFD4537E),
            lockAspectRatio: true,
            statusBarColor: const Color(0xFFB03060),
            backgroundColor: Colors.black,
          ),
        ],
      );
      if (cropped == null) return null;
      return await _saveToAppDir(cropped.path);
    } catch (e) {
      return null;
    }
  }

  static Future<String> _saveToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = '${appDir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// 删除单个图片文件（安全删除，不存在时静默忽略）
  static Future<void> deletePhotoFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// 兜底垃圾回收：扫描应用目录中所有 img_ 开头的文件，
  /// 对比 DB 里 cheki、idols、groups 表中引用的所有路径，
  /// 删除没有被任何记录引用的孤儿文件。
  /// 在应用启动时异步调用，不阻塞 UI。
  static Future<void> cleanOrphanFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final db = await DatabaseHelper.instance.database;

      // 收集 DB 中所有被引用的路径
      final usedPaths = <String>{};

      // cheki.photo_path
      final chekiRows = await db.query('cheki', columns: ['photo_path']);
      for (final row in chekiRows) {
        final path = row['photo_path'] as String?;
        if (path != null) usedPaths.add(path);
      }

      // idols.photo_path
      final idolRows = await db.query('idols', columns: ['photo_path']);
      for (final row in idolRows) {
        final path = row['photo_path'] as String?;
        if (path != null) usedPaths.add(path);
      }

      // groups.logo_path
      final groupRows = await db.query('groups', columns: ['logo_path']);
      for (final row in groupRows) {
        final path = row['logo_path'] as String?;
        if (path != null) usedPaths.add(path);
      }

      // 扫描应用目录，删除 img_ 开头且未被引用的文件
      final dir = Directory(appDir.path);
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!name.startsWith('img_')) continue;
        if (!usedPaths.contains(entity.path)) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static Future<bool> saveToGallery(String imagePath) async {
    try {
      const platform = MethodChannel('com.qianyu.oshiapp/media');
      final result = await platform.invokeMethod('saveToGallery', {
        'filePath': imagePath,
      });
      return result as bool;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _pickAndOpenEdgeDetection({
    required BuildContext context,
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 3000,
      maxHeight: 3000,
      imageQuality: 95,
      requestFullMetadata: false,
    );
    if (picked == null) return null;
    if (!context.mounted) return null;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EdgeDetectionPage(imagePath: picked.path),
      ),
    );
    if (result == null) return null;
    return await _saveToAppDir(result);
  }

  // チェキ专用：四种上传方式
  static void showChekiPhotoOptions({
    required BuildContext context,
    required Function(String) onPicked,
    VoidCallback? onDelete,
  }) {
    final t = AppLanguageScope.textOf(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                t.addPhoto,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            // 拍照+自动识别（テスト中）
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFD4537E),
              ),
              title: Text(t.shootAutoDetect),
              subtitle: Text(
                t.shootAutoDetectSub,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await _pickAndOpenEdgeDetection(
                  context: context,
                  source: ImageSource.camera,
                );
                if (path != null) onPicked(path);
              },
            ),
            // 相册选取+自动识别（テスト中）
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFFD4537E),
              ),
              title: Text(t.albumAutoDetect),
              subtitle: Text(
                t.albumAutoDetectSub,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await _pickAndOpenEdgeDetection(
                  context: context,
                  source: ImageSource.gallery,
                );
                if (path != null) onPicked(path);
              },
            ),
            // 相机拍摄+手动裁剪
            ListTile(
              leading: const Icon(
                Icons.camera_outlined,
                color: Color(0xFFD4537E),
              ),
              title: Text(t.shootManualCrop),
              subtitle: Text(
                t.shootManualCropSub,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await captureAndCropManually(context: context);
                if (path != null) onPicked(path);
              },
            ),
            // 已扫描图片（相册）
            ListTile(
              leading: const Icon(
                Icons.crop_outlined,
                color: Color(0xFFD4537E),
              ),
              title: Text(t.uploadScannedPhoto),
              subtitle: Text(
                t.uploadScannedPhotoSub,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await pickScannedPhoto(context: context);
                if (path != null) onPicked(path);
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(t.deletePhoto, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 头像专用选项
  static void showPhotoOptions({
    required BuildContext context,
    required Function(ImageSource) onPick,
    VoidCallback? onDelete,
  }) {
    final t = AppLanguageScope.textOf(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(t.shootPhoto),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.chooseFromAlbum),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.gallery);
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(t.deletePhoto, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }
}
