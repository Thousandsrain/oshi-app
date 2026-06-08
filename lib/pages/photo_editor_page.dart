import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../app_language.dart';
import '../database_helper.dart';
import 'dart:ui' as ui;

class AdjustParams {
  final double brightness;
  final double exposure;
  final double contrast;
  final double highlights;
  final double shadows;
  final double saturation;
  final double hue;
  final double temperature;
  final double sharpness;
  final double clarity;
  final double grain;
  final double whiteBalance;

  const AdjustParams({
    this.brightness = 0,
    this.exposure = 0,
    this.contrast = 0,
    this.highlights = 0,
    this.shadows = 0,
    this.saturation = 0,
    this.hue = 0,
    this.temperature = 0,
    this.sharpness = 0,
    this.clarity = 0,
    this.grain = 0,
    this.whiteBalance = 0,
  });

  AdjustParams copyWith({
    double? brightness,
    double? exposure,
    double? contrast,
    double? highlights,
    double? shadows,
    double? saturation,
    double? hue,
    double? temperature,
    double? sharpness,
    double? clarity,
    double? grain,
    double? whiteBalance,
  }) => AdjustParams(
    brightness: brightness ?? this.brightness,
    exposure: exposure ?? this.exposure,
    contrast: contrast ?? this.contrast,
    highlights: highlights ?? this.highlights,
    shadows: shadows ?? this.shadows,
    saturation: saturation ?? this.saturation,
    hue: hue ?? this.hue,
    temperature: temperature ?? this.temperature,
    sharpness: sharpness ?? this.sharpness,
    clarity: clarity ?? this.clarity,
    grain: grain ?? this.grain,
    whiteBalance: whiteBalance ?? this.whiteBalance,
  );

  Map<String, dynamic> toJson() => {
    'brightness': brightness,
    'exposure': exposure,
    'contrast': contrast,
    'highlights': highlights,
    'shadows': shadows,
    'saturation': saturation,
    'hue': hue,
    'temperature': temperature,
    'sharpness': sharpness,
    'clarity': clarity,
    'grain': grain,
    'whiteBalance': whiteBalance,
  };

  factory AdjustParams.fromJson(Map<String, dynamic> json) => AdjustParams(
    brightness: (json['brightness'] as num?)?.toDouble() ?? 0,
    exposure: (json['exposure'] as num?)?.toDouble() ?? 0,
    contrast: (json['contrast'] as num?)?.toDouble() ?? 0,
    highlights: (json['highlights'] as num?)?.toDouble() ?? 0,
    shadows: (json['shadows'] as num?)?.toDouble() ?? 0,
    saturation: (json['saturation'] as num?)?.toDouble() ?? 0,
    hue: (json['hue'] as num?)?.toDouble() ?? 0,
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
    sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0,
    clarity: (json['clarity'] as num?)?.toDouble() ?? 0,
    grain: (json['grain'] as num?)?.toDouble() ?? 0,
    whiteBalance: (json['whiteBalance'] as num?)?.toDouble() ?? 0,
  );

  bool get isDefault =>
      brightness == 0 &&
      exposure == 0 &&
      contrast == 0 &&
      highlights == 0 &&
      shadows == 0 &&
      saturation == 0 &&
      hue == 0 &&
      temperature == 0 &&
      sharpness == 0 &&
      clarity == 0 &&
      grain == 0 &&
      whiteBalance == 0;
}

class FilterPreset {
  final String name;
  final AdjustParams params;
  final int? dbId;
  const FilterPreset({required this.name, required this.params, this.dbId});
}

