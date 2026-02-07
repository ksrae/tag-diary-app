#!/bin/bash

# call_log 패키지의 namespace 문제 패치
# Flutter pub get 후에 실행하세요

CALL_LOG_PATH="$HOME/.pub-cache/hosted/pub.dev/call_log-4.0.0/android/build.gradle"

if [ -f "$CALL_LOG_PATH" ]; then
    echo "Patching call_log build.gradle..."
    
    # namespace가 이미 있는지 확인
    if grep -q "namespace" "$CALL_LOG_PATH"; then
        echo "Namespace already exists. Skipping patch."
        exit 0
    fi
    
    # AndroidManifest.xml에서 package 이름 추출
    MANIFEST_PATH="$HOME/.pub-cache/hosted/pub.dev/call_log-4.0.0/android/src/main/AndroidManifest.xml"
    PACKAGE_NAME=$(grep 'package=' "$MANIFEST_PATH" | sed 's/.*package="\([^"]*\)".*/\1/')
    
    # build.gradle에 namespace 추가
    # apply plugin 라인 다음에 namespace 추가
    sed -i.bak "/apply plugin: 'com.android.library'/a\\
\\
android {\\
    namespace '$PACKAGE_NAME'\\
}\\
" "$CALL_LOG_PATH"
    
    echo "✅ Patched successfully!"
    echo "Namespace: $PACKAGE_NAME"
else
    echo "❌ call_log package not found at $CALL_LOG_PATH"
    echo "Please run 'flutter pub get' first"
    exit 1
fi
