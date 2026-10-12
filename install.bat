@echo off
chcp 65001 >nul
title LDLauncher-Clean 一键安装脚本
color 0A

echo.
echo ========================================
echo   LDLauncher-Clean 一键安装脚本
echo ========================================
echo.

REM 检查 ADB 是否存在
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 ADB 工具！
    echo 请确保雷电模拟器已安装，并将 adb 添加到系统 PATH
    echo 或将本脚本复制到模拟器安装目录的 adb 文件夹运行
    pause
    exit /b 1
)

REM 检查设备连接
echo [1/5] 检查模拟器连接...
adb devices | findstr /i "device" >nul
if %errorlevel% neq 0 (
    echo [错误] 未检测到模拟器！
    echo 请确保雷电模拟器 9 已启动并正在运行
    pause
    exit /b 1
)
echo [OK] 模拟器已连接

REM 获取项目目录
set PROJECT_DIR=%~dp0
set APK_PATH=%PROJECT_DIR%release\LDLauncher-Clean-1.0.apk

REM 检查 APK 文件是否存在
if not exist "%APK_PATH%" (
    echo [错误] 未找到 APK 文件！
    echo 路径：%APK_PATH%
    pause
    exit /b 1
)
echo [OK] APK 文件存在

REM 安装 APK
echo [2/5] 安装修改后的启动器...
adb install -r "%APK_PATH%"
if %errorlevel% neq 0 (
    echo [错误] 安装失败！
    pause
    exit /b 1
)
echo [OK] 安装成功

REM 清除应用数据（可选）
echo [3/5] 清除应用数据（确保干净启动）...
adb shell pm clear com.android.launcher3.mod >nul 2>nul
echo [OK] 数据已清除

REM 启动修改后的启动器
echo [4/5] 启动修改后的启动器...
adb shell am start -n com.android.launcher3.mod/com.android.launcher3.Launcher
if %errorlevel% neq 0 (
    echo [警告] 启动失败，但安装已成功
) else (
    echo [OK] 启动器已启动
)

REM 提示设置默认启动器
echo [5/5] 完成！
echo.
echo ========================================
echo   安装完成！
echo ========================================
echo.
echo 修改后的启动器已安装并启动。
echo.
echo 可选操作：
echo   1. 设置为默认启动器（开机自动使用）：
echo      adb shell pm set-home-activity com.android.launcher3.mod/com.android.launcher3.Launcher
echo.
echo   2. 禁用原版启动器：
echo      adb shell pm disable-user --user 0 com.android.launcher3
echo.
echo 注意：重启模拟器后可能需要重新设置默认启动器
echo.
echo ========================================

pause