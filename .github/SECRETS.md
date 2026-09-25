# GitHub Secrets 配置指南

本文档介绍如何为 sunshine-garden（阳光花园・学习乐园）项目配置 GitHub Actions 所需的 Secrets，以便自动化构建与发布。

## 概述

sunshine-garden 为纯 Flutter 移动应用（iOS + Android），自动化发布仅涉及 **Android Release** 流程：

| 工作流 | 触发条件 | 产物 |
|--------|---------|------|
| **Android Release** | push 到 main 或手动触发 | 签名 APK / AAB |

该流程需要预先在 GitHub 仓库中配置以下 Secrets。

## Secrets 完整清单

| Secret 名称 | 是否必需 | 用途 | 格式要求 | 示例 |
|------------|---------|------|---------|------|
| `ANDROID_KEYSTORE` | **必需** | Android 签名 keystore 文件 | Base64 编码字符串，**必须无换行**，长度 > 1000 | `MIIiXDI...`（数千字符） |
| `ANDROID_KEYSTORE_PWD` | **必需** | keystore 密码 | 普通字符串 | `YourStorePass123!` |
| `ANDROID_KEY_ALIAS` | **必需** | key 别名 | 普通字符串（与 keystore 生成时一致） | `sunshine` |
| `ANDROID_KEY_PWD` | **必需** | key 密码 | 普通字符串 | `YourKeyPass456!` |

## 第一部分：Android 签名配置

### 1.1 生成 keystore 文件

在本地终端执行（需要安装 JDK）：

```bash
# 进入 Android 目录
cd android

# 生成 keystore（有效期为 100 年，请妥善保管）
keytool -genkeypair \
  -alias sunshine \
  -keyalg RSA \
  -keysize 2048 \
  -validity 36500 \
  -keystore sunshine-keystore.jks \
  -storepass "YourStorePass123!" \
  -keypass "YourKeyPass456!" \
  -dname "CN=SunshineGarden, OU=SunshineGarden, O=SunshineGarden, L=Beijing, ST=Beijing, C=CN"
```

> ⚠️ **重要**：请将 `YourStorePass123!` 和 `YourKeyPass456!` 替换为您的安全密码，并妥善保管！

### 1.2 导出为 base64

**Linux / macOS：**

```bash
cd android

# 导出为 base64（无换行）
base64 -w 0 sunshine-keystore.jks > keystore-base64.txt

# 查看内容（复制全部内容，包括换行前的所有字符）
cat keystore-base64.txt
```

**Windows PowerShell：**

```powershell
cd .\android\

# 导出为 base64
$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("sunshine-keystore.jks"))

# 写入文件（无换行）
$base64 | Out-File -Encoding ASCII keystore-base64.txt

# 查看内容
Get-Content keystore-base64.txt
```

### 1.3 备份与安全提示

> ⚠️ **务必离线备份！**
>
> - 将 `sunshine-keystore.jks` 文件加密压缩后存入密码管理器或安全云盘
> - 丢失 keystore 将导致**无法更新已上架的应用**
> - 泄露密码将导致签名被滥用

## 第二部分：添加到 GitHub

### 2.1 操作步骤

1. 进入仓库页面：https://github.com/1525745393/sunshine-garden
2. 点击 **Settings**（设置）
3. 左侧菜单选择 **Secrets and variables** → **Actions**
4. 点击 **New repository secret**
5. 填写信息：
   - **Name**: Secret 名称（如 `ANDROID_KEYSTORE`）
   - **Secret**: Secret 值（从 keystore-base64.txt 复制）
6. 点击 **Add secret**
7. 重复以上步骤，添加所有必需的 Secrets（共 4 个）

### 2.2 验证配置

配置完成后，运行 **Secrets 配置检查** 工作流：

1. 进入仓库 **Actions** 页面
2. 选择左侧 **Secrets 配置检查** 工作流
3. 点击 **Run workflow** → **Run workflow**
4. 等待执行完成，查看 **Summary** 页面中的检查结果表格

## 常见问题（FAQ）

### Q1: base64 编码后有多行换行？

**问题**：复制 base64 内容时可能包含换行，导致 GitHub 无法正确解码。

**解决**：确保 base64 编码时使用 `-w 0` 参数（Linux/macOS）或 `Out-File -Encoding ASCII`（PowerShell），生成**无换行的单行字符串**。

### Q2: Android keystore 密码包含特殊字符（如 `!`、`@`）？

**问题**：特殊字符在 shell 中可能需要转义。

**解决**：在 keytool 命令中使用单引号包裹密码。GitHub Secrets 支持任意字符，无需额外转义。

### Q3: 忘记了 key alias？

**问题**：keystore 生成时使用了不同的 alias。

**解决**：使用以下命令列出 keystore 中的所有 alias：

```bash
keytool -list -v -keystore sunshine-keystore.jks -storepass YOUR_STORE_PASS
```

在输出中查找 `Alias name:` 行。

### Q4: keystore 文件丢失？

**问题**：本地 keystore 被删除。

**解决**：
1. 如果有离线备份，从备份恢复
2. 如果无备份，只能**重新生成 keystore** 并重新签名（用户需要重新安装应用）

### Q5: 推送代码后没有触发 Release 工作流？

**解决**：
1. 确认是 push 到 `main` 分支（或手动触发 workflow_dispatch）
2. 确认提交信息符合 Conventional Commits 规范（如 `feat:` / `fix:`），否则 semantic-release 不会发版
3. 检查 Actions 页面是否有错误日志

## 参考链接

- [GitHub Actions 文档](https://docs.github.com/actions)
- [keytool 官方文档](https://docs.oracle.com/en/java/javase/17/docs/specs/man/keytool.html)
- [Android 签名配置](https://developer.android.com/studio/publish/app-signing)
