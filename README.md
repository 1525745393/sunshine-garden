# 阳光花园・学习乐园（Sunshine Garden）

面向 K-12 儿童（幼儿园至初中）的游戏化学习激励移动应用。孩子完成学习任务、玩"知识闯关"获得阳光积分，用积分兑换奖励、解锁勋章、装饰花园。

> 当前仓库为 **MVP v1.0**：聚焦小学低年级（1-2 年级）学段，实现"学习 → 拿积分"核心闭环。详见 [PRD](https://my.feishu.cn/docx/O5Radjz71o8MWtxZdOUcVdfQnTe)。

## 功能范围（v1.0）

- 首次启动：隐私告知弹窗（家长同意）→ 学段/年级选择
- 学习总览（首页）：Hero 卡 + 积分进度环 + 今日任务摘要 + 闯关入口
- 今日任务：任务勾选、积分发放、完成进度
- 知识闯关：关卡选择 → 逐题作答 → 即时反馈与解析 → 星级结算 → 错题入库
- 学习记录：按日期的闯关/任务/积分时间线
- 家长中心：算术验证进入、修改学段/年级/每日时长、一键清除本地数据
- 阳光花园 / 阳光商城 / 我的奖励：UI 占位壳（v1.1 实现）

## 技术栈

| 项 | 选型 |
|---|---|
| 框架 | Flutter 3.x（iOS + Android） |
| 设计体系 | Material 3 |
| 状态管理 | Provider（全局）+ setState（局部） |
| 本地存储 | shared_preferences（配置）+ sqflite（结构化数据） |
| 图标 | Material Icons + emoji |

## 快速开始

> 开发环境需安装 Flutter 3.x SDK（本仓库代码已在 Dart 3 语法下编写，未包含原生工程目录）。

```bash
# 1. 进入工程
cd sunshine-garden

# 2. 生成原生工程骨架（android/、ios/，不会覆盖已有 lib/）
flutter create --org com.sunshine --project-name sunshine_garden .

# 3. 安装依赖
flutter pub get

# 4. 运行
flutter run
```

## 目录结构

```
lib/
├── main.dart                 # 应用入口（Provider 装配 + 路由）
├── theme/app_theme.dart      # 品牌主题（色值统一管理）
├── models/                   # 数据模型
├── providers/                # Provider 状态管理（用户/任务/闯关）
├── db/database_helper.dart   # sqflite 数据库帮助类
├── mock/                     # Mock 数据（题库/任务/奖励/勋章）
├── pages/                    # 页面层（按功能分包）
└── widgets/                  # 通用组件
```

## 数据与合规

- 无广告、无外链、无社交、无第三方 SDK 采集
- 所有儿童数据仅本地存储（sqflite + shared_preferences），不上传服务器
- 家长中心提供"一键清除本地全部数据"
- 计时口径：仅统计 APP 前台活跃时长，后台暂停（时间戳差值计算并持久化）