final List<FilterPreset> kBuiltinPresets = [
  FilterPreset(name: '无', params: const AdjustParams()),
  FilterPreset(
    name: '复古',
    params: const AdjustParams(
      brightness: -0.05,
      contrast: 0.1,
      saturation: -0.2,
      temperature: 0.15,
      highlights: -0.1,
      shadows: 0.1,
      grain: 0.2,
    ),
  ),
  FilterPreset(
    name: '胶片',
    params: const AdjustParams(
      contrast: 0.15,
      saturation: -0.1,
      temperature: 0.1,
      highlights: -0.15,
      shadows: 0.15,
      grain: 0.3,
      clarity: 0.1,
    ),
  ),
  FilterPreset(
    name: '清爽',
    params: const AdjustParams(
      brightness: 0.05,
      saturation: 0.15,
      temperature: -0.2,
      highlights: 0.1,
      clarity: 0.15,
    ),
  ),
  FilterPreset(
    name: '暖色',
    params: const AdjustParams(
      brightness: 0.05,
      saturation: 0.1,
      temperature: 0.25,
      highlights: 0.05,
      contrast: 0.05,
    ),
  ),
  FilterPreset(
    name: '黑白',
    params: const AdjustParams(saturation: -1.0, contrast: 0.2, clarity: 0.1),
  ),
  FilterPreset(
    name: '褪色',
    params: const AdjustParams(
      contrast: -0.15,
      saturation: -0.15,
      brightness: 0.1,
      highlights: -0.1,
      shadows: 0.2,
    ),
  ),
  FilterPreset(
    name: '戏剧',
    params: const AdjustParams(
      contrast: 0.3,
      saturation: 0.2,
      highlights: -0.2,
      shadows: -0.1,
      clarity: 0.2,
      sharpness: 0.15,
    ),
  ),
];

class _AdjustItem {
  final String label;
  final IconData icon;
  final double Function(AdjustParams) getValue;
  final AdjustParams Function(AdjustParams, double) setValue;
  final double min;
  const _AdjustItem({
    required this.label,
    required this.icon,
    required this.getValue,
    required this.setValue,
    this.min = -1,
  });
}

final List<_AdjustItem> kAdjustItems = [
  _AdjustItem(
    label: '白平衡',
    icon: Icons.wb_sunny_outlined,
    getValue: (p) => p.whiteBalance,
    setValue: (p, v) => p.copyWith(whiteBalance: v),
  ),
  _AdjustItem(
    label: '亮度',
    icon: Icons.brightness_6_outlined,
    getValue: (p) => p.brightness,
    setValue: (p, v) => p.copyWith(brightness: v),
  ),
  _AdjustItem(
    label: '曝光',
    icon: Icons.exposure,
    getValue: (p) => p.exposure,
    setValue: (p, v) => p.copyWith(exposure: v),
  ),
  _AdjustItem(
    label: '对比度',
    icon: Icons.contrast,
    getValue: (p) => p.contrast,
    setValue: (p, v) => p.copyWith(contrast: v),
  ),
  _AdjustItem(
    label: '高光',
    icon: Icons.highlight_outlined,
    getValue: (p) => p.highlights,
    setValue: (p, v) => p.copyWith(highlights: v),
  ),
  _AdjustItem(
    label: '阴影',
    icon: Icons.tonality_outlined,
    getValue: (p) => p.shadows,
    setValue: (p, v) => p.copyWith(shadows: v),
  ),
  _AdjustItem(
    label: '饱和度',
    icon: Icons.palette_outlined,
    getValue: (p) => p.saturation,
    setValue: (p, v) => p.copyWith(saturation: v),
  ),
  _AdjustItem(
    label: '色调',
    icon: Icons.color_lens_outlined,
    getValue: (p) => p.hue,
    setValue: (p, v) => p.copyWith(hue: v),
  ),
  _AdjustItem(
    label: '色温',
    icon: Icons.thermostat_outlined,
    getValue: (p) => p.temperature,
    setValue: (p, v) => p.copyWith(temperature: v),
  ),
  _AdjustItem(
    label: '锐化',
    icon: Icons.photo_filter_outlined,
    getValue: (p) => p.sharpness,
    setValue: (p, v) => p.copyWith(sharpness: v),
    min: 0,
  ),
  _AdjustItem(
    label: '清晰度',
    icon: Icons.blur_on_outlined,
    getValue: (p) => p.clarity,
    setValue: (p, v) => p.copyWith(clarity: v),
    min: 0,
  ),
  _AdjustItem(
    label: '颗粒',
    icon: Icons.grain_outlined,
    getValue: (p) => p.grain,
    setValue: (p, v) => p.copyWith(grain: v),
    min: 0,
  ),
];

