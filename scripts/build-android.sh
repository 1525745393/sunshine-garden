#!/usr/bin/env bash
# ============================================================
# Android Release 构建脚本（sunshine-garden 版）
# 由 semantic-release 的 publishCmd 调用：
#   1. 构建 split-per-abi 的签名 APK（多 ABI 产物，便于 GitHub Release 上传）
#   2. 构建签名 AAB（Google Play 上传用）
# 签名密钥来自 GitHub Actions Secrets（android/app/build.gradle 读取环境变量）
# ============================================================
set -euo pipefail

# 切到项目根目录（本脚本位于 scripts/ 下）
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 开始构建 Android Release 产物..."
flutter pub get

echo "📦 构建 APK（split-per-abi）..."
flutter build apk --release --split-per-abi

echo "📦 构建 APK（universal，供 GitHub Release 通用安装包）..."
flutter build apk --release

echo "📦 构建 AAB（App Bundle）..."
flutter build appbundle --release

echo "✅ 构建完成，产物列表："
echo ""
echo "=== APK 产物 ==="
ls -la build/app/outputs/flutter-apk/
echo ""
echo "=== AAB 产物 ==="
ls -la build/app/outputs/bundle/release/
