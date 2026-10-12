@echo off
chcp 65001 >nul
title LDLauncher-Clean 诊断工具
color 0B

echo.
echo ========================================
echo   LDLauncher-Clean 诊断报告
echo ========================================
echo.

REM 时间信息
echo [时间信息]
date /t
time /t
echo.

REM ADB 版本
echo [ADB 版本]
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ ADB 未找到！
    echo 请确保 ADB 在系统 PATH 中
    goto :error
)
adb version
echo.

REM 设备列表
echo [设备列表]
adb devices -l
echo.

REM 检查设备连接
adb devices | findstr "device" >nul
if %errorlevel% neq 0 (
    echo ❌ 未检测到模拟器！
    echo 请确保雷电模拟器已启动
    goto :error
)
echo ✅ 模拟器已连接
echo.

REM 启动器包检查
echo [启动器包检查]
adb shell pm list packages | findstr launcher3
echo.

REM 修改版启动器检查
adb shell pm list packages | findstr "launcher3.mod" >nul
if %errorlevel% equ 0 (
    echo ✅ 修改版启动器已安装
) else (
    echo ❌ 修改版启动器未安装
)
echo.

REM 默认启动器检查
echo [默认启动器]
adb shell settings get secure home_package
echo.

REM 应用详细信息
echo [应用详细信息]
adb shell dumpsys package com.android.launcher3.mod | findstr "versionName\|versionCode\|lastUpdateTime\|firstInstallTime"
echo.

REM UI 层级导出
echo [UI 层级导出]
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml ui.xml >nul 2>nul
if %errorlevel% equ 0 (
    echo ✅ UI 层级已保存到 ui.xml
) else (
    echo ⚠️  UI 层级导出失败
)
echo.

REM 广告相关视图检查
echo [广告相关视图检查]
if exist "ui.xml" (
    findstr /i "ldmnq\|hotseat\|search_iv\|ad_" ui.xml
    if %errorlevel% equ 0 (
        echo ⚠️  发现广告相关视图！
    ) else (
        echo ✅ 未发现广告相关视图
    )
)
echo.

REM 最近日志
echo [最近日志（广告相关）]
adb logcat -d -t 100 | findstr "launcher3.mod\|ldmnq\|LdHotSeat\|LdSearch"
echo.

REM 系统属性
echo [系统属性]
echo Android 版本：%adb shell getprop ro.build.version.release%
echo 设备型号：%adb shell getprop ro.product.model%
echo 模拟器版本：%adb shell getprop ro.build.display.id%
echo.

REM 检查是否设置为默认启动器
echo [启动器状态]
adb shell settings get secure home_package | findstr "launcher3.mod" >nul
if %errorlevel% equ 0 (
    echo ✅ 已设置为默认启动器
) else (
    echo ⚠️  未设置为默认启动器
    echo 建议执行：adb shell pm set-home-activity com.android.launcher3.mod/com.android.launcher3.Launcher
)
echo.

REM 检查应用进程
echo [应用进程]
adb shell ps -A | findstr launcher3.mod
if %errorlevel% equ 0 (
    echo ✅ 应用正在运行
) else (
    echo ⚠️  应用未运行
)
echo.

echo ========================================
echo   诊断完成
echo ========================================
echo.
echo 如需报告问题，请提供：
echo 1. 本诊断输出
echo 2. ui.xml 文件（如导出成功）
echo 3. 问题描述和复现步骤
echo.

pause

:error
echo.
echo ========================================
echo   诊断失败
echo ========================================
echo.
echo 请检查：
echo 1. ADB 是否在系统 PATH 中
echo 2. 模拟器是否正在运行
echo 3. ADB 连接是否正常
echo.
pause
exit /b 1