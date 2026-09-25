# 阳光花园・学习乐园（Sunshine Garden）

面向 K-12 儿童（幼儿园至初中）的游戏化学习激励移动应用。孩子完成学习任务、玩"知识闯关"获得阳光积分，用积分兑换奖励、解锁勋章、装饰花园。

> 当前仓库为 **MVP v1.1**：在 v1.0 学习闭环基础上，落地"阳光花园 / 阳光商城 / 我的奖励"三大激励页面。详见 [PRD](https://my.feishu.cn/docx/O5Radjz71o8MWtxZdOUcVdfQnTe)。

## 功能范围（v1.1）

- 首次启动：隐私告知弹窗（家长同意）→ 学段/年级选择
- 学习总览（首页）：Hero 卡 + 积分进度环 + 今日任务摘要 + 闯关入口
- 今日任务：任务勾选、积分发放、完成进度
- 知识闯关：关卡选择 → 逐题作答 → 即时反馈与解析 → 星级结算 → 错题入库
- 阳光花园：地块网格，已解锁展示植物，锁定地块消费积分解锁（v1.1）
- 阳光商城：奖励商品三档（贴纸/花园装饰/家长兑现），积分足够扣分兑换、不足禁用（v1.1）
- 我的奖励：勋章墙（按闯关进度自动解锁）+ 兑换记录列表（v1.1）
- 学习记录：按日期的闯关/任务/兑换/积分时间线
- 家长中心：算术验证进入、修改学段/年级/每日时长、一键清除本地数据

## 技术栈

| 项 | 选型 |
|---|---|
| 框架 | Flutter 3.x（iOS + Android） |
| 设计体系 | Material 3 |
| 状态管理 | Provider（全局）+ setState（局部） |
| 本地存储 | shared_preferences（配置）+ sqflite（结构化数据） |
| 图标 | Material Icons + emoji |

## 快速开始

> 开发环境需安装 Flutter 3.x SDK。仓库已包含 **android/ 与 ios/ 原生工程骨架**（Gradle 配置、Xcode 工程、启动图标 XML 等均为文本文件，可版本管理）；个别二进制生成物（Gradle wrapper jar、iOS AppIcon PNG）由 `flutter create` 补全，不会覆盖已有配置。

```bash
# 1. 进入工程
cd sunshine-garden

# 2. 补全原生生成物（gradle wrapper jar、iOS 图标占位等；不会覆盖已有 android/ ios/ 配置与 lib/）
flutter create --org com.sunshine --project-name sunshine_garden .

# 3. 安装依赖
flutter pub get

# 4. 运行
flutter run
```

> 说明：
> - Android 启动图标为**自适应矢量图标**（`mipmap-anydpi-v26` + VectorDrawable，纯 XML），要求 `minSdk >= 26`（Android 8.0+，已写入 `app/build.gradle`）。
> - iOS 应用显示名「阳光花园・学习乐园」已写入 `Info.plist`（`CFBundleDisplayName`）；AppIcon 暂为空集，`flutter create` 会生成 Flutter 默认图标，正式发布前需替换为品牌图标（PRD 品牌视觉：#B791FA 底 + 白色阳光）。
> - 本机无 Flutter SDK 的 CI 环境无法直接构建；请在有 Flutter SDK 的机器执行上述步骤。

## 目录结构

```
lib/
├── main.dart                 # 应用入口（Provider 装配 + 路由）
├── theme/app_theme.dart      # 品牌主题（色值统一管理）
├── models/                   # 数据模型（含 GardenPlot / Reward / Badge）
├── providers/                # Provider 状态管理（用户/任务/闯关/花园/商城）
├── db/database_helper.dart   # sqflite 数据库帮助类（含 garden_plots 表）
├── mock/                     # Mock 数据（题库/任务/奖励/勋章/花园）
├── pages/                    # 页面层（按功能分包）
└── widgets/                  # 通用组件（TaskItem / PlotTile / RewardCard / BadgeItem 等）
```

## 数据与合规

- 无广告、无外链、无社交、无第三方 SDK 采集
- 所有儿童数据仅本地存储（sqflite + shared_preferences），不上传服务器
- 家长中心提供"一键清除本地全部数据"
- 计时口径：仅统计 APP 前台活跃时长，后台暂停（时间戳差值计算并持久化）
