#!/bin/bash

# 証明書の生成（初回のみ）
if [ ! -f "cert/localhost.key" ]; then
    mkdir -p cert
    cd cert
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout localhost.key -out localhost.crt \
        -subj "/C=JP/ST=Tokyo/L=Tokyo/O=Development/CN=localhost"
    cd ..
fi

# FlutterのWebアプリをビルド
flutter build web

# HTTPSサーバーを起動（Chrome DevToolsのリモートデバッグを有効化）
flutter run -d chrome \
    --web-port=8443 \
    --web-renderer=html \
    --web-hostname=localhost \
    --dart-define=FLUTTER_WEB_USE_SKIA=true \
    --web-browser-flag="--enable-experimental-web-platform-features" \
    --web-browser-flag="--enable-web-bluetooth" \
    --web-browser-flag="--enable-bluetooth-discovery-logging" \
    --web-browser-flag="--enable-logging=stderr" \
    --web-browser-flag="--v=1"