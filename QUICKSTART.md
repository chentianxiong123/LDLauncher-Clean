# 快速开始

## 3 步安装 LDLauncher-Clean

### 步骤 1: 下载 APK

从 [Releases](https://github.com/chentianxiong123/Launcher3_mod_apktool/releases) 下载最新版本。

### 步骤 2: 运行安装脚本

双击 `install.bat`，等待安装完成。

### 步骤 3: 设置默认启动器

```bash
adb shell pm set-home-activity com.android.launcher3.mod/com.android.launcher3.Launcher
```

---

## 常见问题

**Q: 安装失败怎么办？**

A: 查看 [故障排查](docs/TROUBLESHOOTING.md) 文档。

**Q: 如何更新？**

A: 重新下载最新 APK 并运行 install.bat。

**Q: 如何回滚？**

```bash
adb uninstall com.android.launcher3.mod
```

---

## 贡献

欢迎提交 Issue 和 Pull Request！

查看 [贡献指南](docs/CONTRIBUTING.md) 了解更多信息。