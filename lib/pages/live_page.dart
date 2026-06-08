import 'dart:io';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../database_helper.dart';
import 'add_live_page.dart';
import 'live_detail_page.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  static const Color _accent = Color(0xFFD4537E);

  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  // 当月所有有 live 的日期集合（用于日历标记）
  Set<String> _liveDates = {};
  // 选中日期的 live 列表
  List<Map<String, dynamic>> _dayLives = [];

  @override
  void initState() {
    super.initState();
    _loadMonthMarkers();
    _loadDayLives();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadMonthMarkers() async {
    final db = await DatabaseHelper.instance.database;
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDay = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final rows = await db.query(
      'lives',
      columns: ['date'],
      where: 'date >= ? AND date <= ?',
      whereArgs: [_dateKey(firstDay), _dateKey(lastDay)],
    );
    setState(() {
      _liveDates = rows
          .map((r) => (r['date'] as String? ?? '').substring(0, 10))
          .where((s) => s.isNotEmpty)
          .toSet();
    });
  }

  Future<void> _loadDayLives() async {
    final db = await DatabaseHelper.instance.database;
    final key = _dateKey(_selectedDate);
    final rows = await db.query(
      'lives',
      where: 'date = ?',
      whereArgs: [key],
      orderBy: 'time ASC',
    );
    setState(() => _dayLives = rows);
  }

  Future<void> _refresh() async {
    await _loadMonthMarkers();
    await _loadDayLives();
  }

  void _goToAddLive() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddLivePage(initialDate: _selectedDate),
      ),
    );
    if (result == true) _refresh();
  }

  void _goToDetail(Map<String, dynamic> live) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveDetailPage(live: live)),
    );
    if (result != null) _refresh();
  }

  // 年選択ピッカー
  void _showYearPicker(int currentYear) {
    final t = AppLanguageScope.textOf(context);
    final firstYear = 2000;
    final lastYear = DateTime.now().year + 5;
    final years = List.generate(lastYear - firstYear + 1, (i) => firstYear + i);
    final scrollController = ScrollController(
      initialScrollOffset: ((currentYear - firstYear) * 48.0).clamp(
        0.0,
        double.infinity,
      ),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t.selectYear,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              controller: scrollController,
              itemCount: years.length,
              itemExtent: 48,
              itemBuilder: (_, index) {
                final y = years[index];
                final isSelected = y == currentYear;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _focusedDate = DateTime(y, _focusedDate.month);
                    });
                    _loadMonthMarkers();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      t.yearLabel(y),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── 日历组件 ────────────────────────────────────────────────

  Widget _buildCalendar() {
    final t = AppLanguageScope.textOf(context);
    final year = _focusedDate.year;
    final month = _focusedDate.month;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 0=日
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 月份导航
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(year, month - 1);
                    });
                    _loadMonthMarkers();
                  },
                ),
                GestureDetector(
                  onTap: () => _showYearPicker(year),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.monthLabel(year, month),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: _accent,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(year, month + 1);
                    });
                    _loadMonthMarkers();
                  },
                ),
              ],
            ),
          ),
          // 星期标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: t.weekdays.map((d) {
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        color: d == '日'
                            ? Colors.red.shade300
                            : d == '土'
                            ? Colors.blue.shade300
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // 日期格子
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (_, index) {
                if (index < firstWeekday) return const SizedBox();
                final day = index - firstWeekday + 1;
                final date = DateTime(year, month, day);
                final key = _dateKey(date);
                final isSelected = _dateKey(_selectedDate) == key;
                final isToday = _dateKey(DateTime.now()) == key;
                final hasLive = _liveDates.contains(key);
                final weekday = date.weekday % 7;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _loadDayLives();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accent
                          : isToday
                          ? _accent.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : weekday == 0
                                ? Colors.red.shade400
                                : weekday == 6
                                ? Colors.blue.shade400
                                : Colors.black87,
                          ),
                        ),
                        if (hasLive)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : _accent,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
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

  // ── Live カード ──────────────────────────────────────────────

  Widget _buildLiveCard(Map<String, dynamic> live) {
    final t = AppLanguageScope.textOf(context);
    final name = live['name'] as String? ?? t.untitled;
    final venue = live['venue'] as String? ?? '';
    final time = live['time'] as String? ?? '';

    return GestureDetector(
      onTap: () => _goToDetail(live),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (time.isNotEmpty) ...[
                        Icon(
                          Icons.access_time_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (venue.isNotEmpty) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            venue,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final selectedKey = _dateKey(_selectedDate);
    final formattedSelected = t.dateLong(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Live',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _accent),
            onPressed: _goToAddLive,
            tooltip: t.addLive,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _accent,
        child: ListView(
          children: [
            _buildCalendar(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedSelected,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    t.countItems(_dayLives.length),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (_dayLives.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.noLiveThisDay,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _goToAddLive,
                      icon: const Icon(Icons.add, size: 16, color: _accent),
                      label: Text(
                        t.addLive,
                        style: const TextStyle(color: _accent),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._dayLives.map(_buildLiveCard),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
