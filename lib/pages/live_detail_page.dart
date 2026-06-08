import 'dart:io';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../database_helper.dart';

class LiveDetailPage extends StatefulWidget {
  final Map<String, dynamic> live;
  const LiveDetailPage({super.key, required this.live});

  @override
  State<LiveDetailPage> createState() => _LiveDetailPageState();
}

class _LiveDetailPageState extends State<LiveDetailPage> {
  static const Color _accent = Color(0xFFD4537E);

  late Map<String, dynamic> _live;
  bool _editing = false;

  late TextEditingController _nameController;
  late TextEditingController _venueController;
  late TextEditingController _noteController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  List<Map<String, dynamic>> _allIdols = [];
  List<Map<String, dynamic>> _allGroups = [];
  Set<int> _selectedIdolIds = {};
  Set<int> _selectedGroupIds = {};

  // 关联的チェキ
  List<Map<String, dynamic>> _linkedCheki = [];

  @override
  void initState() {
    super.initState();
    _live = widget.live;
    _nameController = TextEditingController(
      text: _live['name'] as String? ?? '',
    );
    _venueController = TextEditingController(
      text: _live['venue'] as String? ?? '',
    );
    _noteController = TextEditingController(
      text: _live['note'] as String? ?? '',
    );

    final dateStr = _live['date'] as String?;
    if (dateStr != null && dateStr.isNotEmpty) {
      _selectedDate = DateTime.tryParse(dateStr);
    }
    final timeStr = _live['time'] as String?;
    if (timeStr != null && timeStr.length == 5) {
      final parts = timeStr.split(':');
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    _loadAll();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final db = await DatabaseHelper.instance.database;
    final liveId = _live['id'] as int;

    // 全推し・全団体
    final idols = await db.query('idols', orderBy: 'name ASC');
    final groups = await db.query('groups', orderBy: 'name ASC');

    // 選択済み推し
    final liveIdols = await db.query(
      'live_idols',
      where: 'live_id = ?',
      whereArgs: [liveId],
    );
    // 選択済み団体
    final liveGroups = await db.query(
      'live_groups',
      where: 'live_id = ?',
      whereArgs: [liveId],
    );

    // 関連チェキ
    final cheki = await db.rawQuery(
      '''
      SELECT c.*, i.name as idol_name, i.color as idol_color, i.photo_path as idol_photo
      FROM cheki c
      LEFT JOIN idols i ON c.idol_id = i.id
      WHERE c.live_id = ?
      ORDER BY c.date ASC
    ''',
      [liveId],
    );

    setState(() {
      _allIdols = idols;
      _allGroups = groups;
      _selectedIdolIds = liveIdols.map((r) => r['idol_id'] as int).toSet();
      _selectedGroupIds = liveGroups.map((r) => r['group_id'] as int).toSet();
      _linkedCheki = cheki;
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? _timeString() {
    if (_selectedTime == null) return null;
    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _accent)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _accent)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    final db = await DatabaseHelper.instance.database;
    final liveId = _live['id'] as int;

    await db.update(
      'lives',
      {
        'name': _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        'venue': _venueController.text.trim().isEmpty
            ? null
            : _venueController.text.trim(),
        'date': _selectedDate != null ? _dateKey(_selectedDate!) : null,
        'time': _timeString(),
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      },
      where: 'id = ?',
      whereArgs: [liveId],
    );

    // 推し関連付け更新
    await db.delete('live_idols', where: 'live_id = ?', whereArgs: [liveId]);
    for (final idolId in _selectedIdolIds) {
      await db.insert('live_idols', {'live_id': liveId, 'idol_id': idolId});
    }

    // 団体関連付け更新
    await db.delete('live_groups', where: 'live_id = ?', whereArgs: [liveId]);
    for (final groupId in _selectedGroupIds) {
      await db.insert('live_groups', {'live_id': liveId, 'group_id': groupId});
    }

    final updated = await db.query(
      'lives',
      where: 'id = ?',
      whereArgs: [liveId],
    );
    if (updated.isNotEmpty && mounted) {
      setState(() {
        _live = updated.first;
        _editing = false;
      });
    }
  }

  Future<void> _delete() async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteConfirm),
        content: Text(t.deleteLiveContent),
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
    final liveId = _live['id'] as int;

    // チェキの live_id を null に
    await db.update(
      'cheki',
      {'live_id': null},
      where: 'live_id = ?',
      whereArgs: [liveId],
    );
    await db.delete('live_idols', where: 'live_id = ?', whereArgs: [liveId]);
    await db.delete('live_groups', where: 'live_id = ?', whereArgs: [liveId]);
    await db.delete('lives', where: 'id = ?', whereArgs: [liveId]);

    if (mounted) Navigator.pop(context, 'deleted');
  }

  // ── チェキ選択ボトムシート ────────────────────────────────────

