import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../image_helper.dart';
import '../database_helper.dart';

class EditIdolPage extends StatefulWidget {
  final Map<String, dynamic> idol;
  const EditIdolPage({super.key, required this.idol});

  @override
  State<EditIdolPage> createState() => _EditIdolPageState();
}

class _EditIdolPageState extends State<EditIdolPage> {
  static const Color _accent = Color(0xFFD4537E);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  DateTime? _startDate;
  DateTime? _birthday;
  late String _selectedColor;
  String? _photoPath;
  List<Map<String, dynamic>> _groups = [];
  List<int> _selectedGroupIds = [];
  List<Map<String, String>> _snsList = [];

  final List<String> _presetColors = [
    '#D4537E',
    '#E91E8C',
    '#FF6B9D',
    '#FF4081',
    '#7F77DD',
    '#673AB7',
    '#3F51B5',
    '#2196F3',
    '#1D9E75',
    '#4CAF50',
    '#8BC34A',
    '#009688',
    '#EF9F27',
    '#FF9800',
    '#FF5722',
    '#F44336',
    '#888780',
    '#607D8B',
    '#795548',
    '#000000',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.idol['name'] as String?,
    );
    _noteController = TextEditingController(
      text: widget.idol['note'] as String? ?? '',
    );
    _selectedColor = widget.idol['color'] as String? ?? '#D4537E';
    _photoPath = widget.idol['photo_path'] as String?;
    final startStr = widget.idol['start_date'] as String?;
    if (startStr != null) _startDate = DateTime.tryParse(startStr);
    final birthdayStr = widget.idol['birthday'] as String?;
    if (birthdayStr != null) {
      final parts = birthdayStr.split('/');
      if (parts.length == 2)
        _birthday = DateTime(2000, int.parse(parts[0]), int.parse(parts[1]));
    }
    final snsJson = widget.idol['sns_json'] as String?;
    if (snsJson != null) {
      final decoded = jsonDecode(snsJson) as List;
      _snsList = decoded
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final groups = await db.query('groups', orderBy: 'name ASC');
    final linked = await db.query(
      'idol_groups',
      where: 'idol_id = ?',
      whereArgs: [widget.idol['id']],
    );
    setState(() {
      _groups = groups;
      _selectedGroupIds = linked.map((e) => e['group_id'] as int).toList();
    });
  }

