# 修改指南

本文档详细说明 LDLauncher-Clean 的修改原理和技术实现。

## 目录

1. [工作原理](#工作原理)
2. [环境准备](#环境准备)
3. [反编译 APK](#反编译-apk)
4. [修改 Smali 代码](#修改-smali-代码)
5. [修改布局文件](#修改布局文件)
6. [修改 AndroidManifest](#修改-androidmanifest)
7. [重新编译](#重新编译)
8. [签名 APK](#签名-apk)
9. [安装验证](#安装验证)

---

## 工作原理

### 广告加载流程

```
┌─────────────────┐
│   启动器启动     │
└────────┬────────┘
         ▼
┌─────────────────┐
│ AdSdkInterface  │ ← 广告 SDK 初始化
│   .initOnce()   │
└────────┬────────┘
         ▼
┌─────────────────┐
│ FirstScreenMgr  │ ← 首屏广告管理
│   .init()       │
└────────┬────────┘
         ▼
┌─────────────────┐
│ LdHotSeatAdImp  │ ← 底部游戏栏广告
│ .showLauncher() │
└────────┬────────┘
         ▼
┌─────────────────┐
│ LdSearchView    │ ← 搜索栏广告
│   .init()       │
└─────────────────┘
```

### 修改策略

通过以下方式中断广告加载：

1. **Smali 层面**：在关键方法开头添加 `return-void`
2. **布局层面**：隐藏广告视图
3. **清单层面**：移除广告服务

---

## 环境准备

### 必需工具

| 工具 | 版本 | 用途 |
|------|------|------|
| JDK | 17+ | APK 签名 |
| Apktool | 3.0.3 | 反编译/编译 APK |
| ADB | - | 设备调试 |
| Python | 3.8+ | 辅助脚本 |

### 工具路径

```bash
# JDK
C:\Users\YOUR_USERNAME\tools\jdk-17.0.20.1

# Apktool
C:\Users\YOUR_USERNAME\tools\apktool_3.0.3.jar

# ADB
C:\Program Files\ldplayer9box\adb
```

---

## 反编译 APK

### 1. 提取启动器 APK

```bash
# 连接到模拟器
adb connect localhost:5555

# 获取应用路径
adb shell pm path com.android.launcher3

# 拉取 APK 到本地
adb pull /data/app/com.android.launcher3-xxxxx/base.apk Launcher3.apk
```

### 2. 反编译 APK

```bash
java -jar apktool_3.0.3.jar d Launcher3.apk -o launcher_data
```

### 3. 目录结构

```
launcher_data/
├── AndroidManifest.xml      # 应用清单
├── smali/                    # 反编译的 Java 代码
│   └── com/
│       ├── ldmnq/            # 广告 SDK
│       └── android/launcher3/# 启动器代码
├── res/                      # 资源文件
│   ├── layout/               # 布局文件
│   └── values/               # 值资源
└── ...
```

---

## 修改 Smali 代码

### 修改原理

在关键方法的开头添加 `return-void` 指令，使方法直接返回，不执行后续代码。

### 1. 禁用底部游戏栏广告

**文件**：`smali/com/ldmnq/LdHotSeatAdImp.smali`

```smali
.method public showLauncherIcon(Landroid/content/Context;Landroid/widget/FrameLayout;)V
    .locals 2
    return-void    # ← 添加这一行，方法直接返回
    
    .line 124
    iget-boolean v0, p0, Lcom/ldmnq/LdHotSeatAdImp;->isSuccess:Z
    ...
```

**同时禁用数据加载**：

```smali
.method private static getLauncherIconData(...)V
    .locals 3
    return-void    # ← 添加这一行
    
    ...
```

### 2. 禁用搜索视图广告

**文件**：`smali/com/ldmnq/LdSearchView.smali`

```smali
.method public static init(Landroid/app/Activity;ZLcom/android/launcher3/DragController;)V
    .locals 6
    return-void    # ← 添加这一行
    
    .line 86
    new-instance v0, Lcom/ldmnq/LdSearchView$WallpaperChangedBroadcast;
    ...
```

### 3. 禁用首屏广告管理

**文件**：`smali/com/ldmnq/common/manager/FirstScreenManager.smali`

```smali
.method public init(Lcom/android/launcher3/Launcher;)V
    .locals 4
    return-void    # ← 添加这一行
    
    const-string v0, "first_screen.data"
    ...
```

### 4. 禁用广告 SDK 初始化

**文件**：`smali/com/ldmnq/AdSdkInterface.smali`

```smali
.method public static initOnce(Landroid/content/Context;)V
    .locals 0
    return-void    # ← 添加这一行
    
    ...
```

---

## 修改布局文件

### 隐藏搜索放大镜图标

**文件**：`res/layout*/search_view_layout.xml`

修改前：
```xml
<com.changzhi.ld.widget.ui.LdImageView 
    android:id="@id/search_iv" 
    android:layout_width="24.0dp" 
    android:layout_height="24.0dp" />
```

修改后：
```xml
<com.changzhi.ld.widget.ui.LdImageView 
    android:id="@id/search_iv" 
    android:visibility="gone"  # ← 添加这一行
    android:layout_width="24.0dp" 
    android:layout_height="24.0dp" />
```

**注意**：需要修改所有布局变体（共 9 个文件）：
- `res/layout/`
- `res/layout-land/`
- `res/layout-land-v22/`
- `res/layout-port/`
- `res/layout-sw600dp-port/`
- `res/layout-sw600dp-port-v22/`
- `res/layout-sw720dp/`
- `res/layout-sw720dp-v22/`
- `res/layout-v22/`

---

## 修改 AndroidManifest

### 1. 更改包名

**原因**：避免与原版冲突，使用调试密钥签名

```xml
<!-- 修改前 -->
<manifest package="com.android.launcher3">

<!-- 修改后 -->
<manifest package="com.android.launcher3.mod">
```

### 2. 移除广告服务

```xml
<!-- 删除这一行 -->
<service android:name="com.ldmnq.service.LauncherMessageService">
    ...
</service>
```

### 3. 修改 ContentProvider 授权

```xml
<!-- 修改前 -->
<provider android:authorities="com.android.launcher3.settings">

<!-- 修改后 -->
<provider android:authorities="com.android.launcher3.mod.settings">
```

### 4. 更新引用

修改所有 smali 文件中对 `com.android.launcher3.settings` 的引用：

```bash
# 批量替换
find smali -name "*.smali" -exec sed -i 's/com.android.launcher3.settings/com.android.launcher3.mod.settings/g' {} \;
```

---

## 重新编译

### 编译命令

```bash
java -jar apktool_3.0.3.jar b launcher_data -o Launcher3_mod.apk
```

### 常见问题

| 问题 | 解决方案 |
|------|----------|
| `Error: smali has not changed` | 确保修改了 smali 文件 |
| `Resource parsing error` | 检查布局文件语法 |
| `Missing resource` | 确保没有删除必要资源 |

---

## 签名 APK

### 1. 生成密钥库

```bash
keytool -genkey -v -keystore launcher.keystore -alias launcher -keyalg RSA -keysize 2048 -validity 10000
# 密码：android
```

### 2. 签名 APK

```bash
jarsigner -keystore launcher.keystore -storepass android -keypass android -sigalg SHA256withRSA Launcher3_mod.apk launcher
```

### 3. 验证签名

```bash
jarsigner -verify Launcher3_mod.apk
```

---

## 安装验证

### 1. 安装到设备

```bash
adb install -r Launcher3_mod.apk
```

### 2. 启动应用

```bash
adb shell am start -n com.android.launcher3.mod/com.android.launcher3.Launcher
```

### 3. 验证广告已移除

```bash
# 检查 UI 层级
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml

# 搜索广告相关视图
grep "ldmnq\|hotseat\|search_iv" ui.xml
```

### 4. 设置默认启动器（可选）

```bash
adb shell pm set-home-activity com.android.launcher3.mod/com.android.launcher3.Launcher
```

---

## 完整修改清单

| 文件 | 行号 | 修改内容 |
|------|------|----------|
| `LdHotSeatAdImp.smali` | 470, 1847 | 添加 `return-void` |
| `LdSearchView.smali` | 125 | 添加 `return-void` |
| `FirstScreenManager.smali` | 3406 | 添加 `return-void` |
| `AdSdkInterface.smali` | 322 | 添加 `return-void` |
| `search_view_layout.xml` (9 个) | 5 | 添加 `android:visibility="gone"` |
| `AndroidManifest.xml` | 2, 30, 108 | 更改包名，移除服务 |

---

## 回滚方法

如需恢复原版：

```bash
# 卸载修改版
adb uninstall com.android.launcher3.mod

# 原版启动器仍在系统中，无需额外操作
```

---

**文档版本**：1.0.0  
**最后更新**：2026-10-12