import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

enum AppLanguage {
  ja('ja', '日本語'),
  zh('zh', '中文（简体）');

  final String code;
  final String label;

  const AppLanguage(this.code, this.label);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.zh,
    );
  }
}

class AppLanguageController extends ChangeNotifier {
  static const _fileName = 'language.txt';

  AppLanguage _language = AppLanguage.zh;

  AppLanguage get language => _language;
  bool get isJapanese => _language == AppLanguage.ja;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) return;
      _language = AppLanguage.fromCode((await file.readAsString()).trim());
    } catch (_) {
      _language = AppLanguage.zh;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(language.code);
    } catch (_) {}
  }
}

final appLanguageController = AppLanguageController();

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController controllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    return scope?.notifier ?? appLanguageController;
  }

  static AppText textOf(BuildContext context) {
    return AppText(controllerOf(context).language);
  }
}

class AppText {
  final AppLanguage currentLanguage;

  const AppText(this.currentLanguage);

  bool get _ja => currentLanguage == AppLanguage.ja;

  String get appName => _ja ? 'チェキる' : '推活日记';

  String get navCheki => _ja ? 'チェキ' : 'チェキ';
  String get navLive => 'Live';
  String get navOshi => _ja ? '推し' : '推し';
  String get navMore => _ja ? 'もっと' : '更多';

  String get moreTitle => _ja ? 'もっと' : '更多';
  String get backupRestore => _ja ? 'バックアップ・復元' : '备份・恢复';
  String get settings => _ja ? '設定' : '设置';

  String get languageLabel => _ja ? '言語' : '语言';
  String get selectLanguage => _ja ? '言語を選択' : '选择语言';
  String get general => _ja ? '一般' : '通用';
  String get storage => _ja ? 'ストレージ' : '存储';
  String get aboutApp => _ja ? 'このアプリについて' : '关于本应用';
  String get developerInfo => _ja ? '開発者情報' : '开发者信息';
  String get compliance => _ja ? '利用とプライバシー' : '使用与隐私';
  String get privacyPolicy => _ja ? 'プライバシーポリシー' : '隐私政策';
  String get userAgreement => _ja ? '利用規約' : '用户协议';
  String get permissionDescription => _ja ? '権限の説明' : '权限使用说明';
  String get appFiling => _ja ? 'アプリ備案情報' : '应用备案信息';
  String get appFilingPending => _ja ? '備案取得後に表示します' : '备案完成后展示';
  String get policyUpdatedDate => _ja ? '更新日：2026年6月8日' : '更新日期：2026年6月8日';
  String get privacyConsentTitle => _ja ? 'ご利用前の確認' : '使用前确认';
  String get privacyConsentContent => _ja
      ? '本アプリは、チェキ写真の追加・編集・保存、推しやLive情報の管理のために、カメラ、写真、ファイル等の権限を必要な場面で使用します。データは主に端末内に保存されます。ご利用前にプライバシーポリシーと利用規約をご確認ください。'
      : '本应用用于管理チェキ照片、推し和Live信息，会在必要场景使用相机、相册、文件等权限。数据主要保存在本机。使用前请阅读并同意隐私政策和用户协议。';
  String get agreeAndContinue => _ja ? '同意して続ける' : '同意并继续';
  String get disagree => _ja ? '不同意' : '不同意';
  String get privacyConsentRequired => _ja
      ? '同意後にアプリを利用できます'
      : '需要同意后才能继续使用应用';

  String get calculating => _ja ? '計算中...' : '计算中...';
  String get unknown => _ja ? '不明' : '未知';
  String get clearCache => _ja ? 'キャッシュを削除' : '清除缓存';
  String get clearCacheTitle => _ja ? 'キャッシュを削除' : '清除缓存';
  String get clearCacheContent =>
      _ja ? '一時ファイルをすべて削除します。アプリの動作には影響しません。' : '将删除所有临时文件，不会影响应用正常使用。';
  String get cacheCleared => _ja ? 'キャッシュを削除しました' : '缓存已清除';

