@echo off
chcp 65001 >nul
echo 正在编译 APK...

# 设置变量
set PROJECT_DIR=%~dp0..
set APKTOOL=C:\Users\a1\tools\apktool_3.0.3.jar
set SOURCE_DIR=%PROJECT_DIR%\launcher_data
set OUTPUT_DIR=%PROJECT_DIR%\release

# 检查源码目录
if not exist "%SOURCE_DIR%" (
    echo [错误] 源码目录不存在：%SOURCE_DIR%
    pause
    exit /b 1
)

# 检查 Apktool
if not exist "%APKTOOL%" (
    echo [错误] Apktool 不存在：%APKTOOL%
    pause
    exit /b 1
)

# 创建输出目录
if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
)

# 编译 APK
echo 开始编译...
java -jar "%APKTOOL%" b "%SOURCE_DIR%" -o "%OUTPUT_DIR%\LDLauncher-Clean-1.0.apk"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [OK] 编译成功！
    echo APK 位置：%OUTPUT_DIR%\LDLauncher-Clean-1.0.apk
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [错误] 编译失败！
    echo 请检查修改的文件是否有语法错误
    echo ========================================
    pause
    exit /b 1
)

pause