  Future<void> _pickPhoto() async {
    ImageHelper.showPhotoOptions(
      context: context,
      onPick: (source) async {
        final path = await ImageHelper.pickAndCropAvatar(
          context: context,
          source: source,
        );
        if (path != null) setState(() => _photoPath = path);
      },
      onDelete: _photoPath != null
          ? () => setState(() => _photoPath = null)
          : null,
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_birthday ?? DateTime(2000)),
      firstDate: isStart ? DateTime(2000) : DateTime(1970),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _accent)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _birthday = picked;
      });
    }
  }

  void _showColorPicker() {
    final t = AppLanguageScope.textOf(context);
    final customController = TextEditingController(
      text: _selectedColor.replaceFirst('#', ''),
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                t.color,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _presetColors.map((hex) {
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = hex);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                t.customHex,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('#', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: customController,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'FF5733',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (customController.text.length == 6) {
                        setState(
                          () => _selectedColor =
                              '#${customController.text.toUpperCase()}',
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'idols',
      {
        'name': _nameController.text.trim(),
        'note': _noteController.text.trim(),
        'start_date': _startDate?.toIso8601String(),
        'color': _selectedColor,
        'photo_path': _photoPath,
        'birthday': _birthday != null
            ? '${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.day.toString().padLeft(2, '0')}'
            : null,
        'sns_json': _snsList.isNotEmpty ? jsonEncode(_snsList) : null,
      },
      where: 'id = ?',
      whereArgs: [widget.idol['id']],
    );
    await db.delete(
      'idol_groups',
      where: 'idol_id = ?',
      whereArgs: [widget.idol['id']],
    );
    for (final groupId in _selectedGroupIds) {
      await db.insert('idol_groups', {
        'idol_id': widget.idol['id'],
        'group_id': groupId,
      });
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.deleteConfirm),
        content: Text(t.deleteOshiContent(widget.idol['name'] as String? ?? '')),
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
      where: 'idol_id = ?',
      whereArgs: [widget.idol['id']],
    );
    await db.delete('idols', where: 'id = ?', whereArgs: [widget.idol['id']]);
    if (mounted) Navigator.pop(context, 'deleted');
  }

  String _formatDate(DateTime? d) {
    if (d == null) return AppText(appLanguageController.language).unset;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final selectedColorValue = Color(
      int.parse(_selectedColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(
        title: Text(t.editOshi),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade400,
            ),
            onPressed: _delete,
          ),
          TextButton(
            onPressed: _save,
            child: Text(
              t.save,
              style: const TextStyle(color: _accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: selectedColorValue.withOpacity(0.15),
                      backgroundImage:
                          _photoPath != null && File(_photoPath!).existsSync()
                          ? FileImage(File(_photoPath!))
                          : null,
                      child:
                          _photoPath == null || !File(_photoPath!).existsSync()
                          ? Icon(
                              Icons.person_outline_rounded,
                              size: 48,
                              color: selectedColorValue,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                t.tapToChange,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 20),

            _buildCard(
              children: [
                _buildField(
                  controller: _nameController,
                  label: '${t.name} *',
                  icon: Icons.person_outline_rounded,
                  required: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCard(
              children: [
                _buildDateTile(
                  icon: Icons.favorite_outline_rounded,
                  label: t.firstOshiDate,
                  value: _formatDate(_startDate),
                  onTap: () => _pickDate(true),
                ),
                const _Divider(),
                _buildDateTile(
                  icon: Icons.cake_outlined,
                  label: t.birthday,
                  value: _birthday == null
                      ? t.unset
                      : '${_birthday!.month}月${_birthday!.day}日',
                  onTap: () => _pickDate(false),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_groups.isNotEmpty) ...[
              _buildCard(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    t.belongingGroups,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 10),
                  _buildChips(
                    items: _groups,
                    selectedIds: _selectedGroupIds,
                    nameKey: 'name',
                    onToggle: (id) => setState(() {
                      if (_selectedGroupIds.contains(id))
                        _selectedGroupIds.remove(id);
                      else
                        _selectedGroupIds.add(id);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            _buildCard(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  t.color,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selectedColorValue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColorValue.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedColor,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.tapToChange,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCard(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SNS',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
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
                              const Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: _accent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                t.add,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _accent,
                                ),
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
                            controller:
                                TextEditingController(text: sns['platform'])
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
                            controller:
                                TextEditingController(text: sns['handle'])
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
              ],
            ),
            const SizedBox(height: 12),

            _buildCard(
              children: [
                _buildField(
                  controller: _noteController,
                  label: t.noteOptional,
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children, EdgeInsets? padding}) {
    return Container(
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
    required IconData icon,
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
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
              validator: required
                  ? (v) => v == null || v.trim().isEmpty
                        ? AppText(appLanguageController.language).inputRequired(label.replaceAll(' *', ''))
                        : null
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _accent, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      onTap: onTap,
    );
  }

  Widget _buildChips({
    required List<Map<String, dynamic>> items,
    required List<int> selectedIds,
    required String nameKey,
    required void Function(int) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final id = item['id'] as int;
        final isSelected = selectedIds.contains(id);
        return GestureDetector(
          onTap: () => onToggle(id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _accent.withOpacity(0.12)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? _accent : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item[nameKey] as String,
              style: TextStyle(
                color: isSelected ? _accent : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 52),
    child: Divider(height: 1, thickness: 0.5),
  );
}