  String get delete => _ja ? '削除' : '删除';
  String get deleteFailed => _ja ? '削除に失敗しました' : '删除失败';
  String get cancel => _ja ? 'キャンセル' : '取消';
  String get next => _ja ? '次へ' : '下一步';
  String get deleteAllData => _ja ? 'データを全削除' : '删除全部数据';
  String get deleteAllDataContent => _ja
      ? 'チェキ・Live・推し・団体など、すべてのデータが削除されます。この操作は元に戻せません。'
      : 'チェキ、Live、推し、团体等所有数据都会被删除。此操作无法撤销。';
  String get reallyDelete => _ja ? '本当に削除しますか？' : '真的要删除吗？';
  String get reallyDeleteContent => _ja
      ? 'すべてのデータと写真が完全に削除されます。\nバックアップを取ってから実行することをお勧めします。'
      : '所有数据和照片都会被彻底删除。\n建议先完成备份后再执行。';
  String get deleteAllAction => _ja ? '全削除する' : '全部删除';
  String get allDataDeleted => _ja ? 'データをすべて削除しました' : '已删除全部数据';

  String get cropPhoto => _ja ? '写真をトリミング' : '裁剪照片';
  String get adjustPhoto => _ja ? '写真を調整' : '调整照片';
  String get addPhoto => _ja ? '写真を追加' : '添加照片';
  String get shootAutoDetect => _ja ? '撮影して自動認識（テスト中）' : '拍摄并自动识别（测试中）';
  String get shootAutoDetectSub => _ja ? 'カメラで撮影して自動矯正' : '用相机拍摄并自动校正';
  String get albumAutoDetect => _ja ? 'アルバムから選んで自動認識（テスト中）' : '选择并自动识别（测试中）';
  String get albumAutoDetectSub => _ja ? '写真を選択して自動矯正' : '选择照片并自动校正';
  String get shootManualCrop => _ja ? '撮影して手動トリミング' : '拍摄并手动裁剪';
  String get shootManualCropSub => _ja ? 'カメラで撮影して手動矯正' : '用相机拍摄并手动校正';
  String get uploadScannedPhoto => _ja ? 'スキャン済み写真をアップロード' : '选择照片并手动矫正';
  String get uploadScannedPhotoSub =>
      _ja ? '自動認識をスキップして手動トリミング' : '跳过自动识别并手动裁剪';
  String get deletePhoto => _ja ? '写真を削除' : '删除照片';
  String get shootPhoto => _ja ? '撮影する' : '拍摄';
  String get chooseFromAlbum => _ja ? 'アルバムから選ぶ' : '从相册选择';

  String get adjustRange => _ja ? '範囲を調整' : '调整范围';
  String get rotate90 => _ja ? '90度回転' : '旋转90度';
  String get confirm => _ja ? '確認' : '确认';
  String get edgeHint => _ja ? '枠内をドラッグで移動、四隅で微調整できます' : '拖动框内可移动，拖动四角可微调';

  String get noCheki => _ja ? 'まだチェキがありません' : '还没有チェキ';
  String get addWithPlus => _ja ? '＋ボタンから追加しましょう' : '点击＋按钮添加吧';

  String get individual => _ja ? '個人' : '个人';
  String get group => _ja ? '団体' : '团体';
  String get noOshi => _ja ? 'まだ推しがいません' : '还没有推し';
  String get addOshi => _ja ? '推しを追加' : '添加推し';
  String get noGroup => _ja ? 'まだ団体がありません' : '还没有团体';
  String get addGroup => _ja ? '団体を追加' : '添加团体';
  String historyLabel(String value) => _ja ? '推し歴 $value' : '推し历 $value';
  String yearsMonths(int years, int months) =>
      _ja ? '$years年${months}ヶ月' : '$years年$months个月';
  String months(int months) => _ja ? '${months}ヶ月' : '$months个月';
  String days(int days) => _ja ? '$days日' : '$days天';

