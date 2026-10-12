# 故障排查

本文档收录安装和使用 LDLauncher-Clean 过程中可能遇到的问题及解决方案。

## 目录

1. [安装问题](#安装问题)
2. [启动问题](#启动问题)
3. [广告残留](#广告残留)
4. [系统冲突](#系统冲突)
5. [其他问题](#其他问题)

---

## 安装问题

### 问题 1：找不到 ADB 工具

**错误信息**：
```
[错误] 未找到 ADB 工具！
```

**原因**：ADB 不在系统 PATH 中

**解决方案**：
```bash
# 方法 1：将 ADB 添加到 PATH
set PATH=%PATH%;C:\Program Files\ldplayer9box\adb

# 方法 2：直接运行 ADB
"C:\Program Files\ldplayer9box\adb\adb.exe" devices
```

---

### 问题 2：未检测到模拟器

**错误信息**：
```
[错误] 未检测到模拟器！
```

**原因**：模拟器未启动或 ADB 连接失败

**解决方案**：
```bash
# 1. 确保模拟器已启动
# 2. 手动连接 ADB
adb connect localhost:5555

# 3. 检查设备列表
adb devices
# 应该显示：emulator-5554  device
```

---

### 问题 3：APK 安装失败

**错误信息**：
```
adb: failed to install: INSTALL_FAILED_UPDATE_INCOMPATIBLE
```

**原因**：签名不匹配，原版是系统签名

**解决方案**：
```bash
# 1. 先卸载原版（如果可能）
adb uninstall com.android.launcher3

# 2. 或修改包名（我们已修改为 com.android.launcher3.mod）
# 3. 重新安装
adb install -r Launcher3_mod.apk
```

---

### 问题 4：APK 文件不存在

**错误信息**：
```
[错误] 未找到 APK 文件！
```

**原因**：APK 未放入 release 文件夹

**解决方案**：
```bash
# 确保 APK 在正确位置
release\LDLauncher-Clean-1.0.apk

# 或修改 install.bat 中的 APK_PATH
```

---

## 启动问题

### 问题 5：启动器启动失败

**错误信息**：
```
adb shell am start -n ...
Error: Activity not started
```

**原因**：应用未正确安装或权限问题

**解决方案**：
```bash
# 1. 检查应用是否安装
adb shell pm list packages | findstr launcher3.mod

# 2. 清除应用数据
adb shell pm clear com.android.launcher3.mod

# 3. 重新启动
adb shell am start -n com.android.launcher3.mod/com.android.launcher3.Launcher

# 4. 检查日志
adb logcat | findstr launcher3.mod
```

---

### 问题 6：启动器闪退

**症状**：启动后很快返回桌面

**原因**：应用崩溃

**解决方案**：
```bash
# 1. 查看崩溃日志
adb logcat -d | findstr "AndroidRuntime\|FATAL"

# 2. 常见原因
# - 签名问题：重新签名 APK
# - 包名冲突：卸载原版启动器
# - 资源缺失：确保 APK 完整

# 3. 强制停止并重启
adb shell am force-stop com.android.launcher3.mod
adb shell am start -n com.android.launcher3.mod/com.android.launcher3.Launcher
```

---

### 问题 7：设置为默认启动器失败

**错误信息**：
```
adb shell pm set-home-activity ...
Error: can't set default home activity
```

**原因**：系统限制或权限不足

**解决方案**：
```bash
# 方法 1：禁用原版启动器
adb shell pm disable-user --user 0 com.android.launcher3

# 方法 2：使用 Settings 命令
adb shell settings put system home_package com.android.launcher3.mod

# 方法 3：通过模拟器界面设置
# 长按桌面 → 设置 → 默认桌面 → 选择修改版
```

---

## 广告残留

### 问题 8：顶部仍有搜索放大镜

**症状**：修改后搜索图标仍然显示

**原因**：布局文件未正确修改

**解决方案**：
```bash
# 1. 确保修改了所有布局变体
# 共 9 个文件：
# - res/layout/search_view_layout.xml
# - res/layout-land/search_view_layout.xml
# - res/layout-land-v22/search_view_layout.xml
# - res/layout-port/search_view_layout.xml
# - res/layout-sw600dp-port/search_view_layout.xml
# - res/layout-sw600dp-port-v22/search_view_layout.xml
# - res/layout-sw720dp/search_view_layout.xml
# - res/layout-sw720dp-v22/search_view_layout.xml
# - res/layout-v22/search_view_layout.xml

# 2. 清除应用数据
adb shell pm clear com.android.launcher3.mod

# 3. 重新启动
adb shell am start -n com.android.launcher3.mod/com.android.launcher3.Launcher
```

---

### 问题 9：底部游戏栏仍有广告

**症状**：底部仍有游戏图标

**原因**：Smali 修改不完整

**解决方案**：
```bash
# 1. 检查 LdHotSeatAdImp.smali
# 确保 showLauncherIcon 方法开头有 return-void

# 2. 检查 getLauncherIconData 方法
# 确保也有 return-void

# 3. 重新编译并安装
java -jar apktool_3.0.3.jar b launcher_data -o Launcher3_mod.apk
adb install -r Launcher3_mod.apk
```

---

### 问题 10：首屏广告仍然出现

**症状**：启动时仍有广告闪屏

**原因**：FirstScreenManager 未正确禁用

**解决方案**：
```bash
# 1. 检查 FirstScreenManager.smali
# 确保 init 方法开头有 return-void

# 2. 检查 AdSdkInterface.smali
# 确保 initOnce 方法开头有 return-void

# 3. 清除缓存
adb shell pm clear com.android.launcher3.mod
adb shell rm -rf /data/data/com.android.launcher3.mod/cache
```

---

## 系统冲突

### 问题 11：模拟器更新后修改失效

**症状**：更新模拟器后广告回来了

**原因**：模拟器更新覆盖了系统启动器

**解决方案**：
```bash
# 1. 重新安装修改版
adb install -r Launcher3_mod.apk

# 2. 设置默认启动器
adb shell pm set-home-activity com.android.launcher3.mod/com.android.launcher3.Launcher

# 3. 建议：备份修改版 APK，更新后重新安装
```

---

### 问题 12：某些应用无法打开

**症状**：部分应用点击无反应

**原因**：启动器权限问题

**解决方案**：
```bash
# 1. 检查应用是否正常运行
adb shell am start -a android.intent.action.MAIN -n com.example.app/.MainActivity

# 2. 如果是启动器问题，尝试使用原版
adb shell pm enable com.android.launcher3

# 3. 或重新安装修改版
adb uninstall com.android.launcher3.mod
adb install -r Launcher3_mod.apk
```

---

### 问题 13：桌面图标无法拖动

**症状**：长按图标无法拖动

**原因**：修改后的启动器功能受限

**解决方案**：
```bash
# 1. 清除应用数据
adb shell pm clear com.android.launcher3.mod

# 2. 重启启动器
adb shell am force-stop com.android.launcher3.mod
adb shell am start -n com.android.launcher3.mod/com.android.launcher3.Launcher

# 3. 如果是严重问题，考虑使用原版
adb shell pm enable com.android.launcher3
```

---

## 其他问题

### 问题 14：APK 签名验证失败

**错误信息**：
```
jarsigner: keystore password was incorrect
```

**原因**：密钥库密码错误

**解决方案**：
```bash
# 1. 重新生成密钥库
keytool -genkey -v -keystore launcher.keystore -alias launcher -keyalg RSA -keysize 2048 -validity 10000
# 输入密码：android

# 2. 重新签名
jarsigner -keystore launcher.keystore -storepass android -keypass android -sigalg SHA256withRSA Launcher3_mod.apk launcher
```

---

### 问题 15：编译时资源错误

**错误信息**：
```
Error: resource not found
```

**原因**：布局文件语法错误或资源引用错误

**解决方案**：
```bash
# 1. 检查 XML 语法
# 确保标签正确闭合

# 2. 检查资源引用
# 确保引用的资源存在于 res/values 中

# 3. 使用 apktool 的完整重建
java -jar apktool_3.0.3.jar b launcher_data -o Launcher3_mod.apk --use-aapt2
```

---

### 问题 16：如何回滚到原版？

**步骤**：
```bash
# 1. 卸载修改版
adb uninstall com.android.launcher3.mod

# 2. 启用原版（如果被禁用）
adb shell pm enable com.android.launcher3

# 3. 重启模拟器
adb reboot
```

---

### 问题 17：如何检查修改是否生效？

**步骤**：
```bash
# 1. 导出 UI 层级
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml ui.xml

# 2. 检查广告相关视图
grep -i "ldmnq\|hotseat\|search_iv\|ad_" ui.xml

# 3. 检查应用包名
adb shell pm list packages | findstr launcher3

# 4. 查看运行日志
adb logcat -d | findstr "launcher3.mod\|ldmnq"
```

---

### 问题 18：模拟器端口不是 5555？

**原因**：雷电模拟器可能使用其他端口

**解决方案**：
```bash
# 1. 查看模拟器安装的 ADB 端口
adb devices -l

# 2. 或检查模拟器配置
# 通常在：C:\Program Files\ldplayer9box\config.xml

# 3. 常见端口
# 5555, 5557, 5559...
adb connect localhost:5555
adb connect localhost:5557
```

---

## 提交问题报告

遇到问题无法解决？请：

1. **收集信息**
   ```bash
   adb logcat -d > logcat.txt
   adb shell dumpsys package com.android.launcher3.mod > package_info.txt
   ```

2. **提交 Issue**
   - 描述问题现象
   - 提供错误日志
   - 说明复现步骤

3. **检查已有问题**
   - 避免重复提交
   - 查看是否有相似解决方案

---

## 快速诊断脚本

创建 `diagnose.bat`：

```batch
@echo off
echo === 诊断信息 ===
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
adb shell dumpsys package com.android.launcher3.mod | findstr "versionName\|versionCode"
echo.
echo [最近日志]
adb logcat -d -t 50 | findstr "launcher3.mod\|ldmnq\|FATAL"
echo.
echo === 诊断完成 ===
pause
```

---

**文档版本**：1.0.0  
**最后更新**：2026-10-12  
**问题数**：18 个常见问题