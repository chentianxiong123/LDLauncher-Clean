# LDLauncher-Clean

雷电模拟器 9 启动器去广告版 - 纯净桌面，无广告干扰

> ⚠️ **免责声明**：本项目仅供技术学习和研究使用，非商业用途。请勿用于任何非法目的。

## 📋 项目简介

本项目通过对雷电模拟器 9 的启动器（Launcher3）APK 进行反编译和修改，移除了其中的广告组件，包括：

- ✅ 首屏广告
- ✅ 底部游戏栏广告
- ✅ 顶部搜索栏广告
- ✅ 搜索放大镜图标

## 🎯 功能特点

| 功能 | 原版 | 修改后 |
|------|------|--------|
| 首屏广告 | ❌ 有 | ✅ 无 |
| 底部游戏栏 | ❌ 有广告 | ✅ 纯净 |
| 搜索栏广告 | ❌ 有 | ✅ 无 |
| 搜索放大镜 | ❌ 有 | ✅ 无 |
| 桌面功能 | ✅ 完整 | ✅ 完整 |

## 📦 安装方法

### 前置条件

- Windows 系统
- 雷电模拟器 9 已安装并运行
- ADB 工具（模拟器自带，位于模拟器安装目录的 ` adb\ ` 文件夹）

### 一键安装（推荐）

```bash
# 1. 打开命令提示符，进入项目目录
cd C:\path\to\LDLauncher-Clean

# 2. 运行一键安装脚本
install.bat
```

### 手动安装

```bash
# 1. 确保模拟器正在运行
adb devices

# 2. 安装修改后的 APK
adb install -r release\LDLauncher-Clean-1.0.apk

# 3. 启动修改后的启动器
adb shell am start -n com.android.launcher3.mod/com.android.launcher3.Launcher

# 4. （可选）设置为默认启动器
adb shell pm set-home-activity com.android.launcher3.mod/com.android.launcher3.Launcher
```

## 🔧 技术细节

### 修改原理

通过以下方式移除广告：

1. **Smali 代码修改**
   - 禁用广告 SDK 初始化
   - 禁用广告加载方法
   - 添加 `return-void` 指令阻止广告显示

2. **布局文件修改**
   - 隐藏搜索放大镜图标
   - 保留搜索功能但移除广告元素

3. **AndroidManifest 修改**
   - 移除广告服务
   - 更改包名避免冲突

### 修改的文件

| 文件 | 修改内容 |
|------|----------|
| `LdHotSeatAdImp.smali` | 禁用底部游戏栏广告加载 |
| `LdSearchView.smali` | 禁用搜索视图初始化 |
| `FirstScreenManager.smali` | 禁用首屏广告管理 |
| `AdSdkInterface.smali` | 禁用广告 SDK 初始化 |
| `search_view_layout.xml` | 隐藏搜索放大镜图标 |
| `AndroidManifest.xml` | 移除广告服务，更改包名 |

### 技术栈

- 反编译工具：[Apktool](https://apktool.org/)
- APK 签名工具：JDK 17 + jarsigner
- 调试工具：Android ADB

## 📚 文档

- [修改指南](docs/MODIFICATION_GUIDE.md) - 详细的修改步骤和原理
- [故障排查](docs/TROUBLESHOOTING.md) - 常见问题及解决方案
- [脚本说明](docs/SCRIPTS.md) - 自动化脚本使用说明

## 🔄 更新日志

### v1.0.0 (2026-10-12)
- ✅ 首次发布
- ✅ 移除所有广告组件
- ✅ 保持桌面功能完整
- ✅ 提供一键安装脚本

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目仅供个人学习和研究使用。

- ❌ 不得用于商业用途
- ❌ 不得修改后重新分发
- ✅ 欢迎技术交流和讨论

## ⚠️ 风险提示

1. **系统兼容性**：修改后的 APK 使用调试密钥签名，可能与部分系统应用冲突
2. **更新覆盖**：模拟器更新可能会覆盖修改后的启动器
3. **数据清除**：建议首次安装时清除应用数据

## 📧 联系方式

- GitHub Issues：[提交问题](https://github.com/your-name/Launcher3_mod_apktool/issues)

---

**最后更新**：2026-10-12  
**版本**：1.0.0  
**维护者**：LDLauncher-Clean Team