  String get selectYear => _ja ? '年を選択' : '选择年份';
  String yearLabel(int year) => _ja ? '$year年' : '$year年';
  String monthLabel(int year, int month) =>
      _ja ? '$year年$month月' : '$year年$month月';
  List<String> get weekdays => _ja
      ? const ['日', '月', '火', '水', '木', '金', '土']
      : const ['日', '一', '二', '三', '四', '五', '六'];
  String get untitled => _ja ? '（無題）' : '（无标题）';
  String dateLong(DateTime date) => _ja
      ? '${date.year}年${date.month}月${date.day}日'
      : '${date.year}年${date.month}月${date.day}日';
  String countItems(int count) => _ja ? '$count件' : '$count条';
  String get noLiveThisDay => _ja ? 'この日のLiveはありません' : '这一天没有Live';
  String get addLive => _ja ? 'Liveを追加' : '添加Live';

  String copied(String label) => _ja ? '$labelをコピーしました' : '已复制$label';
  String get developer => _ja ? '開発者' : '开发者';
  String get qqNumber => _ja ? 'QQ番号' : 'QQ';
  String get tapToCopy => _ja ? 'タップでコピー' : '点击复制';
  String get notPublished => _ja ? '（未公開）' : '（未公开）';
  String get madeBy => _ja ? 'Made with ♥ by 千雨' : '由 千雨 制作';

  String get save => _ja ? '保存' : '保存';
  String get addCheki => _ja ? 'チェキを追加' : '添加チェキ';
  String get tapToAddPhoto => _ja ? 'タップして写真を追加' : '点击添加照片';
  String get chooseOshi => _ja ? '推しを選ぶ' : '选择推し';
  String get addOshiFirst => _ja ? '先に推しを追加してください' : '请先添加推し';
  String get shootDate => _ja ? '撮影日' : '拍摄日期';
  String get noteOptional => _ja ? '備考（任意）' : '备注（可选）';
  String get note => _ja ? '備考' : '备注';
  String get unset => _ja ? '未設定' : '未设置';

  String get liveName => _ja ? 'Live名' : 'Live名称';
  String get liveNameHint => _ja ? '例：夏のワンマンライブ' : '例：夏日单独公演';
  String get venue => _ja ? '場所' : '地点';
  String get venueHint => _ja ? '例：Zepp Tokyo' : '例：Zepp Tokyo';
  String get date => _ja ? '日付' : '日期';
  String get startTime => _ja ? '開演時間' : '开演时间';
  String get performingGroups => _ja ? '出演団体' : '出演团体';
  String get performingOshi => _ja ? '出演推し' : '出演推し';
  String get noteHint => _ja ? 'メモなど' : '笔记等';

  String get backupDone =>
      _ja ? 'バックアップ完了！Downloadフォルダに保存されました' : '备份完成！已保存到Download文件夹';
  String get backupFailed => _ja ? 'バックアップ失敗' : '备份失败';
  String get restoreFromExternal => _ja ? '外部ファイルから復元' : '从外部文件恢复';
  String get restoreFromExternalContent => _ja
      ? 'バックアップZIPファイルを選択してください。\n現在のデータが上書きされます。'
      : '请选择备份ZIP文件。\n当前数据将被覆盖。';
  String get continueAction => _ja ? '続ける' : '继续';
  String get restoreDone => _ja ? '復元完了！アプリを再起動してください' : '恢复完成！请重启应用';
  String get restoreFailed => _ja ? '復元失敗' : '恢复失败';
  String get restoreFileMissing => _ja ? 'ファイルが選択されなかったか、復元失敗' : '未选择文件或恢复失败';
  String get restoreConfirm => _ja ? '復元確認' : '恢复确认';
  String get restoreConfirmContent =>
      _ja ? '現在のデータが上書きされます。続けますか？' : '当前数据将被覆盖，要继续吗？';
  String get restore => _ja ? '復元' : '恢复';
  String get deleteConfirm => _ja ? '削除確認' : '删除确认';
  String get deleteBackupContent => _ja ? 'このバックアップを削除しますか？' : '要删除这个备份吗？';
  String get backupNow => _ja ? '今すぐバックアップ' : '立即备份';
  String get backupNowSub => _ja ? '写真・データをすべて含みます' : '包含所有照片和数据';
  String get restoreFromFile => _ja ? 'ファイルから復元' : '从文件恢复';
  String get restoreFromFileSub => _ja ? '外部ストレージのZIPから復元' : '从外部存储的ZIP恢复';
  String get selectBackupFile => _ja ? 'バックアップファイルを選択' : '选择备份文件';
  String get deviceBackups => _ja ? 'このデバイスのバックアップ' : '本设备的备份';
  String get noBackups => _ja ? 'バックアップがありません' : '没有备份';