  Future<void> _showChekiPicker() async {
    final db = await DatabaseHelper.instance.database;
    final liveId = _live['id'] as int;
    final liveDateStr = _live['date'] as String?;

    // 既に関連付け済みの cheki id
    final linked = _linkedCheki.map((c) => c['id'] as int).toSet();

    // 当日チェキ
    List<Map<String, dynamic>> todayCheki = [];
    if (liveDateStr != null) {
      todayCheki = await db.rawQuery(
        '''
        SELECT c.*, i.name as idol_name, i.color as idol_color
        FROM cheki c
        LEFT JOIN idols i ON c.idol_id = i.id
        WHERE substr(c.date, 1, 10) = ? AND c.live_id IS NULL
        ORDER BY c.date ASC
      ''',
        [liveDateStr.substring(0, 10)],
      );
    }

    // 全チェキ（live_id が null のもの）
    final allCheki = await db.rawQuery('''
      SELECT c.*, i.name as idol_name, i.color as idol_color
      FROM cheki c
      LEFT JOIN idols i ON c.idol_id = i.id
      WHERE c.live_id IS NULL
      ORDER BY c.date DESC
    ''');

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChekiPickerSheet(
        todayCheki: todayCheki,
        allCheki: allCheki,
        onSelected: (chekiId) async {
          await db.update(
            'cheki',
            {'live_id': liveId},
            where: 'id = ?',
            whereArgs: [chekiId],
          );
          await _loadAll();
        },
      ),
    );
  }

  // ── 選択チップ行 ─────────────────────────────────────────────

  Widget _buildChipRow({
    required String label,
    required List<Map<String, dynamic>> items,
    required Set<int> selectedIds,
    required void Function(int) onToggle,
    required String nameKey,
    String? colorKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final id = item['id'] as int;
            final isSelected = selectedIds.contains(id);
            final name = item[nameKey] as String? ?? '';
            Color chipColor = _accent;
            if (colorKey != null) {
              final hex = item[colorKey] as String?;
              if (hex != null) {
                chipColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
              }
            }
            return GestureDetector(
              onTap: () => onToggle(id),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? chipColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? chipColor : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── チェキサムネイル ─────────────────────────────────────────

  Widget _buildChekiGrid() {
    if (_linkedCheki.isEmpty) return const SizedBox();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.628,
      ),
      itemCount: _linkedCheki.length,
      itemBuilder: (_, index) {
        final cheki = _linkedCheki[index];
        final path = cheki['photo_path'] as String?;
        final idolColor = Color(
          int.parse(
            (cheki['idol_color'] as String? ?? '#D4537E').replaceFirst(
              '#',
              '0xFF',
            ),
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: path != null && File(path).existsSync()
              ? Image.file(File(path), fit: BoxFit.cover)
              : Container(
                  color: idolColor.withOpacity(0.12),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: idolColor.withOpacity(0.4),
                  ),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final name = _live['name'] as String? ?? t.untitled;
    final dateStr = _live['date'] as String? ?? '';
    final timeStr = _live['time'] as String? ?? '';
    final venueStr = _live['venue'] as String? ?? '';
    final noteStr = _live['note'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          name.isEmpty ? t.untitled : name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_editing) ...[
            TextButton(
              onPressed: _save,
              child: Text(
                t.save,
                style: const TextStyle(color: _accent, fontWeight: FontWeight.w600),
              ),
            ),
          ] else ...[
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
        padding: const EdgeInsets.all(16),
        children: [
          // ── 基本情報 ──
          _buildSection(
            children: _editing
                ? [
                    _buildEditField(
                      controller: _nameController,
                      label: t.liveName,
                      icon: Icons.music_note_outlined,
                    ),
                    const Divider(height: 1),
                    _buildEditField(
                      controller: _venueController,
                      label: t.venue,
                      icon: Icons.location_on_outlined,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: _accent,
                        size: 20,
                      ),
                      title: Text(t.date, style: const TextStyle(fontSize: 14)),
                      trailing: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}'
                            : t.unset,
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedDate != null
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                      onTap: _pickDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.access_time_outlined,
                        color: _accent,
                        size: 20,
                      ),
                      title: Text(t.startTime, style: const TextStyle(fontSize: 14)),
                      trailing: Text(
                        _selectedTime != null ? _timeString()! : t.unset,
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedTime != null
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                      onTap: _pickTime,
                    ),
                    const Divider(height: 1),
                    _buildEditField(
                      controller: _noteController,
                      label: t.note,
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                  ]
                : [
                    if (name.isNotEmpty)
                      _buildInfoRow(Icons.music_note_outlined, t.liveName, name),
                    if (dateStr.isNotEmpty) ...[
                      if (name.isNotEmpty) const Divider(height: 1),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        t.date,
                        dateStr,
                      ),
                    ],
                    if (timeStr.isNotEmpty) ...[
                      const Divider(height: 1),
                      _buildInfoRow(
                        Icons.access_time_outlined,
                        t.startTime,
                        timeStr,
                      ),
                    ],
                    if (venueStr.isNotEmpty) ...[
                      const Divider(height: 1),
                      _buildInfoRow(Icons.location_on_outlined, t.venue, venueStr),
                    ],
                    if (noteStr.isNotEmpty) ...[
                      const Divider(height: 1),
                      _buildInfoRow(Icons.notes_outlined, t.note, noteStr),
                    ],
                    if (name.isEmpty &&
                        dateStr.isEmpty &&
                        venueStr.isEmpty &&
                        noteStr.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          t.fieldInfoMissing,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                  ],
          ),
          const SizedBox(height: 16),

          // ── 出演者（編集時のみ選択可） ──
          if (_editing) ...[
            _buildSection(
              padding: const EdgeInsets.all(16),
              children: [
                if (_allGroups.isNotEmpty) ...[
                  _buildChipRow(
                    label: t.performingGroups,
                    items: _allGroups,
                    selectedIds: _selectedGroupIds,
                    onToggle: (id) => setState(() {
                      if (_selectedGroupIds.contains(id)) {
                        _selectedGroupIds.remove(id);
                      } else {
                        _selectedGroupIds.add(id);
                      }
                    }),
                    nameKey: 'name',
                  ),
                  const SizedBox(height: 16),
                ],
                if (_allIdols.isNotEmpty)
                  _buildChipRow(
                    label: t.performingOshi,
                    items: _allIdols,
                    selectedIds: _selectedIdolIds,
                    onToggle: (id) => setState(() {
                      if (_selectedIdolIds.contains(id)) {
                        _selectedIdolIds.remove(id);
                      } else {
                        _selectedIdolIds.add(id);
                      }
                    }),
                    nameKey: 'name',
                    colorKey: 'color',
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ] else if (_selectedGroupIds.isNotEmpty ||
              _selectedIdolIds.isNotEmpty) ...[
            _buildSection(
              padding: const EdgeInsets.all(16),
              children: [
                if (_selectedGroupIds.isNotEmpty) ...[
                  Text(
                    t.performingGroups,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allGroups
                        .where(
                          (g) => _selectedGroupIds.contains(g['id'] as int),
                        )
                        .map(
                          (g) => Chip(
                            label: Text(g['name'] as String),
                            backgroundColor: _accent.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: _accent,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (_selectedGroupIds.isNotEmpty && _selectedIdolIds.isNotEmpty)
                  const SizedBox(height: 12),
                if (_selectedIdolIds.isNotEmpty) ...[
                  Text(
                    t.performingOshi,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allIdols
                        .where((i) => _selectedIdolIds.contains(i['id'] as int))
                        .map((idol) {
                          final colorHex =
                              idol['color'] as String? ?? '#D4537E';
                          final color = Color(
                            int.parse(colorHex.replaceFirst('#', '0xFF')),
                          );
                          return Chip(
                            label: Text(idol['name'] as String),
                            backgroundColor: color.withOpacity(0.1),
                            labelStyle: TextStyle(color: color, fontSize: 12),
                          );
                        })
                        .toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── チェキ ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.navCheki,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (!_editing)
                TextButton.icon(
                  onPressed: _showChekiPicker,
                  icon: const Icon(Icons.add, size: 16, color: _accent),
                  label: Text(
                    t.add,
                    style: const TextStyle(color: _accent, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildChekiGrid(),
          if (_linkedCheki.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  t.noChekiLinked,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection({required List<Widget> children, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: padding != null
          ? Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            )
          : Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _accent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: _accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── チェキ選択シート ─────────────────────────────────────────────

class _ChekiPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> todayCheki;
  final List<Map<String, dynamic>> allCheki;
  final Future<void> Function(int chekiId) onSelected;

  const _ChekiPickerSheet({
    required this.todayCheki,
    required this.allCheki,
    required this.onSelected,
  });

  @override
  State<_ChekiPickerSheet> createState() => _ChekiPickerSheetState();
}

class _ChekiPickerSheetState extends State<_ChekiPickerSheet>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFD4537E);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildGrid(List<Map<String, dynamic>> chekiList) {
    final t = AppLanguageScope.textOf(context);
    if (chekiList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(t.noChekiAvailable, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.628,
      ),
      itemCount: chekiList.length,
      itemBuilder: (_, index) {
        final cheki = chekiList[index];
        final path = cheki['photo_path'] as String?;
        final idolColor = Color(
          int.parse(
            (cheki['idol_color'] as String? ?? '#D4537E').replaceFirst(
              '#',
              '0xFF',
            ),
          ),
        );
        return GestureDetector(
          onTap: () async {
            Navigator.pop(context);
            await widget.onSelected(cheki['id'] as int);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                path != null && File(path).existsSync()
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : Container(
                        color: idolColor.withOpacity(0.12),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: idolColor.withOpacity(0.4),
                        ),
                      ),
                // 推し名バッジ
                if (cheki['idol_name'] != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        cheki['idol_name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              t.selectCheki,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              indicatorColor: _accent,
              labelColor: _accent,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: '${t.today}（${widget.todayCheki.length}）'),
                Tab(text: '${t.all}（${widget.allCheki.length}）'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGrid(widget.todayCheki),
                  _buildGrid(widget.allCheki),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
