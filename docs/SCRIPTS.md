# 脚本说明

本文档说明项目中所有自动化脚本的使用方法。

## 目录

1. [install.bat - 一键安装脚本](#installbat---一键安装脚本)
2. [rebuild_apk.bat - 重新编译脚本](#rebuild_apkbat---重新编译脚本)
3. [sign_apk.bat - 签名脚本](#sign_apkbat---签名脚本)
4. [diagnose.bat - 诊断脚本](#diagnosebat---诊断脚本)
5. [patch_dnplayer.py - Windows 客户端补丁脚本](#patch_dnplayerpy---windows-客户端补丁脚本)

---

## install.bat - 一键安装脚本

### 功能

自动完成修改后的启动器的安装和启动。

### 使用场景

- 首次安装 LDLauncher-Clean
- 更新到新版本
- 模拟器更新后重新安装

### 使用方法

```bash
# 1. 双击运行（推荐）
install.bat

# 2. 或在命令行运行
cd C:\path\to\LDLauncher-Clean
install.bat
```

### 执行流程

```
[1/5] 检查模拟器连接
    ↓
[2/5] 安装修改后的 APK
    ↓
[3/5] 清除应用数据
    ↓
[4/5] 启动修改后的启动器
    ↓
[5/5] 完成提示
```

### 前置条件

- ✅ 雷电模拟器 9 已启动
- ✅ ADB 在系统 PATH 中
- ✅ APK 文件在 `release\` 目录

### 常见问题

| 问题 | 解决 |
|------|------|
| 找不到 ADB | 将模拟器 `adb` 目录添加到 PATH |
| 未检测到模拟器 | 确保模拟器正在运行 |
| 安装失败 | 检查 APK 文件是否完整 |
| 启动失败 | 手动执行 `adb shell am start ...` |

---

## rebuild_apk.bat - 重新编译脚本

### 功能

将修改后的源码重新编译为 APK。

### 使用场景

- 修改了 Smali 代码后
- 修改了布局文件后
- 修改了 AndroidManifest 后

### 使用方法

```bash
# 1. 确保源码在 launcher_data 目录
# 2. 运行编译脚本
scripts\rebuild_apk.bat
```

### 脚本内容

```batch
@echo off
chcp 65001 >nul
echo 正在编译 APK...

java -jar "C:\Users\YOUR_USERNAME\tools\apktool_3.0.3.jar" b launcher_data -o release\LDLauncher-Clean-1.0.apk

if %errorlevel% equ 0 (
    echo [OK] 编译成功！
    echo APK 已生成：release\LDLauncher-Clean-1.0.apk
) else (
    echo [错误] 编译失败！
    echo 请检查修改的文件是否有语法错误
)

pause
```

### 注意事项

- 确保修改的文件保存正确
- 检查 Smali 语法（缩进、指令格式）
- 检查 XML 布局语法（标签闭合、属性引用）

---

## sign_apk.bat - 签名脚本

### 功能

使用调试密钥对 APK 进行签名。

### 使用场景

- 重新编译 APK 后
- 生成新的 APK 文件后
- 更换签名密钥后

### 使用方法

```bash
# 1. 确保 APK 已编译完成
# 2. 运行签名脚本
scripts\sign_apk.bat
```

### 脚本内容

```batch
@echo off
chcp 65001 >nul
echo 正在签名 APK...

set APK_PATH=release\LDLauncher-Clean-1.0.apk
set KEYSTORE=launcher.keystore
set KEY_ALIAS=launcher
set PASSWORD=android

# 检查密钥库是否存在
if not exist "%KEYSTORE%" (
    echo [警告] 密钥库不存在，正在生成...
    keytool -genkey -v -keystore %KEYSTORE% -alias %KEY_ALIAS% -keyalg RSA -keysize 2048 -validity 10000
    pause
)

# 签名 APK
"C:\Users\YOUR_USERNAME\tools\jdk-17.0.20.1\bin\jarsigner.exe" -keystore %KEYSTORE% -storepass %PASSWORD% -keypass %PASSWORD% -sigalg SHA256withRSA %APK_PATH% %KEY_ALIAS%

if %errorlevel% equ 0 (
    echo [OK] 签名成功！
) else (
    echo [错误] 签名失败！
)

# 验证签名
echo 验证签名...
"C:\Users\YOUR_USERNAME\tools\jdk-17.0.20.1\bin\jarsigner.exe" -verify %APK_PATH%

pause
```

### 密钥库配置

| 参数 | 值 |
|------|-----|
| 密钥库文件 | `launcher.keystore` |
| 密钥别名 | `launcher` |
| 密钥密码 | `android` |
| 签名算法 | `SHA256withRSA` |
| 有效期 | 10000 天（约 27 年） |

### 安全提示

- ⚠️ 此密钥仅供学习和测试使用
- ❌ 不要用于商业发布
- ❌ 不要泄露密钥库文件

---

## diagnose.bat - 诊断脚本

### 功能

收集系统诊断信息，帮助排查问题。

### 使用场景

- 安装后出现问题
- 提交 Issue 时收集信息
- 检查系统配置

### 使用方法

```bash
# 1. 运行诊断脚本
scripts\diagnose.bat

# 2. 将输出保存到文件
scripts\diagnose.bat > diagnose_output.txt
```

### 脚本内容

```batch
@echo off
chcp 65001 >nul
echo === LDLauncher-Clean 诊断报告 ===
echo.
echo [时间]
date /t
time /t
echo.

echo [ADB 版本]
adb version
echo.

echo [设备列表]
adb devices -l
echo.

echo [启动器包]
adb shell pm list packages | findstr launcher3
echo.

echo [默认启动器]
adb shell settings get secure home_package
echo.

echo [应用信息]
adb shell dumpsys package com.android.launcher3.mod | findstr "versionName\|versionCode\|lastUpdateTime"
echo.

echo [UI 层级]
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml ui.xml
echo [OK] UI 层级已保存到 ui.xml
echo.

echo [广告相关视图检查]
findstr /i "ldmnq\|hotseat\|search_iv" ui.xml
echo.

echo [最近日志]
adb logcat -d -t 100 | findstr "launcher3.mod\|ldmnq\|FATAL"
echo.

echo [系统属性]
adb shell getprop ro.build.version.release
adb shell getprop ro.product.model
echo.

echo === 诊断完成 ===
echo.
echo 请将此输出提供给问题报告
pause
```

### 输出文件

| 文件 | 说明 |
|------|------|
| `diagnose_output.txt` | 诊断输出（可选保存） |
| `ui.xml` | UI 层级导出 |
| `logcat.txt` | 系统日志（可选导出） |

---

## 脚本集成

### 完整工作流

```
修改源码
    ↓
rebuild_apk.bat  ← 编译
    ↓
sign_apk.bat     ← 签名
    ↓
install.bat      ← 安装
    ↓
diagnose.bat     ← 验证（可选）
```

### 一键完成脚本

创建 `full_build.bat`：

```batch
@echo off
chcp 65001 >nul
echo === 完整构建流程 ===

echo [1/3] 编译...
call scripts\rebuild_apk.bat
if %errorlevel% neq 0 goto error

echo [2/3] 签名...
call scripts\sign_apk.bat
if %errorlevel% neq 0 goto error

echo [3/3] 安装...
call install.bat
if %errorlevel% neq 0 goto error

echo.
echo === 构建完成 ===
pause
exit /b 0

:error
echo.
echo === 构建失败 ===
pause
exit /b 1
```

---

## 自定义脚本

### 修改脚本路径

根据实际情况修改脚本中的路径：

```batch
# ADB 路径
set ADB_PATH=C:\Program Files\ldplayer9box\adb\adb.exe

# JDK 路径
set JDK_PATH=C:\Users\YOUR_USERNAME\tools\jdk-17.0.20.1

# Apktool 路径
set APKTOOL=C:\Users\YOUR_USERNAME\tools\apktool_3.0.3.jar

# 项目路径
set PROJECT_DIR=C:\path\to\LDLauncher-Clean
```

### 添加新功能

在脚本中添加自定义逻辑：

```batch
:: 示例：自动备份原版 APK
if exist "backup\original_launcher.apk" (
    echo 已存在备份，跳过
) else (
    echo 备份原版 APK...
    adb pull /data/app/com.android.launcher3-xxxxx/base.apk backup\original_launcher.apk
)
```

---

## 故障排查脚本

### 快速检查

```batch
@echo off
echo 快速检查...

:: 检查 ADB
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ ADB 未配置
    exit /b 1
)

:: 检查设备
adb devices | findstr "device" >nul
if %errorlevel% neq 0 (
    echo ❌ 模拟器未连接
    exit /b 1
)

:: 检查应用
adb shell pm list packages | findstr "launcher3.mod" >nul
if %errorlevel% neq 0 (
    echo ❌ 应用未安装
    exit /b 1
)

:: 检查默认启动器
adb shell settings get secure home_package | findstr "launcher3.mod" >nul
if %errorlevel% neq 0 (
    echo ⚠️  未设置为默认启动器
) else (
    echo ✅ 已设置为默认启动器
)

echo ✅ 所有检查通过
pause
```

---

## patch_dnplayer.py - Windows 客户端补丁脚本

### 功能

对雷电模拟器 9 的 Windows 客户端主程序 `dnplayer.exe` 打二进制补丁，
在 9 个广告函数入口写入 `ret` 指令，使广告逻辑直接短路。

### 使用场景

- 去除客户端启动广告 / AppActive 弹窗广告 / 广告视频
- LDPlayer 版本升级后重新适配补丁
- 对照测试（还原原始版后恢复补丁）

### 前置条件

- ✅ Python 3 + pefile 库（`pip install pefile`）
- ✅ `dnplayer.exe` 已退出（运行中会 PermissionError）
- ✅ 首次运行前备份原始文件

### 使用方法

```bash
:: 1. 退出 LDPlayer
taskkill /F /IM dnplayer.exe /T

:: 2. 备份（仅首次）
copy /y C:\leidian\LDPlayer9\dnplayer.exe C:\leidian\LDPlayer9\dnplayer.exe.bak

:: 3. 打补丁
python scripts\patch_dnplayer.py

:: 4. 启动测试
start C:\leidian\LDPlayer9\dnplayer.exe
```

### 输出示例

```
PATCH _showLaunchAd            VA 0x4CE8A0 -> off 0xCDCA0 : c21400
PATCH canShowAppActiveAD       VA 0x44BC30 -> off 0x4B030 : 31c0c20400
PATCH preShowAppActiveAd       VA 0x44C360 -> off 0x4B760 : c20c00
PATCH updateLaunchAdControl    VA 0x5E1F40 -> off 0x1E1340 : c3
PATCH onLaunchAdBtnClicked     VA 0x4CDF90 -> off 0xCD390 : c3
PATCH _checkShowNextLaunchAd   VA 0x4CF080 -> off 0xCE480 : c21400
PATCH loadAppActiveAd          VA 0x44AEE0 -> off 0x4A2E0 : c3
PATCH isVideoOK                VA 0x4C7600 -> off 0xC6A00 : 31c0c3
PATCH downloadVid              VA 0x4C8080 -> off 0xC7480 : c3
WROTE C:\leidian\LDPlayer9\dnplayer.exe (9 patches)
```

> 脚本**幂等**：重复运行会因前缀校验（原字节应为 `55 8B EC`）而全部 SKIP，
> 不会重复打补丁或破坏已修补版本。

### 版本切换

```bat
:: 用修改版
copy /y C:\leidian\LDPlayer9\dnplayer-mod.exe C:\leidian\LDPlayer9\dnplayer.exe

:: 还原原始版
copy /y C:\leidian\LDPlayer9\dnplayer.exe.bak C:\leidian\LDPlayer9\dnplayer.exe
```

> 详细逆向分析见 [Windows 客户端破解指南](DNPLAYER_PATCH_GUIDE.md)

---

## 脚本清单

| 脚本 | 用途 | 运行时机 |
|------|------|----------|
| `install.bat` | 一键安装 | 首次安装/更新 |
| `scripts\rebuild_apk.bat` | 重新编译 | 修改源码后 |
| `scripts\sign_apk.bat` | 签名 APK | 编译后 |
| `scripts\diagnose.bat` | 诊断问题 | 出现问题时 |
| `scripts\quick_check.bat` | 快速检查 | 安装后验证 |
| `scripts\patch_dnplayer.py` | **dnplayer.exe 补丁** | 客户端广告去除 |

---

**文档版本**：1.1.0  
**最后更新**：2026-10-13  
**脚本数量**：6 个核心脚本