  String get tapToChoosePhoto => _ja ? 'タップして写真を選ぶ' : '点击选择照片';
  String get groupName => _ja ? '団体名' : '团体名';
  String get groupNameRequired => _ja ? '団体名を入力してください' : '请输入团体名';
  String get platform => _ja ? 'プラットフォーム' : '平台';
  String get username => _ja ? 'ユーザー名' : '用户名';
  String get noAt => _ja ? '@なし' : '不含@';
  String get add => _ja ? '追加' : '添加';
  String get name => _ja ? '名前' : '姓名';
  String get firstOshiDate => _ja ? '初推し日' : '初推日';
  String get birthday => _ja ? '誕生日' : '生日';
  String get belongingGroups => _ja ? '所属団体' : '所属团体';
  String get color => _ja ? 'カラー' : '颜色';
  String get customHex => _ja ? 'カスタム HEX' : '自定义 HEX';
  String get tapToChange => _ja ? 'タップして変更' : '点击更改';
  String inputRequired(String label) => _ja ? '$labelを入力してください' : '请输入$label';

  String get noPhotoToSave => _ja ? '保存する写真がありません' : '没有可保存的照片';
  String get savedToAlbum => _ja ? 'アルバムに保存しました' : '已保存到相册';
  String get saveFailed => _ja ? '保存に失敗しました' : '保存失败';
  String get deleteChekiContent => _ja ? 'このチェキを削除しますか？' : '要删除这张チェキ吗？';
  String get retouch => _ja ? '修図' : '修图';
  String get saveToAlbum => _ja ? 'アルバムに保存' : '保存到相册';
  String get none => _ja ? 'なし' : '无';

  String get fieldInfoMissing => _ja ? '情報未登録' : '信息未登记';
  String get members => _ja ? 'メンバー' : '成员';
  String get noMembers => _ja ? 'メンバーがいません' : '还没有成员';
  String get chekiTotal => _ja ? 'チェキ合計' : 'チェキ合计';
  String get liveCount => _ja ? '現場数' : '现场数';
  String get lastLive => _ja ? '最終現場' : '最后现场';
  String get affiliation => _ja ? '所属' : '所属';
  String pieces(int count) => _ja ? '$count枚' : '$count张';
  String times(int count) => _ja ? '$count回' : '$count次';
  String people(int count) => _ja ? '$count名' : '$count人';
  String get editGroup => _ja ? '団体を編集' : '编辑团体';
  String deleteGroupContent(String name) =>
      _ja ? '「$name」を削除しますか？\nメンバーの関連付けも解除されます。' : '要删除“$name”吗？\n成员关联也会被解除。';
  String get editOshi => _ja ? '推しを編集' : '编辑推し';
  String deleteOshiContent(String name) => _ja ? '「$name」を削除しますか？' : '要删除“$name”吗？';
  String get deleteLiveContent => _ja
      ? 'このLiveを削除しますか？\n関連するチェキのLive情報も解除されます。'
      : '要删除这个Live吗？\n相关チェキ的Live信息也会解除。';
  String get noChekiLinked => _ja ? 'チェキが追加されていません' : '还没有添加チェキ';
  String get noChekiAvailable => _ja ? 'チェキがありません' : '没有可选チェキ';
  String get selectCheki => _ja ? 'チェキを選択' : '选择チェキ';
  String get today => _ja ? '当日' : '当天';
  String get all => _ja ? '全て' : '全部';

