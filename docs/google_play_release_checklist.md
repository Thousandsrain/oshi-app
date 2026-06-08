# Google Play 发布前清单

## 已完成

- 包名：com.qianyu.oshiapp
- compileSdk：36
- targetSdk：36
- minSdk：24
- App 内隐私政策入口
- App 内用户协议入口
- App 内权限说明入口
- 首次启动隐私同意弹窗
- Release APK 已测试

## 还需要完成

1. 重新构建 AAB

```cmd
cd /d "C:\FILES\Android project\oshi_app"
flutter build appbundle --release
```

产物：

```text
build\app\outputs\bundle\release\app-release.aab
```

2. 发布隐私政策公网 URL

建议把 `docs/privacy_policy_google_play_zh.md` 发布到 GitHub Pages、Cloudflare Pages、Vercel 或个人网站。

3. 准备截图

建议至少准备：

- 首次启动隐私同意弹窗
- Cheki 列表页
- Cheki 详情页
- 添加 Cheki 页面
- 推し列表页
- Live 日历页
- 设置页的使用与隐私入口
- 隐私政策页面

4. Play Console 填表

需要填写：

- Store listing
- App content
- Data safety
- Privacy Policy URL
- Content rating
- Target audience
- Production release

5. 上架前最终测试

- 安装 AAB 或 release 包
- 首次启动同意弹窗
- 相机拍摄
- 相册选择
- 保存到相册
- 备份恢复
- 图片头像恢复显示
- 设置页隐私政策/用户协议/权限说明
