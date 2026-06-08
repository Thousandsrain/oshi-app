import 'package:flutter/material.dart';
import '../app_language.dart';
import '../database_helper.dart';

class AddLivePage extends StatefulWidget {
  final DateTime initialDate;
  const AddLivePage({super.key, required this.initialDate});

  @override
  State<AddLivePage> createState() => _AddLivePageState();
}

class _AddLivePageState extends State<AddLivePage> {
  static const Color _accent = Color(0xFFD4537E);

  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  List<Map<String, dynamic>> _allIdols = [];
  List<Map<String, dynamic>> _allGroups = [];
  Set<int> _selectedIdolIds = {};
  Set<int> _selectedGroupIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadIdolsAndGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadIdolsAndGroups() async {
    final db = await DatabaseHelper.instance.database;
    final idols = await db.query('idols', orderBy: 'name ASC');
    final groups = await db.query('groups', orderBy: 'name ASC');
    setState(() {
      _allIdols = idols;
      _allGroups = groups;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? _timeString() {
    if (_selectedTime == null) return null;
    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final db = await DatabaseHelper.instance.database;
    final liveId = await db.insert('lives', {
      'name': _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      'venue': _venueController.text.trim().isEmpty
          ? null
          : _venueController.text.trim(),
      'date': _dateKey(_selectedDate),
      'time': _timeString(),
      'note': _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    });

    for (final idolId in _selectedIdolIds) {
      await db.insert('live_idols', {'live_id': liveId, 'idol_id': idolId});
    }
    for (final groupId in _selectedGroupIds) {
      await db.insert('live_groups', {'live_id': liveId, 'group_id': groupId});
    }

    if (mounted) Navigator.pop(context, true);
  }

  Widget _buildChipRow({
    required String label,
    required List<Map<String, dynamic>> items,
    required Set<int> selectedIds,
    required void Function(int) onToggle,
    required String nameKey,
    String? colorKey,
  }) {
    if (items.isEmpty) return const SizedBox();
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
              onTap: () => setState(() {
                if (isSelected) {
                  selectedIds.remove(id);
                } else {
                  selectedIds.add(id);
                }
              }),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          t.addLive,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              t.save,
              style: const TextStyle(color: _accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基本情報
          _buildCard(
            children: [
              _buildField(
                controller: _nameController,
                label: t.liveName,
                hint: t.liveNameHint,
                icon: Icons.music_note_outlined,
              ),
              const Divider(height: 1),
              _buildField(
                controller: _venueController,
                label: t.venue,
                hint: t.venueHint,
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 日時
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: _accent,
                  size: 20,
                ),
                title: Text(t.date, style: const TextStyle(fontSize: 14)),
                trailing: Text(
                  '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
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
            ],
          ),
          const SizedBox(height: 12),

          // 出演者
          if (_allGroups.isNotEmpty || _allIdols.isNotEmpty)
            _buildCard(
              padding: const EdgeInsets.all(16),
              children: [
                if (_allGroups.isNotEmpty) ...[
                  _buildChipRow(
                    label: t.performingGroups,
                    items: _allGroups,
                    selectedIds: _selectedGroupIds,
                    onToggle: (id) {},
                    nameKey: 'name',
                  ),
                  if (_allIdols.isNotEmpty) const SizedBox(height: 16),
                ],
                if (_allIdols.isNotEmpty)
                  _buildChipRow(
                    label: t.performingOshi,
                    items: _allIdols,
                    selectedIds: _selectedIdolIds,
                    onToggle: (id) {},
                    nameKey: 'name',
                    colorKey: 'color',
                  ),
              ],
            ),
          if (_allGroups.isNotEmpty || _allIdols.isNotEmpty)
            const SizedBox(height: 12),

          // 備考
          _buildCard(
            children: [
              _buildField(
                controller: _noteController,
                label: t.note,
                hint: t.noteHint,
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children, EdgeInsets? padding}) {
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
                hintText: hint,
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
