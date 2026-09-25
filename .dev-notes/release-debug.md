# 发版链路排障记录（2026-09-25）

## 已确证事实
- android-release.yml 在 push main 时跑 npx semantic-release（verify/prepare/publish 三段）
- v1.0.0 / v1.0.1 / v1.0.2 tag 已生成，pubspec 已升至 1.0.2+10，CHANGELOG 含 1.0.1/1.0.2
  → verify + prepare（含 git 提交/tag）全部成功
- GitHub Release 从未创建（releases 页为空）→ publish 阶段（exec build-android.sh + github 上传）失败
- 本机用 CI 同款环境（Flutter 3.44.8 + JDK17 + SDK36 + NDK28.2）复现并修复 4 处代码问题：
  1) Gradle 8.3 → 8.10.2（Flutter 最低 8.7）
  2) AGP 8.1 → 8.6.0（Flutter 最低 8.6）
  3) build.gradle: `String.bytes.decodeBase64()` → `decodeBase64()`（byte[] 无此方法）
  4) build.gradle: `File.write(byte[])` → `keystoreFile.bytes = keystoreBytes`
  5) build-android.sh 补充 universal `flutter build apk --release`（匹配 .releaserc assets 的 app-release.apk）
- 本机完整构建 exit 0，5 产物齐全（3 ABI APK + universal APK + AAB）
- CI runner 预装 platform-36/build-tools-36/NDK-28.2（Ubuntu2404 readme 确认）

## 未解决
- Run 9 (36153014763) / Run 10 (36155051703) 均在 publish 早期失败（2m36s / 2m57s，exit 1）
- 日志被 GitHub 登录墙挡住，未拿到真实报错
- 时长差 ~20s 与 Gradle -all→-bin 下载体积差吻合 → 高度疑似 CI 冷启动 Gradle 发行包下载/依赖下载失败
- 候选修复：workflow 增加 Gradle 预热步骤（./gradlew help 或 flutter build debug）将下载排除出 publish 窗口

## 关键 ID
- 远程 main HEAD 曾含 aa3e73e（工具链修复）、2d5918b（-bin+timeout）
- 本地构建环境：~/flutter3448、~/jdk17、~/androidsdk（含 NDK 28.2）
- 签名凭据：workspace/keystore.b64 + creds.txt（STORE_PWD/KEY_PWD/KEY_ALIAS）

## 最终根因（2026-09-25 16:00 确认）
- Run 9/10 真实日志（PAT 拉取）显示：
  `android/app/build.gradle line 34 > build/sunshine-release.jks (No such file or directory)`
- 根因：签名代码把 keystore 写到 `${rootProject.buildDir}`（android/build/），
  Gradle 配置期该目录在 CI 全新工作区不存在 → File.bytes 写入静默失败 → storeFile 找不到文件
- 本机通过是因为跑过构建、build/ 已存在（假阳性）
- 修复：`keystoreFile.parentFile.mkdirs()` 后再写入
- 验证：删除 build/ 模拟 CI 全新环境 → 构建 exit 0，5 产物齐全

## 最终结果
- 推送 c7d8478（fix: mkdirs）→ Run 11 成功
- Release v1.0.3 已创建（github-actions，Latest，7 assets：4 APK + 1 AAB + 2 源码包）
- badge：release passing / ci passing 双绿
- 注意：v1.0.1/v1.0.2 tag 因 Run 9/10 prepare 成功已存在但无 Release；v1.0.3 为实际首个 Release
