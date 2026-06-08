import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'photo_editor_page.dart';
import '../app_language.dart';
import '../database_helper.dart';
import '../image_helper.dart';

class ChekiDetailPage extends StatefulWidget {
  final Map<String, dynamic> cheki;
  const ChekiDetailPage({super.key, required this.cheki});

  @override
  State<ChekiDetailPage> createState() => _ChekiDetailPageState();
}

class _ChekiDetailPageState extends State<ChekiDetailPage> {
  static const Color _accent = Color(0xFFD4537E);

  late Map<String, dynamic> _cheki;
  bool _editing = false;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  String? _photoPath;
  String? _replacedPhotoPath;

  // 推し選択
  List<Map<String, dynamic>> _idols = [];
  int? _selectedIdolId;

  @override
  void initState() {
    super.initState();
    _cheki = widget.cheki;
    _noteController = TextEditingController(
      text: _cheki['note'] as String? ?? '',
    );
    _selectedDate =
        DateTime.tryParse(_cheki['date'] as String? ?? '') ?? DateTime.now();
    _photoPath = _cheki['photo_path'] as String?;
    _selectedIdolId = _cheki['idol_id'] as int?;
    _loadIdols();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadIdols() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('idols', orderBy: 'name ASC');
    setState(() => _idols = result);
  }

  void _showPhotoOptions() {
    ImageHelper.showChekiPhotoOptions(
      context: context,
      onPicked: (path) {
        if (_photoPath != null && _photoPath != path) {
          _replacedPhotoPath = _photoPath;
        }
        setState(() => _photoPath = path);
      },
      onDelete: _photoPath != null
          ? () {
              _replacedPhotoPath = _photoPath;
              setState(() => _photoPath = null);
            }
          : null,
    );
  }

