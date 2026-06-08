import 'dart:io';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../database_helper.dart';
import '../image_helper.dart';

class AddChekiPage extends StatefulWidget {
  const AddChekiPage({super.key});

  @override
  State<AddChekiPage> createState() => _AddChekiPageState();
}

class _AddChekiPageState extends State<AddChekiPage> {
  List<Map<String, dynamic>> _idols = [];
  int? _selectedIdolId;
  DateTime _selectedDate = DateTime.now();
  final _noteController = TextEditingController();
  String? _photoPath;
  bool _saved = false; // 标记是否已成功保存到 DB

  @override
  void initState() {
    super.initState();
    _loadIdols();
  }

  @override
  void dispose() {
    _noteController.dispose();
    // A：页面销毁时若图片未保存到 DB，立即删除临时文件
    if (!_saved && _photoPath != null) {
      ImageHelper.deletePhotoFile(_photoPath);
    }
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
        // 换图时删除旧的临时文件
        if (_photoPath != null && _photoPath != path) {
          ImageHelper.deletePhotoFile(_photoPath);
        }
        setState(() => _photoPath = path);
      },
      onDelete: _photoPath != null
          ? () {
              ImageHelper.deletePhotoFile(_photoPath);
              setState(() => _photoPath = null);
            }
          : null,
    );
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
    await db.insert('cheki', {
      'idol_id': _selectedIdolId,
      'date': _selectedDate.toIso8601String(),
      'note': _noteController.text.trim(),
      'photo_path': _photoPath,
    });
    _saved = true; // 标记已保存，dispose 时不删除文件
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.addCheki),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(t.save, style: const TextStyle(color: Color(0xFFD4537E))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 照片区域 - Instax Mini比例
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: AspectRatio(
                aspectRatio: 0.628,
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _photoPath != null && File(_photoPath!).existsSync()
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_photoPath!), fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: _showPhotoOptions,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: const Color(0xFFD4537E).withOpacity(0.08),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 48,
                                  color: Color(0xFFD4537E),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t.tapToAddPhoto,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 选推し
          Text(
            t.chooseOshi,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (_idols.isEmpty)
            Text(t.addOshiFirst, style: const TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _idols.map((idol) {
                final isSelected = _selectedIdolId == idol['id'];
                final color = Color(
                  int.parse(
                    (idol['color'] as String? ?? '#D4537E').replaceFirst(
                      '#',
                      '0xFF',
                    ),
                  ),
                );
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedIdolId = idol['id'] as int),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
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
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // 选日期
          Text(t.shootDate, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const Divider(),
          const SizedBox(height: 8),

          // 备注
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: t.noteOptional,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
