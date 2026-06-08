# Google Play Data Safety 填写建议

> 说明：以下内容用于帮助填写 Play Console 的 Data safety 表单。最终仍以 Google Play 后台字段为准。

## 核心口径

本应用是完全本地工具类应用。

- 不提供账号注册或登录
- 不接入开发者服务器
- 不接入云同步
- 不接入广告 SDK
- 不接入统计 SDK
- 不向第三方出售、共享或转让用户数据
- 用户创建的数据主要保存在当前设备本地

## 是否收集或共享用户数据

建议口径：

本应用不会将用户数据传输到开发者服务器，也不会与第三方共享用户数据。用户添加的照片、记录、备注和备份主要保存在设备本地。

如果 Play Console 对“仅在设备本地处理且不离开设备”的数据允许不计为收集，可选择：

- Does your app collect or share any of the required user data types? No

如果后台要求声明本地处理的数据，可按以下用途说明：

- Photos and videos: 用户主动选择或拍摄，用于照片管理、裁剪、编辑和保存
- Files and docs: 用户主动备份、恢复、导入或导出时使用
- App activity / user-generated content: 仅保存在设备本地，用于应用内展示和管理

## 是否共享数据

选择：

- No

说明：

本应用不向第三方出售、共享或转让用户数据，不接入广告 SDK、统计 SDK、社交登录 SDK 或云服务 SDK。

## 数据是否加密传输

如果选择“不收集用户数据”，此项通常不适用。

如果需要说明：

本应用不会将用户数据传输到开发者服务器。用户主动使用系统分享、导出备份或保存到相册时，相关文件由用户自行选择目标位置。

## 是否允许用户删除数据

选择：

- Yes

说明：

用户可以在应用内删除单条记录、照片、缓存或全部本地数据。本应用不提供账号注册或登录功能，因此不涉及账号注销流程。

## 数据用途

如果需要选择用途，建议仅选择：

- App functionality

不要选择：

- Analytics
- Advertising or marketing
- Personalization
- Account management

## 儿童相关

本应用不是专门面向儿童的应用，不面向 13 岁以下儿童提供服务，也不主动收集儿童个人信息。
