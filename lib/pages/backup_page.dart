import 'dart:io';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../backup_helper.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  static const Color _accent = Color(0xFFD4537E);
  List<String> _backups = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final list = await BackupHelper.listBackups();
    setState(() => _backups = list);
  }

  Future<void> _createBackup() async {
    final t = AppLanguageScope.textOf(context);
    setState(() => _loading = true);
    final path = await BackupHelper.createBackup();
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            path != null ? t.backupDone : t.backupFailed,
          ),
        ),
      );
      if (path != null) _loadBackups();
    }
  }

  Future<void> _restoreFromFile() async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await _showConfirmDialog(
      title: t.restoreFromExternal,
      content: t.restoreFromExternalContent,
      actionLabel: t.continueAction,
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    final success = await BackupHelper.restoreBackup(
      null,
      dialogTitle: t.selectBackupFile,
    );
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(success ? t.restoreDone : t.restoreFileMissing),
        ),
      );
      if (success) Navigator.pop(context, true);
    }
  }

  Future<void> _restoreBackup(String path) async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await _showConfirmDialog(
      title: t.restoreConfirm,
      content: t.restoreConfirmContent,
      actionLabel: t.restore,
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    final success = await BackupHelper.restoreBackup(path);
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(success ? t.restoreDone : t.restoreFailed),
        ),
      );
      if (success) Navigator.pop(context, true);
    }
  }

  Future<void> _deleteBackup(String path) async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await _showConfirmDialog(
      title: t.deleteConfirm,
      content: t.deleteBackupContent,
      actionLabel: t.delete,
      destructive: true,
    );
    if (confirm != true) return;
    await BackupHelper.deleteBackup(path);
    _loadBackups();
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String actionLabel,
    bool destructive = false,
  }) {
    final t = AppLanguageScope.textOf(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              actionLabel,
              style: TextStyle(
                color: destructive ? Colors.red : _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBackupName(String path) {
    final name = path.split('/').last;
    final parts = name
        .replaceAll('oshi_backup_', '')
        .replaceAll('.zip', '')
        .split('T');
    if (parts.length < 2) return name;
    final date = parts[0].replaceAll('-', '.');
    final time = parts[1].substring(0, 5).replaceAll('-', ':');
    return '$date $time';
  }

  String _formatSize(String path) {
    final size = File(path).lengthSync();
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(title: Text(t.backupRestore)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // アクションカード
                Container(
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
                      _ActionTile(
                        icon: Icons.cloud_upload_outlined,
                        label: t.backupNow,
                        subtitle: t.backupNowSub,
                        color: _accent,
                        onTap: _createBackup,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 66),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      _ActionTile(
                        icon: Icons.folder_open_outlined,
                        label: t.restoreFromFile,
                        subtitle: t.restoreFromFileSub,
                        color: Colors.blue.shade600,
                        onTap: _restoreFromFile,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // バックアップ一覧
                if (_backups.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      t.deviceBackups,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Container(
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
                      children: _backups.asMap().entries.map((entry) {
                        final i = entry.key;
                        final path = entry.value;
                        return Column(
                          children: [
                            if (i > 0)
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Divider(height: 1, thickness: 0.5),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.folder_zip_outlined,
                                      color: _accent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatBackupName(path),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatSize(path),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.restore_rounded,
                                      color: _accent,
                                      size: 20,
                                    ),
                                    onPressed: () => _restoreBackup(path),
                                    tooltip: t.restore,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red.shade400,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteBackup(path),
                                    tooltip: t.delete,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        t.noBackups,
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
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
      ),
    );
  }
}