class PhotoEditorPage extends StatefulWidget {
  final String imagePath;
  final int chekiId;
  const PhotoEditorPage({
    super.key,
    required this.imagePath,
    required this.chekiId,
  });

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Uint8List> _history = [];
  int _historyIndex = -1;
  AdjustParams _params = const AdjustParams();
  List<FilterPreset> _customPresets = [];
  bool _saving = false;
  late String _workingPath;
  late String _originalBackupPath; // 原始版本备份路径
  Uint8List? _originalBytes; // 原始版本 bytes（用于「オリジナルに戻す」）
  int? _activeAdjustIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _workingPath = widget.imagePath;
    // 备份路径：同目录下的 xxx_original.jpg
    _originalBackupPath = _workingPath.replaceFirst(
      RegExp(r'\.jpg$', caseSensitive: false),
      '_original.jpg',
    );
    _init();
  }

  Future<void> _init() async {
    final bytes = Uint8List.fromList(await File(_workingPath).readAsBytes());

    // 如果备份不存在则创建（首次进入修图）
    final backupFile = File(_originalBackupPath);
    if (!await backupFile.exists()) {
      await backupFile.writeAsBytes(bytes);
    }
    _originalBytes = Uint8List.fromList(await backupFile.readAsBytes());

    _pushHistory(bytes);
    await _loadCustomPresets();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _pushHistory(Uint8List bytes) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(bytes);
    if (_history.length > 20) _history.removeAt(0);
    _historyIndex = _history.length - 1;
  }

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  void _undo() {
    if (!_canUndo) return;
    _historyIndex--;
    _params = const AdjustParams();
    _activeAdjustIndex = null;
    setState(() {});
  }

  void _redo() {
    if (!_canRedo) return;
    _historyIndex++;
    _params = const AdjustParams();
    _activeAdjustIndex = null;
    setState(() {});
  }

  Uint8List get _currentBytes => _history[_historyIndex];

  /// 恢复到用户最初上传的原始版本
  Future<void> _revertToOriginal() async {
    if (_originalBytes == null) return;
    final t = AppLanguageScope.textOf(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.revertOriginal),
        content: Text(t.revertOriginalContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.revert, style: const TextStyle(color: Color(0xFFD4537E))),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // 清空 history，以 originalBytes 重新开始
    _history.clear();
    _historyIndex = -1;
    _pushHistory(Uint8List.fromList(_originalBytes!));
    _params = const AdjustParams();
    _activeAdjustIndex = null;
    setState(() {});
  }

  ColorFilter _buildColorFilter([AdjustParams? override]) {
    final pp = override ?? _params;
    final b = pp.brightness * 0.5;
    final e = pp.exposure * 0.5;
    final c = 1.0 + pp.contrast * 0.8;
    final s = 1.0 + pp.saturation;
    final t = pp.temperature * 0.3;
    final wb = pp.whiteBalance * 0.2;
    final hl = pp.highlights * 0.15;
    final sh = pp.shadows * 0.1;
    final bright = b + e + hl + sh;
    final sr = (1 - s) * 0.2126;
    final sg = (1 - s) * 0.7152;
    final sb = (1 - s) * 0.0722;
    return ColorFilter.matrix([
      (sr + s) * c,
      sg * c,
      sb * c,
      0,
      (bright + t + wb) * 255,
      sr * c,
      (sg + s) * c,
      sb * c,
      0,
      bright * 255,
      sr * c,
      sg * c,
      (sb + s) * c,
      0,
      (bright - t - wb) * 255,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  Future<void> _openCropper() async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(
      tempDir.path,
      'edit_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(tempPath).writeAsBytes(_currentBytes);
    if (!mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: tempPath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLanguageScope.textOf(context).cropRotate,
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
    if (cropped == null) return;
    final newBytes = Uint8List.fromList(await File(cropped.path).readAsBytes());
    _pushHistory(newBytes);
    _params = const AdjustParams();
    setState(() {});
  }

  Future<void> _applyAdjustments() async {
    if (_params.isDefault) return;
    setState(() => _saving = true);
    try {
      final codec = await ui.instantiateImageCodec(_currentBytes);
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..colorFilter = _buildColorFilter();
      canvas.drawImage(srcImage, Offset.zero, paint);
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(srcImage.width, srcImage.height);
      final byteData = await rendered.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final decoded = img.decodeImage(pngBytes);
      if (decoded == null) return;
      final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 95));

      _pushHistory(jpgBytes);
      _params = const AdjustParams();
      _activeAdjustIndex = null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_params.isDefault) await _applyAdjustments();
    setState(() => _saving = true);
    try {
      await File(_workingPath).writeAsBytes(_currentBytes);
      await FileImage(File(_workingPath)).evict();
      imageCache.clear();
      imageCache.clearLiveImages();
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'cheki',
        {'photo_path': _workingPath},
        where: 'id = ?',
        whereArgs: [widget.chekiId],
      );
      if (mounted) Navigator.pop(context, _workingPath);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadCustomPresets() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('filter_presets', orderBy: 'created_at DESC');
    _customPresets = result
        .map(
          (row) => FilterPreset(
            name: row['name'] as String,
            params: AdjustParams.fromJson(
              jsonDecode(row['params_json'] as String),
            ),
            dbId: row['id'] as int,
          ),
        )
        .toList();
  }

  Future<void> _savePreset() async {
    final t = AppLanguageScope.textOf(context);
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.presetName),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: t.presetNameHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: Text(t.save, style: const TextStyle(color: Color(0xFFD4537E))),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    await db.insert('filter_presets', {
      'name': name,
      'params_json': jsonEncode(_params.toJson()),
      'created_at': DateTime.now().toIso8601String(),
    });
    await _loadCustomPresets();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.presetSaved)));
    }
  }

  Future<void> _deletePreset(FilterPreset preset) async {
    if (preset.dbId == null) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'filter_presets',
      where: 'id = ?',
      whereArgs: [preset.dbId],
    );
    await _loadCustomPresets();
    if (mounted) setState(() {});
  }

  void _showSliderSheet(int index) {
    final item = kAdjustItems[index];
    final t = AppLanguageScope.textOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.icon,
                          color: const Color(0xFFD4537E),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.adjustName(item.label),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4537E).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        () {
                          final v = item.getValue(_params);
                          return v == 0
                              ? '0%'
                              : '${v > 0 ? '+' : ''}${(v * 100).round()}%';
                        }(),
                        style: const TextStyle(
                          color: Color(0xFFD4537E),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 24,
                    ),
                    activeTrackColor: const Color(0xFFD4537E),
                    inactiveTrackColor: Colors.grey.shade700,
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFFD4537E).withOpacity(0.2),
                  ),
                  child: Slider(
                    value: item.getValue(_params),
                    min: item.min,
                    max: 1,
                    onChanged: (v) {
                      setSheetState(() {});
                      setState(() => _params = item.setValue(_params, v));
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade700),
                        ),
                        onPressed: () {
                          setSheetState(() {});
                          setState(() => _params = item.setValue(_params, 0));
                        },
                        child: Text(
                          t.reset,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFD4537E,
                          ).withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _applyAdjustments();
                        },
                        child: Text(
                          t.apply,
                          style: const TextStyle(
                            color: Color(0xFFD4537E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPreset(FilterPreset preset) async {
    final t = AppLanguageScope.textOf(context);
    final json = jsonEncode({
      'name': preset.name,
      'params': preset.params.toJson(),
      'app': t.appName,
    });
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, '${preset.name}.cheki');
    await File(path).writeAsString(json);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '「${t.photoPreset(preset.name)}」${t.export}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4537E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.ios_share_outlined,
                  color: Color(0xFFD4537E),
                  size: 20,
                ),
              ),
              title: Text(t.share, style: const TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                await Share.shareXFiles([
                  XFile(path),
                ], text: '${t.presetShareTextPrefix}: ${t.photoPreset(preset.name)}');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.download_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: Text(
                'Download',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final oshiDir = Directory(
                    '/storage/emulated/0/Download/oshi/filter',
                  );
                  if (!oshiDir.existsSync())
                    await oshiDir.create(recursive: true);
                  final destPath = p.join(oshiDir.path, '${preset.name}.cheki');
                  await File(path).copy(destPath);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Download/oshi/filter: ${preset.name}.cheki',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.saveFailedTryShare)),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _importPreset() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    try {
      final content = await File(path).readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final name = json['name'] as String? ?? AppLanguageScope.textOf(context).import;
      final params = AdjustParams.fromJson(
        json['params'] as Map<String, dynamic>? ?? {},
      );
      final db = await DatabaseHelper.instance.database;
      await db.insert('filter_presets', {
        'name': name,
        'params_json': jsonEncode(params.toJson()),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _loadCustomPresets();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLanguageScope.textOf(context).importedPreset(name))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLanguageScope.textOf(context).importFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    if (_history.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4537E)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          t.edit,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          // オリジナルに戻すボタン
          if (_originalBytes != null)
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white70),
              tooltip: t.revertOriginal,
              onPressed: _revertToOriginal,
            ),
          IconButton(
            icon: Icon(
              Icons.undo,
              color: _canUndo ? Colors.white : Colors.grey.shade700,
            ),
            onPressed: _canUndo ? _undo : null,
          ),
          IconButton(
            icon: Icon(
              Icons.redo,
              color: _canRedo ? Colors.white : Colors.grey.shade700,
            ),
            onPressed: _canRedo ? _redo : null,
          ),
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD4537E),
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFD4537E,
                      ).withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                    ),
                    onPressed: _save,
                    child: Text(
                      t.save,
                      style: const TextStyle(
                        color: Color(0xFFD4537E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // 图片预览
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeAdjustIndex = null),
              child: Center(
                child: ColorFiltered(
                  colorFilter: _buildColorFilter(),
                  child: Image.memory(
                    _currentBytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),

          // 底部面板
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFD4537E),
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: const Color(0xFFD4537E),
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.crop_rounded, size: 20),
                      text: t.crop,
                    ),
                    Tab(icon: const Icon(Icons.tune_rounded, size: 20), text: t.adjust),
                    Tab(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      text: t.filter,
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: _activeAdjustIndex != null ? 300 : 180,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCropTab(),
                      OverflowBox(
                        maxHeight: 500,
                        minHeight: 0,
                        alignment: Alignment.topCenter,
                        child: _buildAdjustTab(),
                      ),
                      _buildFilterTab(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropTab() {
    final t = AppLanguageScope.textOf(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD4537E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _openCropper,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.crop_rounded,
                        color: Color(0xFFD4537E),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.openCropRotate,
                        style: const TextStyle(
                          color: Color(0xFFD4537E),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustTab() {
    final t = AppLanguageScope.textOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: kAdjustItems.length,
            itemBuilder: (context, index) {
              final item = kAdjustItems[index];
              final value = item.getValue(_params);
              final isActive = _activeAdjustIndex == index;
              final hasValue = value != 0;
              return GestureDetector(
                onTap: () {
                  if (isActive) {
                    setState(() => _activeAdjustIndex = null);
                  } else {
                    setState(() => _activeAdjustIndex = index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD4537E).withOpacity(0.2)
                        : hasValue
                        ? const Color(0xFFD4537E).withOpacity(0.08)
                        : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFD4537E)
                          : hasValue
                          ? const Color(0xFFD4537E).withOpacity(0.4)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive
                            ? const Color(0xFFD4537E)
                            : hasValue
                            ? const Color(0xFFD4537E).withOpacity(0.8)
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasValue
                            ? '${(value * 100).round()}%'
                            : t.adjustName(item.label),
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFFD4537E)
                              : hasValue
                              ? const Color(0xFFD4537E).withOpacity(0.8)
                              : Colors.grey.shade500,
                          fontSize: 9,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (_activeAdjustIndex != null) ...[
          const Divider(color: Color(0xFF3A3A3C), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Builder(
              builder: (_) {
                final item = kAdjustItems[_activeAdjustIndex!];
                final value = item.getValue(_params);
                final pct = value == 0
                    ? '0%'
                    : '${value > 0 ? '+' : ''}${(value * 100).round()}%';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.icon,
                              color: const Color(0xFFD4537E),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t.adjustName(item.label),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4537E).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pct,
                            style: const TextStyle(
                              color: Color(0xFFD4537E),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 20,
                        ),
                        activeTrackColor: const Color(0xFFD4537E),
                        inactiveTrackColor: Colors.grey.shade700,
                        thumbColor: Colors.white,
                        overlayColor: const Color(0xFFD4537E).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: item.getValue(_params),
                        min: item.min,
                        max: 1,
                        onChanged: (v) =>
                            setState(() => _params = item.setValue(_params, v)),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Colors.grey.shade700),
                            ),
                            onPressed: () => setState(
                              () => _params = item.setValue(_params, 0),
                            ),
                            child: Text(
                              t.reset,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFD4537E,
                              ).withOpacity(0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _applyAdjustments,
                            child: Text(
                              t.apply,
                              style: const TextStyle(
                                color: Color(0xFFD4537E),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade700),
                    ),
                    onPressed: () =>
                        setState(() => _params = const AdjustParams()),
                    child: Text(
                      t.resetAll,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFD4537E,
                      ).withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _applyAdjustments,
                    child: Text(
                      t.apply,
                      style: const TextStyle(
                        color: Color(0xFFD4537E),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterTab() {
    final t = AppLanguageScope.textOf(context);
    final allPresets = [...kBuiltinPresets, ..._customPresets];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _filterAction(Icons.save_outlined, t.savePreset, _savePreset),
              _filterAction(
                Icons.file_download_outlined,
                t.import,
                _importPreset,
              ),
              if (_customPresets.isNotEmpty)
                _filterAction(
                  Icons.ios_share_outlined,
                  t.export,
                  _showExportSheet,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: allPresets.length,
            itemBuilder: (context, index) {
              final preset = allPresets[index];
              final isCustom = preset.dbId != null;
              final isSelected = _params == preset.params;
              return GestureDetector(
                onTap: () => setState(() => _params = preset.params),
                onLongPress: isCustom ? () => _showPresetOptions(preset) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4537E)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4537E,
                                    ).withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ColorFiltered(
                            colorFilter: _buildColorFilter(preset.params),
                            child: Image.memory(
                              _currentBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        t.photoPreset(preset.name),
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFD4537E)
                              : Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCustom)
                        Text(
                          t.custom,
                          style: TextStyle(
                            color: const Color(0xFFD4537E).withOpacity(0.7),
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.grey.shade400, size: 20),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPresetOptions(FilterPreset preset) {
    final t = AppLanguageScope.textOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.ios_share_outlined,
                color: Colors.white70,
              ),
              title: Text(
                t.export,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _exportPreset(preset);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(t.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deletePreset(preset);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showExportSheet() {
    final t = AppLanguageScope.textOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t.selectPresetToExport,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ..._customPresets.map(
              (preset) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4537E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFD4537E),
                    size: 18,
                  ),
                ),
                title: Text(
                  preset.name,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportPreset(preset);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

Future<Uint8List> _processImageIsolate(Map<String, dynamic> data) async {
  final bytes = data['bytes'] as Uint8List;
  final paramsJson = data['params'] as Map<String, dynamic>;
  final pp = AdjustParams.fromJson(paramsJson);
  var image = img.decodeImage(bytes);
  if (image == null) return bytes;

  final brightnessAmount = ((pp.brightness + pp.exposure) * 0.5 * 255).round();
  if (brightnessAmount != 0) {
    image = img.adjustColor(image, brightness: brightnessAmount);
  }
  if (pp.contrast != 0) {
    image = img.adjustColor(image, contrast: 1.0 + pp.contrast * 0.8);
  }
  if (pp.saturation != 0) {
    image = img.adjustColor(image, saturation: 1.0 + pp.saturation);
  }
  if (pp.temperature != 0 || pp.whiteBalance != 0) {
    final warmth = ((pp.temperature + pp.whiteBalance) * 30).round();
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r + warmth).clamp(0, 255).toInt();
        final b = (pixel.b - warmth).clamp(0, 255).toInt();
        image.setPixelRgb(x, y, r, pixel.g.toInt(), b);
      }
    }
  }
  if (pp.sharpness > 0) {
    final s = pp.sharpness;
    image = img.convolution(
      image,
      filter: [0, -s, 0, -s, 1 + 4 * s, -s, 0, -s, 0],
      div: 1,
    );
  }
  if (pp.grain > 0) {
    final random = Random();
    final grainAmount = (pp.grain * 25).round();
    if (grainAmount > 0) {
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final noise = random.nextInt(grainAmount * 2) - grainAmount;
          image.setPixelRgb(
            x,
            y,
            (pixel.r + noise).clamp(0, 255).toInt(),
            (pixel.g + noise).clamp(0, 255).toInt(),
            (pixel.b + noise).clamp(0, 255).toInt(),
          );
        }
      }
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}
