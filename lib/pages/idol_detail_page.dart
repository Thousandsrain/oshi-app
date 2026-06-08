import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../app_language.dart';
import '../database_helper.dart';
import 'edit_idol_page.dart';
import 'cheki_detail_page.dart';

class IdolDetailPage extends StatefulWidget {
  final Map<String, dynamic> idol;
  const IdolDetailPage({super.key, required this.idol});

  @override
  State<IdolDetailPage> createState() => _IdolDetailPageState();
}

class _IdolDetailPageState extends State<IdolDetailPage> {
  static const Color _accent = Color(0xFFD4537E);

  late Map<String, dynamic> _idol;
  int _chekiCount = 0;
  int _liveCount = 0;
  String _lastLive = '';
  List<String> _groupNames = [];
  List<Map<String, dynamic>> _recentCheki = [];

  @override
  void initState() {
    super.initState();
    _idol = widget.idol;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;
    final chekiResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM cheki WHERE idol_id = ?',
      [_idol['id']],
    );
    final liveResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM live_idols WHERE idol_id = ?',
      [_idol['id']],
    );
    final lastLiveResult = await db.rawQuery(
      '''SELECT l.date FROM lives l
         INNER JOIN live_idols li ON l.id = li.live_id
         WHERE li.idol_id = ? ORDER BY l.date DESC LIMIT 1''',
      [_idol['id']],
    );
    final groupResult = await db.rawQuery(
      '''SELECT g.name FROM groups g
         INNER JOIN idol_groups ig ON g.id = ig.group_id
         WHERE ig.idol_id = ?''',
      [_idol['id']],
    );
    // LIMIT 6 を削除 — 全チェキを表示
    final allCheki = await db.rawQuery(
      '''SELECT c.*, i.name as idol_name, i.color as idol_color, i.photo_path as idol_photo
         FROM cheki c LEFT JOIN idols i ON c.idol_id = i.id
         WHERE c.idol_id = ? ORDER BY c.date DESC''',
      [_idol['id']],
    );
    setState(() {
      _chekiCount = Sqflite.firstIntValue(chekiResult) ?? 0;
      _liveCount = Sqflite.firstIntValue(liveResult) ?? 0;
      _groupNames = groupResult.map((r) => r['name'] as String).toList();
      _recentCheki = allCheki;
      if (lastLiveResult.isNotEmpty) {
        final dateStr = lastLiveResult.first['date'] as String?;
        if (dateStr != null) {
          final d = DateTime.tryParse(dateStr);
          if (d != null)
            _lastLive =
                '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
        }
      }
    });
  }

  String _calcHistory() {
    final startStr = _idol['start_date'] as String?;
    if (startStr == null) return '';
    final start = DateTime.tryParse(startStr);
    if (start == null) return '';
    final diff = DateTime.now().difference(start);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    final t = AppText(appLanguageController.language);
    if (years > 0) return t.historyLabel(t.yearsMonths(years, months));
    if (months > 0) return t.historyLabel(t.months(months));
    return t.historyLabel(t.days(diff.inDays));
  }

  List<Map<String, String>> _parseSns() {
    final snsJson = _idol['sns_json'] as String?;
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

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final color = Color(
      int.parse(
        (_idol['color'] as String? ?? '#D4537E').replaceFirst('#', '0xFF'),
      ),
    );
    final history = _calcHistory();
    final photoPath = _idol['photo_path'] as String?;
    final birthday = _idol['birthday'] as String?;
    final note = _idol['note'] as String?;
    final snsList = _parseSns();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: _accent,
                  size: 18,
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditIdolPage(idol: _idol)),
                );
                if (result == true) {
                  final db = await DatabaseHelper.instance.database;
                  final updated = await db.query(
                    'idols',
                    where: 'id = ?',
                    whereArgs: [_idol['id']],
                  );
                  if (updated.isNotEmpty) {
                    setState(() => _idol = updated.first);
                    _loadStats();
                  }
                } else if (result == 'deleted') {
                  if (mounted) Navigator.pop(context, true);
                }
              },
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Hero
          Container(
            color: color.withOpacity(0.06),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: color.withOpacity(0.15),
                  backgroundImage:
                      photoPath != null && File(photoPath).existsSync()
                      ? FileImage(File(photoPath))
                      : null,
                  child: photoPath == null || !File(photoPath).existsSync()
                      ? Text(
                          (_idol['name'] as String).characters.first,
                          style: TextStyle(
                            color: color,
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
                        _idol['name'] as String,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_groupNames.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _groupNames.join(' · '),
                          style: TextStyle(
                            fontSize: 13,
                            color: color.withOpacity(0.8),
                          ),
                        ),
                      ],
                      if (history.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            history,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
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
                  label: t.navCheki,
                  value: t.pieces(_chekiCount),
                  color: color,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: t.liveCount,
                  value: t.times(_liveCount),
                  color: color,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: t.lastLive,
                  value: _lastLive.isEmpty ? t.none : _lastLive,
                  color: color,
                ),
              ],
            ),
          ),

          // 詳細情報
          if (birthday != null && birthday.isNotEmpty ||
              _groupNames.isNotEmpty ||
              snsList.isNotEmpty ||
              note != null && note.isNotEmpty)
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
                  children: [
                    if (birthday != null && birthday.isNotEmpty)
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        label: t.birthday,
                        value: '${birthday.replaceAll('/', '月')}日',
                        color: color,
                      ),
                    if (_groupNames.isNotEmpty) ...[
                      if (birthday != null && birthday.isNotEmpty)
                        const _RowDivider(),
                      _InfoRow(
                        icon: Icons.group_outlined,
                        label: t.affiliation,
                        value: _groupNames.join(' · '),
                        color: color,
                      ),
                    ],
                    ...snsList.asMap().entries.map((entry) {
                      final sns = entry.value;
                      return Column(
                        children: [
                          const _RowDivider(),
                          _InfoRow(
                            icon: Icons.link_rounded,
                            label: sns['platform']!,
                            value: '@${sns['handle']}',
                            color: color,
                          ),
                        ],
                      );
                    }),
                    if (note != null && note.isNotEmpty) ...[
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.notes_outlined,
                        label: t.note,
                        value: note,
                        color: color,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // チェキ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.navCheki,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_chekiCount > 0)
                  Text(
                    t.pieces(_chekiCount),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          if (_chekiCount == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                t.noCheki,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.628,
                ),
                itemCount: _recentCheki.length,
                itemBuilder: (context, index) {
                  final cheki = _recentCheki[index];
                  final path = cheki['photo_path'] as String?;
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChekiDetailPage(cheki: cheki),
                        ),
                      );
                      _loadStats();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: path != null && File(path).existsSync()
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Container(
                              color: color.withOpacity(0.08),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 20,
                                color: color.withOpacity(0.3),
                              ),
                            ),
                    ),
                  );
                },
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
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
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 46),
    child: Divider(height: 1, thickness: 0.5),
  );
}
