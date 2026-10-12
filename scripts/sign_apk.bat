@echo off
chcp 65001 >nul
echo 正在签名 APK...

# 设置变量
set PROJECT_DIR=%~dp0..
set JDK_PATH=C:\Users\a1\tools\jdk-17.0.20.1
set JARSIGNER=%JDK_PATH%\bin\jarsigner.exe
set KEYTOOL=%JDK_PATH%\bin\keytool.exe
set KEYSTORE=%PROJECT_DIR%\launcher.keystore
set KEY_ALIAS=launcher
set PASSWORD=android
set APK_PATH=%PROJECT_DIR%\release\LDLauncher-Clean-1.0.apk

# 检查 APK 文件
if not exist "%APK_PATH%" (
    echo [错误] APK 文件不存在：%APK_PATH%
    echo 请先运行 rebuild_apk.bat 编译 APK
    pause
    exit /b 1
)

# 检查 Jarsigner
if not exist "%JARSIGNER%" (
    echo [错误] Jarsigner 不存在：%JARSIGNER%
    pause
    exit /b 1
)

# 检查密钥库
if not exist "%KEYSTORE%" (
    echo [警告] 密钥库不存在，正在生成...
    echo 密钥别名：%KEY_ALIAS%
    echo 密钥密码：%PASSWORD%
    echo.
    
    %KEYTOOL% -genkey -v -keystore %KEYSTORE% -alias %KEY_ALIAS% -keyalg RSA -keysize 2048 -validity 10000
    
    if %errorlevel% equ 0 (
        echo [OK] 密钥库生成成功！
        echo.
        echo ========================================
        echo ⚠️  重要：备份密钥库！
        echo 密钥库文件：%KEYSTORE%
        echo 密码：%PASSWORD%
        echo ========================================
        pause
    ) else (
        echo [错误] 密钥库生成失败！
        pause
        exit /b 1
    )
)

# 签名 APK
echo.
echo 开始签名...
%JARSIGNER% -keystore %KEYSTORE% -storepass %PASSWORD% -keypass %PASSWORD% -sigalg SHA256withRSA %APK_PATH% %KEY_ALIAS%

if %errorlevel% equ 0 (
    echo [OK] 签名成功！
) else (
    echo [错误] 签名失败！
    pause
    exit /b 1
)

# 验证签名
echo.
echo 验证签名...
%JARSIGNER% -verify %APK_PATH%

if %errorlevel% equ 0 (
    echo [OK] 签名验证通过！
) else (
    echo [警告] 签名验证失败！
)

echo.
echo ========================================
echo [完成] APK 签名完成
echo 文件：%APK_PATH%
echo ========================================

pause