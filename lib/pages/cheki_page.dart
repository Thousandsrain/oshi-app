import 'dart:io';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../database_helper.dart';
import 'cheki_detail_page.dart';

class ChekiPage extends StatefulWidget {
  const ChekiPage({super.key});

  @override
  State<ChekiPage> createState() => _ChekiPageState();
}

class _ChekiPageState extends State<ChekiPage> {
  static const Color _accent = Color(0xFFD4537E);
  List<Map<String, dynamic>> _chekiList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCheki();
  }

  Future<void> _loadCheki() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT c.*, i.name as idol_name, i.color as idol_color, i.photo_path as idol_photo
      FROM cheki c
      LEFT JOIN idols i ON c.idol_id = i.id
      ORDER BY c.date DESC
    ''');
    setState(() {
      _chekiList = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final topPad = MediaQuery.of(context).padding.top;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_chekiList.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
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
                    Icons.photo_camera_outlined,
                    size: 44,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t.noCheki,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.addWithPlus,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadCheki,
        color: _accent,
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(12, topPad + 16, 12, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.628,
          ),
          itemCount: _chekiList.length,
          itemBuilder: (context, index) {
            final cheki = _chekiList[index];
            final photoPath = cheki['photo_path'] as String?;
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChekiDetailPage(cheki: cheki),
                  ),
                );
                _loadCheki();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photoPath != null && File(photoPath).existsSync()
                    ? Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: idolColor.withOpacity(0.08),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: idolColor.withOpacity(0.4),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                cheki['idol_name'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: idolColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
