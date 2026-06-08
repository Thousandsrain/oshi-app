import 'package:flutter/material.dart';
import '../app_language.dart';

enum LegalDocumentType { privacy, agreement, permissions, filing }

class LegalPage extends StatelessWidget {
  final LegalDocumentType type;

  const LegalPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final t = AppLanguageScope.textOf(context);
    final content = _content(t);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F5),
      appBar: AppBar(title: Text(_title(t))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(t),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.policyUpdatedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 18),
                ...content.map((section) => _PolicySection(section: section)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _title(AppText t) {
    switch (type) {
      case LegalDocumentType.privacy:
        return t.privacyPolicy;
      case LegalDocumentType.agreement:
        return t.userAgreement;
      case LegalDocumentType.permissions:
        return t.permissionDescription;
      case LegalDocumentType.filing:
        return t.appFiling;
    }
  }

  List<PolicySection> _content(AppText t) {
    final ja = t.currentLanguage == AppLanguage.ja;
    if (ja) return _jaContent();
    return _zhContent();
  }

  List<PolicySection> _zhContent() {
    switch (type) {
      case LegalDocumentType.privacy:
        return const [
          PolicySection(
            title: '一、应用说明',
            paragraphs: [
              '推活日记（チェキる）是一款完全本地运行的チェキ、推し、Live 信息管理工具。',
              '本应用不提供账号注册或登录功能，不接入服务器、网站、云同步、广告 SDK 或统计 SDK。用户创建的数据主要保存在当前设备本地。',
              '开发者：千雨。联系方式：QQ 2087074589。',
            ],
          ),
          PolicySection(
            title: '二、处理的数据类别与用途',
            paragraphs: [
              '照片和图片：用于添加チェキ照片、推し头像、团体图片、Live 图片，以及进行裁剪、编辑、滤镜处理和保存。',
              '用户主动填写的内容：包括チェキ记录、推し信息、团体信息、Live 信息、日期、备注、颜色、滤镜预设等，用于在应用内展示、检索和管理。',
              '文件和备份数据：用于用户主动创建本地备份、恢复备份、导入或导出滤镜预设。',
              '本应用不会收集设备唯一标识、位置信息、通讯录、短信、通话记录或其他与功能无关的信息。',
            ],
          ),
          PolicySection(
            title: '三、数据收集、共享与传输',
            paragraphs: [
              '本应用处理的数据主要保存在当前设备本地，不会主动上传到开发者服务器。',
              '本应用不向第三方出售、共享或转让用户数据。',
              '本应用不接入广告 SDK、统计 SDK、社交登录 SDK 或云服务 SDK。',
              '由于本应用不进行服务器传输，通常不存在向开发者服务器传输用户数据的过程。用户主动使用系统分享、导出备份或保存到相册时，相关文件将由用户自行选择保存或分享的位置。',
            ],
          ),
          PolicySection(
            title: '四、权限使用',
            paragraphs: [
              '相机权限：仅在你选择拍摄照片时使用。',
              '相册/图片读取权限：仅在你选择从相册导入图片或读取图片文件时使用。',
              '存储/文件访问权限：仅在备份、恢复、导入滤镜预设、保存图片等用户主动操作时使用。',
            ],
          ),
          PolicySection(
            title: '五、数据保留与删除',
            paragraphs: [
              '本应用不提供账号注册或登录功能，因此不涉及账号注销流程。',
              '你添加的数据会保留在当前设备中，直到你主动删除相关记录、清除缓存、删除全部数据、卸载应用，或删除相关备份文件。',
              '你可以在应用内删除单条记录、照片、缓存或全部本地数据。',
              '删除全部数据后，本应用会尝试删除本机保存的应用数据和应用内照片文件。已导出到外部位置的备份或图片需要你自行管理。',
            ],
          ),
          PolicySection(
            title: '六、数据安全',
            paragraphs: [
              '本应用不会把用户数据上传到开发者服务器。',
              '用户数据主要保存在设备本地，设备本身的安全性、系统权限控制、屏幕锁和备份文件保管由用户自行管理。',
              '请妥善保存导出的备份文件，避免将包含个人照片或记录的备份文件分享给不可信对象。',
            ],
          ),
          PolicySection(
            title: '七、个性化推荐与广告',
            paragraphs: [
              '本应用不提供个性化推荐服务，不根据用户信息进行画像，不投放广告，也不使用广告 SDK 或统计分析 SDK。',
            ],
          ),
          PolicySection(
            title: '八、儿童隐私',
            paragraphs: [
              '本应用不是专门面向儿童的应用，不面向 13 岁以下儿童提供服务，也不主动收集儿童个人信息。',
              '未成年人使用本应用时，应在监护人指导下使用，并由监护人妥善管理设备、照片和备份文件。',
            ],
          ),
          PolicySection(
            title: '九、政策更新与联系方式',
            paragraphs: ['如对隐私政策或数据处理有疑问，可通过“关于本应用”页面中的联系方式与开发者联系。'],
          ),
        ];
      case LegalDocumentType.agreement:
        return const [
          PolicySection(
            title: '一、服务内容',
            paragraphs: [
              '本应用为本地工具类应用，用于记录、编辑和管理用户自行添加的チェキ、推し和 Live 信息。',
              '用户应自行确认添加内容的合法性，并妥善保管自己的设备和备份文件。',
            ],
          ),
          PolicySection(
            title: '二、使用规则',
            paragraphs: [
              '请勿使用本应用保存、制作或传播违法违规内容。',
              '因用户自行删除数据、覆盖备份、丢失设备或误操作造成的数据损失，由用户自行承担。',
            ],
          ),
          PolicySection(
            title: '三、功能变更',
            paragraphs: [
              '开发者可能根据维护需要调整、优化或移除部分功能。',
              '本应用目前不提供联网账号、云同步或服务器存储服务。',
            ],
          ),
        ];
      case LegalDocumentType.permissions:
        return const [
          PolicySection(
            title: '相机权限',
            paragraphs: ['用于拍摄チェキ照片或推し/团体头像。未主动拍摄时不会调用相机。'],
          ),
          PolicySection(
            title: '相册/图片读取权限',
            paragraphs: ['用于从相册选择照片、裁剪图片、编辑图片或导入图片。未主动选择时不会读取相册图片。'],
          ),
          PolicySection(
            title: '存储/文件权限',
            paragraphs: ['用于保存图片到相册、备份数据、恢复备份、导入或导出滤镜预设。'],
          ),
          PolicySection(
            title: '网络权限',
            paragraphs: ['正式包不主动声明互联网权限。本应用不接入服务器，不进行账号登录、云同步、广告投放或统计上报。'],
          ),
        ];
      case LegalDocumentType.filing:
        return const [
          PolicySection(
            title: '备案状态',
            paragraphs: [
              '本应用为完全本地运行的工具类应用，不接入服务器、网站、账号登录或云服务。',
              '如应用市场要求提供 APP 备案信息，将在完成备案后于此处展示备案号。',
            ],
          ),
        ];
    }
  }

  List<PolicySection> _jaContent() {
    switch (type) {
      case LegalDocumentType.privacy:
        return const [
          PolicySection(
            title: '1. アプリについて',
            paragraphs: [
              'チェキるは、チェキ、推し、Live情報を端末内で管理するローカルツールです。',
              '本アプリはアカウント登録、ログイン、サーバー接続、Webサイト連携、クラウド同期、広告SDK、解析SDKを利用しません。',
              '開発者：千雨。連絡先：QQ 2087074589。',
            ],
          ),
          PolicySection(
            title: '2. 取り扱うデータと利用目的',
            paragraphs: [
              '写真・画像は、チェキ写真、推し画像、団体画像、Live画像の追加、編集、保存のために使用します。',
              'ユーザーが入力したチェキ記録、推し情報、団体情報、Live情報、日付、メモ、色、フィルタープリセットは、アプリ内での表示、整理、管理のために使用します。',
              'バックアップファイルは、ユーザーが選択した場合のバックアップ作成、復元、プリセットの入出力のために使用します。',
              '本アプリは端末識別子、位置情報、連絡先、SMS、通話履歴など、機能に不要な情報を収集しません。',
            ],
          ),
          PolicySection(
            title: '3. 共有と送信',
            paragraphs: [
              '本アプリのデータは主に端末内に保存され、開発者サーバーへ送信されません。',
              '本アプリはユーザーデータを第三者へ販売、共有、譲渡しません。',
              '広告SDK、解析SDK、ソーシャルログインSDK、クラウドサービスSDKは利用しません。',
            ],
          ),
          PolicySection(
            title: '4. 権限の利用',
            paragraphs: [
              'カメラ権限は、ユーザーが撮影を選択した場合にのみ使用します。',
              '写真・画像の読み取り権限は、ユーザーが画像を選択、編集、取り込みする場合にのみ使用します。',
              'ファイル関連の権限は、バックアップ、復元、画像保存、プリセットの入出力など、ユーザー操作に応じて使用します。',
            ],
          ),
          PolicySection(
            title: '5. 保持と削除',
            paragraphs: [
              '本アプリはアカウント登録やログインを提供しないため、アカウント削除手続きはありません。',
              'ユーザーが追加したデータは、削除、全データ削除、アプリのアンインストール、またはバックアップファイルの削除まで端末内に保持されます。',
              'ユーザーはアプリ内で記録、写真、キャッシュ、すべてのローカルデータを削除できます。',
              '外部に書き出したバックアップや画像は、ユーザー自身で管理してください。',
            ],
          ),
          PolicySection(
            title: '6. 子どものプライバシー',
            paragraphs: [
              '本アプリは13歳未満の子どもを対象としたものではなく、子どもの個人情報を意図的に収集しません。',
              '未成年者が利用する場合は、保護者の管理と同意のもとで利用してください。',
            ],
          ),
        ];
      case LegalDocumentType.agreement:
        return const [
          PolicySection(
            title: '1. サービス内容',
            paragraphs: ['本アプリは、ユーザーが追加したチェキ、推し、Live情報をローカルで管理するツールです。'],
          ),
          PolicySection(
            title: '2. 利用上の注意',
            paragraphs: [
              '違法または不適切な内容の保存、作成、配布には使用しないでください。',
              '誤操作、端末紛失、バックアップの上書き等によるデータ損失については、ユーザー自身で管理してください。',
            ],
          ),
          PolicySection(
            title: '3. 機能変更',
            paragraphs: ['開発者は、保守や改善のために機能を調整、変更、削除する場合があります。'],
          ),
        ];
      case LegalDocumentType.permissions:
        return const [
          PolicySection(title: 'カメラ', paragraphs: ['写真撮影を選択した場合にのみ使用します。']),
          PolicySection(title: '写真・画像', paragraphs: ['画像の選択、編集、取り込みのために使用します。']),
          PolicySection(title: 'ファイル', paragraphs: ['バックアップ、復元、画像保存、プリセット入出力のために使用します。']),
          PolicySection(title: 'ネットワーク', paragraphs: ['本アプリはサーバー接続、ログイン、クラウド同期、広告、解析を行いません。']),
        ];
      case LegalDocumentType.filing:
        return const [
          PolicySection(
            title: '備案情報',
            paragraphs: [
              '本アプリは完全ローカル動作のツールで、サーバー、Webサイト、ログイン、クラウドサービスを利用しません。',
              'アプリストア審査で備案情報が必要な場合、取得後にこのページへ表示します。',
            ],
          ),
        ];
    }
  }
}

class PolicySection {
  final String title;
  final List<String> paragraphs;

  const PolicySection({required this.title, required this.paragraphs});
}

class _PolicySection extends StatelessWidget {
  final PolicySection section;

  const _PolicySection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...section.paragraphs.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