  Future<void> _openEditor() async {
    if (_photoPath == null || !File(_photoPath!).existsSync()) return;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoEditorPage(
          imagePath: _photoPath!,
          chekiId: _cheki['id'] as int,
        ),
      ),
    );

    if (result != null) {
      await FileImage(File(result)).evict();
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() => _photoPath = result);
    }
  }

  Future<void> _saveToGallery() async {
    final t = AppLanguageScope.textOf(context);
    if (_photoPath == null || !File(_photoPath!).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.noPhotoToSave)));
      return;
    }
    final success = await ImageHelper.saveToGallery(_photoPath!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? t.savedToAlbum : t.saveFailed)),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'cheki',
      {
        'idol_id': _selectedIdolId,
        'date': _selectedDate.toIso8601String(),
        'note': _noteController.text.trim(),
        'photo_path': _photoPath,
      },
      where: 'id = ?',
      whereArgs: [_cheki['id']],
    );

    if (_replacedPhotoPath != null) {
      await ImageHelper.deletePhotoFile(_replacedPhotoPath);
      _replacedPhotoPath = null;
    }

    final updated = await db.rawQuery(
      '''
      SELECT c.*, i.name as idol_name, i.color as idol_color, i.photo_path as idol_photo
      FROM cheki c
      LEFT JOIN idols i ON c.idol_id = i.id
      WHERE c.id = ?
      ''',
      [_cheki['id']],
    );
    if (updated.isNotEmpty && mounted) {
      setState(() {
        _cheki = updated.first;
        _editing = false;
      });
    }
  }

  Future<void> _delete() async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.deleteConfirm),
        content: Text(t.deleteChekiContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final db = await DatabaseHelper.instance.database;
    await db.delete('cheki', where: 'id = ?', whereArgs: [_cheki['id']]);

    await ImageHelper.deletePhotoFile(_photoPath);
    if (_photoPath != null) {
      final originalPath = _photoPath!.replaceFirst(
        RegExp(r'\.jpg$', caseSensitive: false),
        '_original.jpg',
      );
      await ImageHelper.deletePhotoFile(originalPath);
    }

    if (mounted) Navigator.pop(context, 'deleted');
  }

  void _openFullscreen() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: Hero(
                  tag: 'cheki_${_cheki['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_photoPath!), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Widget _buildIdolChips() {
    if (_idols.isEmpty) return const SizedBox();
    final t = AppLanguageScope.textOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.chooseOshi,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 未選択
            GestureDetector(
              onTap: () => setState(() => _selectedIdolId = null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedIdolId == null
                      ? _accent.withOpacity(0.12)
                      : Colors.transparent,
                  border: Border.all(
                    color: _selectedIdolId == null
                        ? _accent
                        : Colors.grey.shade300,
                    width: _selectedIdolId == null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t.unset,
                  style: TextStyle(
                    color: _selectedIdolId == null ? _accent : Colors.grey,
                    fontWeight: _selectedIdolId == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            ..._idols.map((idol) {
              final id = idol['id'] as int;
              final isSelected = _selectedIdolId == id;
              final colorHex = idol['color'] as String? ?? '#D4537E';
              final color = Color(
                int.parse(colorHex.replaceFirst('#', '0xFF')),
              );
              return GestureDetector(
                onTap: () => setState(() => _selectedIdolId = id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    idol['name'] as String,
                    style: TextStyle(
                      color: isSelected ? color : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final idolColor = Color(
      int.parse(
        (_cheki['idol_color'] as String? ?? '#D4537E').replaceFirst(
          '#',
          '0xFF',
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_editing) ...[
            TextButton(
              onPressed: _save,
              child: Text(
                t.save,
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            if (_photoPath != null) ...[
              IconButton(
                icon: const Icon(Icons.tune_outlined),
                onPressed: _openEditor,
                tooltip: t.retouch,
              ),
              IconButton(
                icon: const Icon(Icons.save_alt_outlined),
                onPressed: _saveToGallery,
                tooltip: t.saveToAlbum,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: ListView(
        children: [
          // 写真エリア
          GestureDetector(
            onTap: _editing
                ? _showPhotoOptions
                : (_photoPath != null && File(_photoPath!).existsSync()
                      ? _openFullscreen
                      : null),
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.65,
                  child: AspectRatio(
                    aspectRatio: 0.628,
                    child: _photoPath != null && File(_photoPath!).existsSync()
                        ? Hero(
                            tag: 'cheki_${_cheki['id']}',
                            child: Image.file(
                              File(_photoPath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Container(
                            color: idolColor.withOpacity(0.08),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 48,
                                  color: idolColor.withOpacity(0.4),
                                ),
                                if (_editing) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    t.tapToAddPhoto,
                                    style: TextStyle(
                                      color: idolColor.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 推し表示（非編集時）
                if (!_editing) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: idolColor.withOpacity(0.2),
                        backgroundImage:
                            _cheki['idol_photo'] != null &&
                                File(
                                  _cheki['idol_photo'] as String,
                                ).existsSync()
                            ? FileImage(File(_cheki['idol_photo'] as String))
                            : null,
                        child:
                            _cheki['idol_photo'] == null ||
                                !File(
                                  _cheki['idol_photo'] as String,
                                ).existsSync()
                            ? Text(
                                (_cheki['idol_name'] as String? ?? '?')
                                    .characters
                                    .first,
                                style: TextStyle(
                                  color: idolColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _cheki['idol_name'] as String? ?? t.unset,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 推し選択（編集時）
                if (_editing) ...[
                  _buildIdolChips(),
                  const SizedBox(height: 16),
                ],

                // 日付
                Text(
                  t.shootDate,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                _editing
                    ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_formatDate(_selectedDate)),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: _pickDate,
                      )
                    : Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                const SizedBox(height: 16),

                // Live名（非編集時）
                if (!_editing && _cheki['live_id'] != null)
                  _LiveNameWidget(liveId: _cheki['live_id'] as int),
                if (!_editing && _cheki['live_id'] != null)
                  const SizedBox(height: 16),

                // 備考
                Text(
                  t.note,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                _editing
                    ? TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      )
                    : Text(
                        _cheki['note'] != null &&
                                (_cheki['note'] as String).isNotEmpty
                            ? _cheki['note'] as String
                            : t.none,
                        style: const TextStyle(fontSize: 15),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Live名ウィジェット
class _LiveNameWidget extends StatefulWidget {
  final int liveId;
  const _LiveNameWidget({required this.liveId});

  @override
  State<_LiveNameWidget> createState() => _LiveNameWidgetState();
}

class _LiveNameWidgetState extends State<_LiveNameWidget> {
  String? _liveName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'lives',
      where: 'id = ?',
      whereArgs: [widget.liveId],
    );
    if (rows.isNotEmpty && mounted) {
      setState(() => _liveName = rows.first['name'] as String?);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_liveName == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Live', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.music_note_outlined,
              size: 16,
              color: Color(0xFFD4537E),
            ),
            const SizedBox(width: 4),
            Text(_liveName!, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }
}
