import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_picker/image_picker.dart';
import '../app_language.dart';
import '../database_helper.dart';
import 'idol_detail_page.dart';

class GroupDetailPage extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  static const Color _accent = Color(0xFFD4537E);
  late Map<String, dynamic> _group;
  List<Map<String, dynamic>> _members = [];
  int _chekiCount = 0;
  int _liveCount = 0;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final members = await db.rawQuery(
      '''SELECT i.* FROM idols i
         INNER JOIN idol_groups ig ON i.id = ig.idol_id
         WHERE ig.group_id = ? ORDER BY i.name ASC''',
      [_group['id']],
    );
    int chekiTotal = 0;
    for (final m in members) {
      final r = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM cheki WHERE idol_id = ?',
        [m['id']],
      );
      chekiTotal += Sqflite.firstIntValue(r) ?? 0;
    }
    final liveResult = await db.rawQuery(
      '''SELECT COUNT(DISTINCT li.live_id) as cnt FROM live_idols li
         INNER JOIN idol_groups ig ON li.idol_id = ig.idol_id
         WHERE ig.group_id = ?''',
      [_group['id']],
    );
    setState(() {
      _members = members;
      _chekiCount = chekiTotal;
      _liveCount = Sqflite.firstIntValue(liveResult) ?? 0;
    });
  }

  List<Map<String, String>> _parseSns() {
    final snsJson = _group['sns_json'] as String?;
    if (snsJson == null) return [];
    try {
      final decoded = jsonDecode(snsJson) as List;
      return decoded
          .map((e) => Map<String, String>.from(e as Map))
          .where(
            (e) =>
                (e['platform'] ?? '').isNotEmpty &&
                (e['handle'] ?? '').isNotEmpty,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _editGroup() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditGroupSheet(
        group: _group,
        onSaved: (_) async {
          final db = await DatabaseHelper.instance.database;
          final result = await db.query(
            'groups',
            where: 'id = ?',
            whereArgs: [_group['id']],
          );
          if (result.isNotEmpty && mounted) {
            setState(() => _group = result.first);
            _loadData();
          }
        },
      ),
    );
  }

  Future<void> _delete() async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.deleteConfirm),
        content: Text(t.deleteGroupContent(_group['name'] as String? ?? '')),
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
    await db.delete(
      'idol_groups',
      where: 'group_id = ?',
      whereArgs: [_group['id']],
    );
    await db.delete('groups', where: 'id = ?', whereArgs: [_group['id']]);
    if (mounted) Navigator.pop(context, 'deleted');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final note = _group['note'] as String?;
    final logoPath = _group['logo_path'] as String?;
    final snsList = _parseSns();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined, color: _accent, size: 18),
            ),
            onPressed: _editGroup,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                size: 18,
              ),
            ),
            onPressed: _delete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          // Hero
          Container(
            color: _accent.withOpacity(0.06),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: _accent.withOpacity(0.15),
                  backgroundImage:
                      logoPath != null && File(logoPath).existsSync()
                      ? FileImage(File(logoPath))
                      : null,
                  child: logoPath == null || !File(logoPath).existsSync()
                      ? Text(
                          (_group['name'] as String).characters.first,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _group['name'] as String,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 統計
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatCard(
                  label: t.members,
                  value: t.people(_members.length),
                  color: _accent,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: t.chekiTotal,
                  value: t.pieces(_chekiCount),
                  color: _accent,
                ),
                const SizedBox(width: 8),
                _StatCard(label: t.liveCount, value: t.times(_liveCount), color: _accent),
              ],
            ),
          ),

          // SNS
          if (snsList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: snsList.asMap().entries.map((entry) {
                    final i = entry.key;
                    final sns = entry.value;
                    return Column(
                      children: [
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Divider(height: 1, thickness: 0.5),
                          ),
                        ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              color: _accent,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            sns['platform']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '@${sns['handle']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // メンバー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              t.members,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_members.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t.noMembers,
                style: TextStyle(color: Colors.grey.shade400),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: _members.asMap().entries.map((entry) {
                    final i = entry.key;
                    final idol = entry.value;
                    final idolColor = Color(
                      int.parse(
                        (idol['color'] as String? ?? '#D4537E').replaceFirst(
                          '#',
                          '0xFF',
                        ),
                      ),
                    );
                    final idolPhoto = idol['photo_path'] as String?;
                    return Column(
                      children: [
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.only(left: 68),
                            child: Divider(height: 1, thickness: 0.5),
                          ),
                        ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: idolColor.withOpacity(0.15),
                            backgroundImage:
                                idolPhoto != null &&
                                    File(idolPhoto).existsSync()
                                ? FileImage(File(idolPhoto))
                                : null,
                            child:
                                idolPhoto == null ||
                                    !File(idolPhoto).existsSync()
                                ? Text(
                                    (idol['name'] as String).characters.first,
                                    style: TextStyle(
                                      color: idolColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            idol['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade300,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IdolDetailPage(idol: idol),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// 編集シート
class _EditGroupSheet extends StatefulWidget {
  final Map<String, dynamic> group;
  final Function(Map<String, dynamic>) onSaved;
  const _EditGroupSheet({required this.group, required this.onSaved});

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  static const Color _accent = Color(0xFFD4537E);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  String? _photoPath;
  List<Map<String, String>> _snsList = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.group['name'] as String?,
    );
    _noteController = TextEditingController(
      text: widget.group['note'] as String? ?? '',
    );
    _photoPath = widget.group['logo_path'] as String?;
    final snsJson = widget.group['sns_json'] as String?;
    if (snsJson != null) {
      try {
        final decoded = jsonDecode(snsJson) as List;
        _snsList = decoded
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'groups',
      {
        'name': _nameController.text.trim(),
        'note': _noteController.text.trim(),
        'logo_path': _photoPath,
        'sns_json': _snsList.isNotEmpty ? jsonEncode(_snsList) : null,
      },
      where: 'id = ?',
      whereArgs: [widget.group['id']],
    );
    widget.onSaved({});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.editGroup,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: _accent.withOpacity(0.12),
                      backgroundImage:
                          _photoPath != null && File(_photoPath!).existsSync()
                          ? FileImage(File(_photoPath!))
                          : null,
                      child:
                          _photoPath == null || !File(_photoPath!).existsSync()
                          ? const Icon(
                              Icons.group_outlined,
                              size: 44,
                              color: _accent,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${t.groupName} *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? t.groupNameRequired : null,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SNS',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                if (_snsList.length < 3)
                  GestureDetector(
                    onTap: () => setState(
                      () => _snsList.add({'platform': '', 'handle': ''}),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 14, color: _accent),
                          const SizedBox(width: 2),
                          Text(
                            t.add,
                            style: const TextStyle(fontSize: 12, color: _accent),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            ..._snsList.asMap().entries.map((entry) {
              final i = entry.key;
              final sns = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: TextEditingController(text: sns['platform'])
                          ..selection = TextSelection.collapsed(
                            offset: (sns['platform'] ?? '').length,
                          ),
                        decoration: InputDecoration(
                          labelText: t.platform,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (v) => _snsList[i]['platform'] = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: TextEditingController(text: sns['handle'])
                          ..selection = TextSelection.collapsed(
                            offset: (sns['handle'] ?? '').length,
                          ),
                        decoration: InputDecoration(
                          labelText: t.username,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (v) => _snsList[i]['handle'] = v,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () => setState(() => _snsList.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t.noteOptional,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