  String get edit => _ja ? '編集' : '编辑';
  String get revertOriginal => _ja ? 'オリジナルに戻す' : '恢复原图';
  String get revertOriginalContent => _ja
      ? 'すべての編集を破棄して、アップロード時の状態に戻しますか？\nこの操作はアンドゥできません。'
      : '要放弃所有编辑，恢复到上传时的状态吗？\n此操作无法撤销。';
  String get revert => _ja ? '戻す' : '恢复';
  String get cropRotate => _ja ? 'トリミング・回転' : '裁剪・旋转';
  String get presetName => _ja ? 'プリセット名' : '预设名称';
  String get presetNameHint => _ja ? '例：桜色' : '例：樱花色';
  String get presetSaved => _ja ? 'プリセットを保存しました' : '预设已保存';
  String get share => _ja ? 'シェア' : '分享';
  String get presetShareTextPrefix => _ja ? 'チェキるフィルタープリセット' : '$appName滤镜预设';
  String get saveFailedTryShare => _ja ? '保存に失敗しました。シェアをお試しください。' : '保存失败，请尝试分享。';
  String importedPreset(String name) => _ja ? '「$name」をインポートしました' : '已导入“$name”';
  String get importFailed => _ja ? 'インポートに失敗しました' : '导入失败';
  String get crop => _ja ? 'トリミング' : '裁剪';
  String get adjust => _ja ? '調整' : '调整';
  String get filter => _ja ? 'フィルター' : '滤镜';
  String get openCropRotate => _ja ? 'トリミング・回転を開く' : '打开裁剪・旋转';
  String get reset => _ja ? 'リセット' : '重置';
  String get apply => _ja ? '適用' : '应用';
  String get resetAll => _ja ? '全リセット' : '全部重置';
  String get savePreset => _ja ? 'プリセット保存' : '保存预设';
  String get import => _ja ? 'インポート' : '导入';
  String get export => _ja ? 'エクスポート' : '导出';
  String get custom => _ja ? 'カスタム' : '自定义';
  String get selectPresetToExport => _ja ? 'エクスポートするプリセットを選択' : '选择要导出的预设';

  String photoPreset(String name) {
    final jaMap = {
      '无': 'なし',
      '复古': 'ビンテージ',
      '胶片': 'フィルム',
      '清爽': '清涼',
      '暖色': 'ウォーム',
      '黑白': 'モノクロ',
      '褪色': 'フェード',
      '戏剧': 'ドラマ',
      '导入': 'インポート',
    };
    final zhMap = {
      'なし': '无',
      'ビンテージ': '复古',
      'フィルム': '胶片',
      '清涼': '清爽',
      'ウォーム': '暖色',
      'モノクロ': '黑白',
      'フェード': '褪色',
      'ドラマ': '戏剧',
      'インポート': '导入',
    };
    return (_ja ? jaMap : zhMap)[name] ?? name;
  }

  String adjustName(String name) {
    final jaMap = {
      '白平衡': 'ホワイトバランス',
      '亮度': '明るさ',
      '曝光': '露出',
      '对比度': 'コントラスト',
      '高光': 'ハイライト',
      '阴影': 'シャドウ',
      '饱和度': '彩度',
      '色调': '色調',
      '色温': '色温度',
      '锐化': 'シャープ',
      '清晰度': '明瞭度',
      '颗粒': 'グレイン',
    };
    final zhMap = {
      'ホワイトバランス': '白平衡',
      '明るさ': '亮度',
      '露出': '曝光',
      'コントラスト': '对比度',
      'ハイライト': '高光',
      'シャドウ': '阴影',
      '彩度': '饱和度',
      '色調': '色调',
      '色温度': '色温',
      'シャープ': '锐化',
      '明瞭度': '清晰度',
      'グレイン': '颗粒',
    };
    return (_ja ? jaMap : zhMap)[name] ?? name;
  }
}
