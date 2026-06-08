import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'pages/oshi_page.dart';
import 'pages/cheki_page.dart';
import 'pages/add_cheki_page.dart';
import 'pages/more_page.dart';
import 'pages/live_page.dart';
import 'pages/legal_page.dart';
import 'image_helper.dart';
import 'app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appLanguageController.load();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const OshiApp());
}

class OshiApp extends StatelessWidget {
  const OshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      controller: appLanguageController,
      child: Builder(
        builder: (context) {
          final t = AppLanguageScope.textOf(context);
          return MaterialApp(
            title: t.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD4537E),
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF7F3F5),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1A1A1A),
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                titleTextStyle: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
              ),
            ),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _dataVersion = 0;
  bool? _privacyAccepted;

  @override
  void initState() {
    super.initState();
    _loadPrivacyConsent();
  }

  Future<File> _privacyConsentFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/privacy_consent_v1.txt');
  }

  Future<void> _loadPrivacyConsent() async {
    var accepted = false;
    try {
      final file = await _privacyConsentFile();
      accepted = await file.exists() && (await file.readAsString()) == 'accepted';
    } catch (_) {
      accepted = false;
    }
    if (!mounted) return;
    setState(() => _privacyAccepted = accepted);
    if (accepted) {
      ImageHelper.cleanOrphanFiles();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showPrivacyConsentDialog();
    });
  }

  Future<void> _acceptPrivacyConsent() async {
    try {
      final file = await _privacyConsentFile();
      await file.writeAsString('accepted');
    } catch (_) {}
    if (!mounted) return;
    setState(() => _privacyAccepted = true);
    ImageHelper.cleanOrphanFiles();
  }

  void _showPrivacyConsentDialog() {
    final t = AppLanguageScope.textOf(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.privacyConsentTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.privacyConsentContent),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPage(
                          type: LegalDocumentType.privacy,
                        ),
                      ),
                    ),
                    child: Text(t.privacyPolicy),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPage(
                          type: LegalDocumentType.agreement,
                        ),
                      ),
                    ),
                    child: Text(t.userAgreement),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.privacyConsentRequired)),
              );
            },
            child: Text(t.disagree),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _acceptPrivacyConsent();
            },
            child: Text(t.agreeAndContinue),
          ),
        ],
      ),
    );
  }

  void _handleDataRestored() {
    setState(() {
      _dataVersion++;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final pages = [
      ChekiPage(key: ValueKey('cheki_$_dataVersion')),
      LivePage(key: ValueKey('live_$_dataVersion')),
      OshiPage(key: ValueKey('oshi_$_dataVersion')),
      MorePage(
        key: ValueKey('more_$_dataVersion'),
        onDataRestored: _handleDataRestored,
      ),
    ];

    if (_privacyAccepted != true) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.photo_camera_outlined,
                  activeIcon: Icons.photo_camera_rounded,
                  label: t.navCheki,
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.music_note_outlined,
                  activeIcon: Icons.music_note_rounded,
                  label: t.navLive,
                  selected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                // 中央追加ボタン
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddChekiPage()),
                      ).then((result) {
                        if (result == true) setState(() {});
                      });
                    },
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4537E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4537E).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.favorite_outline_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: t.navOshi,
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: t.navMore,
                  selected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD4537E);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? accent : const Color(0xFFBDBDBD),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? accent : const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
