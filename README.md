# 推活日记 / チェキる

推活日记是一款使用 Flutter 开发的本地工具类应用，用于管理チェキ照片、推し资料、团体信息和 Live 记录。

应用不提供账号注册或登录功能，不接入服务器、网站、云同步、广告 SDK 或统计 SDK。用户创建的数据主要保存在当前设备本地。

## 功能

- チェキ照片添加、裁剪、编辑和保存
- 推し资料、头像、生日、初推日和备注管理
- 团体资料与成员关联管理
- Live 日期、地点、时间、出演推し/团体记录
- 本地数据备份与恢复
- 滤镜预设导入、导出和分享
- App 内隐私政策、用户协议和权限说明

## 技术栈

- Flutter / Dart
- Android native Kotlin MethodChannel
- SQLite via sqflite

## 开发环境

```bash
flutter pub get
flutter run
```

## 构建

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

## 隐私政策

隐私政策文本位于：

```text
docs/privacy_policy_google_play_zh.md
docs/privacy-policy.html
```

## 开源许可

本项目使用 MIT License。详见 [LICENSE](LICENSE)。

## 安全提醒

请不要提交签名密钥、`key.properties`、`.jks` 文件、开发者后台资料或任何个人身份材料。
