# Google Play 上架资料草稿

## 基础信息

- App name: 推活日记 / チェキる
- Package name: com.qianyu.oshiapp
- Version: 1.0.0
- Version code: 1
- Category suggestion: Tools / Lifestyle
- Developer: 千雨
- Contact: QQ 2087074589
- App type: Local-only utility app

## Short Description

本地管理チェキ照片、推し资料和 Live 记录的轻量工具。

## Full Description

推活日记是一款面向推活用户的本地记录工具，可用于整理チェキ照片、推し资料、团体信息和 Live 记录。用户可以添加照片、记录拍摄日期与备注，管理推し和团体资料，并对照片进行裁剪、调整和滤镜处理。

本应用不提供账号注册或登录功能，不接入服务器、网站、云同步、广告 SDK 或统计 SDK。用户数据主要保存在当前设备本地。

## Privacy Policy Notes

Google Play 需要一个公开可访问的隐私政策 URL。App 内已经有隐私政策页面，但 Play Console 仍需要填写公网 URL。

建议将隐私政策发布到 GitHub Pages、Cloudflare Pages、Vercel 或个人网站。隐私政策页面应包含：

- App 名称和开发者主体
- 收集/处理的数据类别
- 数据用途
- 是否共享数据
- 是否上传到服务器
- 数据保留与删除方式
- 儿童隐私说明
- 联系方式

## Data Safety Form Suggested Answers

### Does your app collect or share any of the required user data types?

建议根据 Google Play 对“collect”的定义谨慎填写。你的 App 不把数据传出设备，也不上传到开发者服务器；如果 Play Console 将“仅在设备本地处理且不离开设备”的数据排除在收集之外，可以选择不收集。

推荐说明：

- App does not transmit user data off device to the developer or third parties.
- User-created photos, notes and records are stored locally on the device.
- Users may manually export backups or share files using system share features.

### Is all user data collected by your app encrypted in transit?

如果选择“不收集用户数据”，该问题通常不适用。

如果需要解释：本应用不向开发者服务器传输用户数据；用户主动使用系统分享或导出备份时，由用户选择目标位置。

### Do you provide a way for users to request that their data is deleted?

选择 Yes。说明：

用户可以在 App 内删除单条记录、照片、缓存或全部本地数据。本应用不提供账号注册/登录，因此不涉及账号删除流程。

### Does your app share user data?

选择 No。说明：

本应用不向第三方出售、共享或转让用户数据，不接入广告 SDK、统计 SDK、社交登录 SDK 或云服务 SDK。

## Permissions Explanation

### Camera

Used only when the user chooses to take a photo, such as adding a cheki photo or avatar.

### Photos / Images

Used only when the user chooses images from the gallery, edits images, crops images, or imports image files.

### Storage / Files

Used for user-initiated actions such as saving images, creating backups, restoring backups, and importing/exporting filter presets.

## Target SDK

Current Android configuration:

- compileSdk: 36
- targetSdk: 36
- minSdk: 24

This satisfies Google Play's Android 15 / API 35 or higher target requirement for new apps and updates.

## AAB Build Command

Google Play normally expects an Android App Bundle:

```cmd
cd /d "C:\FILES\Android project\oshi_app"
flutter build appbundle --release
```

Expected output:

```text
build\app\outputs\bundle\release\app-release.aab
```

## Screenshot Suggestions

- First-launch privacy consent dialog
- Cheki list page
- Cheki detail page
- Add Cheki page
- Oshi list page
- Live calendar page
- Settings privacy section
- Privacy policy page
