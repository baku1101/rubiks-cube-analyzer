@echo off
setlocal

REM プロジェクトのルートディレクトリに移動
cd /d %~dp0\..

REM 既存のプロセスを終了
taskkill /F /IM "chrome.exe" /T 2>nul

REM キャッシュをクリア
call flutter clean
call flutter pub get

REM Flutter Webアプリをビルド
call flutter build web --web-renderer canvaskit

REM Chrome起動オプションを設定
set "CHROME_FLAGS=--enable-experimental-web-platform-features"
set "CHROME_FLAGS=%CHROME_FLAGS% --enable-web-bluetooth"
set "CHROME_FLAGS=%CHROME_FLAGS% --enable-bluetooth-discovery-logging"
set "CHROME_FLAGS=%CHROME_FLAGS% --enable-logging=stderr"
set "CHROME_FLAGS=%CHROME_FLAGS% --v=1"
set "CHROME_FLAGS=%CHROME_FLAGS% --unsafely-treat-insecure-origin-as-secure=http://localhost:8090"
set "CHROME_FLAGS=%CHROME_FLAGS% --auto-open-devtools-for-tabs"
set "CHROME_FLAGS=%CHROME_FLAGS% --remote-debugging-port=9222"
set "CHROME_FLAGS=%CHROME_FLAGS% --enable-features=WebBluetooth,ExperimentalWebPlatformFeatures"
set "CHROME_FLAGS=%CHROME_FLAGS% --enable-blink-features=WebBluetooth,ExperimentalWebPlatformFeatures"
set "CHROME_FLAGS=%CHROME_FLAGS% --debug-devtools"
set "CHROME_FLAGS=%CHROME_FLAGS% --log-level=0"

REM HTTPSなしでローカルテスト用にChromeを起動
echo Launching Flutter Web App...
call flutter run -d chrome ^
    --dart-define=USE_ALTERNATIVE_BACKEND=true ^
    --web-hostname=localhost ^
    --web-port=8090 ^
    --dart-define=FLUTTER_WEB_DEBUG=true ^
    --dart-define=FLUTTER_WEB_AUTO_DETECT=true ^
    --web-browser-flag="%CHROME_FLAGS%"

if errorlevel 1 (
    echo Error: Failed to launch Flutter Web App
    exit /b 1
)

endlocal