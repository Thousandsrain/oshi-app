import 'dart:io';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../database_helper.dart';
import 'add_group_page.dart';
import 'add_idol_page.dart';
import 'group_detail_page.dart';
import 'idol_detail_page.dart';

class OshiPage extends StatefulWidget {
  const OshiPage({super.key});

  @override
  State<OshiPage> createState() => _OshiPageState();
}

class _OshiPageState extends State<OshiPage>
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

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(
        title: Text(t.navOshi),
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
                child: const Icon(Icons.add_rounded, color: _accent, size: 20),
              ),
              onPressed: () async {
                if (_tabController.index == 0) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddIdolPage()),
                  );
                  if (result == true) setState(() {});
                } else {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddGroupPage()),
                  );
                  if (result == true) setState(() {});
                }
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: _accent,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: t.individual),
                Tab(text: t.group),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IdolListTab(onRefresh: () => setState(() {})),
          _GroupListTab(onRefresh: () => setState(() {})),
        ],
      ),
    );
  }
}

// ── 推し一覧 ─────────────────────────────────────────────────────

class _IdolListTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const _IdolListTab({required this.onRefresh});

  @override
  State<_IdolListTab> createState() => _IdolListTabState();
}

class _IdolListTabState extends State<_IdolListTab> {
  static const Color _accent = Color(0xFFD4537E);
  List<Map<String, dynamic>> _idols = [];

  @override
  void initState() {
    super.initState();
    _loadIdols();
  }

  Future<void> _loadIdols() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('idols', orderBy: 'name ASC');
    setState(() => _idols = result);
  }

  String _calcHistory(String? startDateStr) {
    if (startDateStr == null) return '';
    final start = DateTime.tryParse(startDateStr);
    if (start == null) return '';
    final diff = DateTime.now().difference(start);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    final t = AppText(appLanguageController.language);
    if (years > 0) return t.yearsMonths(years, months);
    if (months > 0) return t.months(months);
    return t.days(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    if (_idols.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 44,
                color: _accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.noOshi,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddIdolPage()),
                );
                if (result == true) _loadIdols();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t.addOshi),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIdols,
      color: _accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _idols.length,
        itemBuilder: (context, index) {
          final idol = _idols[index];
          final color = Color(
            int.parse(
              (idol['color'] as String? ?? '#D4537E').replaceFirst('#', '0xFF'),
            ),
          );
          final history = _calcHistory(idol['start_date'] as String?);
          final photoPath = idol['photo_path'] as String?;

          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IdolDetailPage(idol: idol)),
              );
              _loadIdols();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.15),
                    backgroundImage:
                        photoPath != null && File(photoPath).existsSync()
                        ? FileImage(File(photoPath))
                        : null,
                    child: photoPath == null || !File(photoPath).existsSync()
                        ? Text(
                            (idol['name'] as String).characters.first,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idol['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (history.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.historyLabel(history),
                              style: TextStyle(fontSize: 11, color: color),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade300,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 団体一覧 ─────────────────────────────────────────────────────

class _GroupListTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const _GroupListTab({required this.onRefresh});

  @override
  State<_GroupListTab> createState() => _GroupListTabState();
}

class _GroupListTabState extends State<_GroupListTab> {
  static const Color _accent = Color(0xFFD4537E);
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('groups', orderBy: 'name ASC');
    setState(() => _groups = result);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.group_outlined, size: 44, color: _accent),
            ),
            const SizedBox(height: 20),
            Text(
              t.noGroup,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGroupPage()),
                );
                if (result == true) _loadGroups();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t.addGroup),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: _accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final logoPath = group['logo_path'] as String?;

          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailPage(group: group),
                ),
              );
              if (result == 'deleted') _loadGroups();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _accent.withOpacity(0.12),
                    backgroundImage:
                        logoPath != null && File(logoPath).existsSync()
                        ? FileImage(File(logoPath))
                        : null,
                    child: logoPath == null || !File(logoPath).existsSync()
                        ? Text(
                            (group['name'] as String).characters.first,
                            style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (group['note'] != null &&
                            (group['note'] as String).isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            group['note'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade300,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
