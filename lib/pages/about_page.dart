import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_language.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color _accent = Color(0xFFD4537E);

  void _copyToClipboard(BuildContext context, String text, String label) {
    final t = AppLanguageScope.textOf(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.copied(label)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(title: Text(t.developerInfo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // アプリアイコン + 名前
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  t.appName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 開発者情報カード
          _SectionLabel(label: t.developer),
          _SectionCard(
            children: [
              _InfoTile(
                icon: Icons.person_outline_rounded,
                label: t.developer,
                value: '千雨',
              ),
              const _RowDivider(),
              _InfoTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'QQ',
                value: '2087074589',
                onTap: () => _copyToClipboard(context, '2087074589', t.qqNumber),
                tapHint: t.tapToCopy,
              ),
              const _RowDivider(),
              _InfoTile(
                icon: Icons.code_rounded,
                label: 'GitHub',
                value: t.notPublished,
              ),
            ],
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              t.madeBy,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? tapHint;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.tapHint,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD4537E);
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
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (tapHint != null)
                Text(
                  tapHint!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
            ],
          ),
        ),
      ),
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
