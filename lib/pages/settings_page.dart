import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../app_language.dart';
import '../database_helper.dart';
import 'about_page.dart';
import 'legal_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _accent = Color(0xFFD4537E);

  String _cacheSize = '';

  @override
  void initState() {
    super.initState();
    _cacheSize = AppText(appLanguageController.language).calculating;
    _calcCacheSize();
  }

  Future<void> _calcCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int total = 0;
      if (tempDir.existsSync()) {
        await for (final entity in tempDir.list(recursive: true)) {
          if (entity is File) total += await entity.length();
        }
      }
      if (mounted) setState(() => _cacheSize = _formatSize(total));
    } catch (_) {
      if (mounted) {
        setState(() => _cacheSize = AppLanguageScope.textOf(context).unknown);
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _clearCache() async {
    final t = AppLanguageScope.textOf(context);
    final confirm = await _showConfirmDialog(
      title: t.clearCacheTitle,
      content: t.clearCacheContent,
      actionLabel: t.delete,
    );
    if (confirm != true) return;

    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await for (final entity in tempDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
      setState(() => _cacheSize = '0 B');
      if (mounted) {
        _showSnack(AppLanguageScope.textOf(context).cacheCleared);
      }
    } catch (_) {
      if (mounted) _showSnack(AppLanguageScope.textOf(context).deleteFailed);
    }
  }

  Future<void> _clearAllData() async {
    final t = AppLanguageScope.textOf(context);
    // 第一次确认
    final first = await _showConfirmDialog(
      title: t.deleteAllData,
      content: t.deleteAllDataContent,
      actionLabel: t.next,
      destructive: true,
    );
    if (first != true) return;

    // 第二次确认
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.reallyDelete),
        content: Text(t.reallyDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.deleteAllAction),
          ),
        ],
      ),
    );
    if (second != true) return;

    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('cheki');
      await db.delete('live_idols');
      await db.delete('live_groups');
      await db.delete('lives');
      await db.delete('idol_groups');
      await db.delete('idols');
      await db.delete('groups');
      await db.delete('filter_presets');

      // 删除应用内所有 img_ 图片文件
      final appDir = await getApplicationDocumentsDirectory();
      await for (final entity in appDir.list()) {
        if (entity is File && entity.path.split('/').last.startsWith('img_')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }

      if (mounted) _showSnack(AppLanguageScope.textOf(context).allDataDeleted);
    } catch (_) {
      if (mounted) _showSnack(AppLanguageScope.textOf(context).deleteFailed);
    }
  }

  void _showLanguagePicker() {
    final controller = AppLanguageScope.controllerOf(context);
    final t = AppLanguageScope.textOf(context);
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
              t.selectLanguage,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          _LangOption(
            label: AppLanguage.ja.label,
            isSelected: controller.language == AppLanguage.ja,
            onTap: () async {
              Navigator.pop(ctx);
              await controller.setLanguage(AppLanguage.ja);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _LangOption(
            label: AppLanguage.zh.label,
            isSelected: controller.language == AppLanguage.zh,
            onTap: () async {
              Navigator.pop(ctx);
              await controller.setLanguage(AppLanguage.zh);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 一般 ──
          _SectionLabel(label: t.general),
          _SectionCard(
            children: [
              _MenuItem(
                icon: Icons.language_rounded,
                label: t.languageLabel,
                trailing: Text(
                  AppLanguageScope.controllerOf(context).language.label,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                onTap: _showLanguagePicker,
              ),
            ],
          ),
          const SizedBox(height: 20),

          _SectionLabel(label: t.compliance),
          _SectionCard(
            children: [
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: t.privacyPolicy,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LegalPage(type: LegalDocumentType.privacy),
                  ),
                ),
              ),
              const _RowDivider(),
              _MenuItem(
                icon: Icons.description_outlined,
                label: t.userAgreement,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LegalPage(type: LegalDocumentType.agreement),
                  ),
                ),
              ),
              const _RowDivider(),
              _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                label: t.permissionDescription,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LegalPage(type: LegalDocumentType.permissions),
                  ),
                ),
              ),
              const _RowDivider(),
              _MenuItem(
                icon: Icons.verified_user_outlined,
                label: t.appFiling,
                trailing: Text(
                  t.appFilingPending,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LegalPage(type: LegalDocumentType.filing),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── ストレージ ──
          _SectionLabel(label: t.storage),
          _SectionCard(
            children: [
              _MenuItem(
                icon: Icons.cleaning_services_outlined,
                label: t.clearCache,
                trailing: Text(
                  _cacheSize,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                onTap: _clearCache,
              ),
              const _RowDivider(),
              _MenuItem(
                icon: Icons.delete_sweep_outlined,
                label: t.deleteAllData,
                labelColor: Colors.red.shade400,
                iconColor: Colors.red.shade400,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.transparent,
                ),
                onTap: _clearAllData,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── このアプリについて ──
          _SectionLabel(label: t.aboutApp),
          _SectionCard(
            children: [
              _MenuItem(
                icon: Icons.info_outline_rounded,
                label: t.developerInfo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── 共用ウィジェット ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
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
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD4537E);
    final effectiveIconColor = iconColor ?? accent;
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
                  color: effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: labelColor ?? Colors.black87,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null)
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

class _LangOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD4537E);
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: accent)
          : null,
      onTap: onTap,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 66),
    child: Divider(height: 1, thickness: 0.5),
  );
}
