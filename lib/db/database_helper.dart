import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/garden_plot.dart';
import '../models/level.dart';
import '../models/mistake.dart';
import '../models/reward.dart';
import '../models/study_record.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

/// sqflite 数据库帮助类（结构化数据本地持久化）
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'sunshine_garden.db';
  static const _dbVersion = 5; // v1.5 多孩子档案：业务表按 user_id 隔离
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // 用户档案（单孩子，v1.0）
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            nickname TEXT,
            stage TEXT,
            grade TEXT,
            total_score INTEGER DEFAULT 0,
            continuous_days INTEGER DEFAULT 0,
            last_active_date TEXT,
            last_active_day_key TEXT,
            daily_minutes INTEGER,
            sound_enabled INTEGER DEFAULT 1,
            animation_enabled INTEGER DEFAULT 1,
            dark_mode INTEGER DEFAULT 0,
            daily_target_score INTEGER DEFAULT 0,
            filter_current_stage INTEGER DEFAULT 0,
            daily_score_limit INTEGER DEFAULT 0,
            pomodoro_enabled INTEGER DEFAULT 1,
            focus_minutes INTEGER DEFAULT 15,
            break_minutes INTEGER DEFAULT 3,
            allowed_start_hour INTEGER DEFAULT 0,
            allowed_end_hour INTEGER DEFAULT 24
          )
        ''');
        // 关卡进度
        await db.execute('''
          CREATE TABLE levels (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            stage TEXT,
            subject TEXT,
            unit TEXT,
            name TEXT,
            star_count INTEGER DEFAULT 0,
            unlocked INTEGER DEFAULT 0
          )
        ''');
        // 今日任务（按 day_key 区分，跨日重建）
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            day_key TEXT,
            title TEXT,
            icon TEXT,
            score INTEGER DEFAULT 0,
            completed INTEGER DEFAULT 0
          )
        ''');
        // 错题本
        await db.execute('''
          CREATE TABLE mistakes (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            question_text TEXT,
            user_answer TEXT,
            correct_answer TEXT,
            analysis TEXT,
            added_at TEXT,
            next_review_at TEXT,
            resolved INTEGER DEFAULT 0
          )
        ''');
        // 学习记录
        await db.execute('''
          CREATE TABLE records (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            day_key TEXT,
            created_at TEXT,
            type TEXT,
            title TEXT,
            detail TEXT,
            score_change INTEGER DEFAULT 0
          )
        ''');
        // 商城商品兑换状态（v1.3：custom 标记家长自定义奖励）
        await db.execute('''
          CREATE TABLE rewards (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            name TEXT,
            icon TEXT,
            price INTEGER,
            tier TEXT,
            redeemed INTEGER DEFAULT 0,
            custom INTEGER DEFAULT 0
          )
        ''');
        // 兑换记录（v1.3：status = pending/approved/rejected，大奖励需家长审批）
        await db.execute('''
          CREATE TABLE redemptions (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            reward_name TEXT,
            reward_icon TEXT,
            cost INTEGER,
            redeemed_at TEXT,
            status TEXT DEFAULT 'approved',
            tier TEXT DEFAULT 'small'
          )
        ''');
        // 勋章状态
        await db.execute('''
          CREATE TABLE badges (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            name TEXT,
            icon TEXT,
            condition TEXT,
            unlocked INTEGER DEFAULT 0
          )
        ''');
        // 花园地块解锁状态（v1.1）
        await db.execute('''
          CREATE TABLE garden_plots (
            id TEXT PRIMARY KEY,
            user_id TEXT DEFAULT '',
            name TEXT,
            icon TEXT,
            description TEXT,
            price INTEGER DEFAULT 0,
            unlocked INTEGER DEFAULT 0
          )
        ''');
      },
      // 老版本升级：v1.0 已有库 → 补齐 v1.1 新增表；v1.3 追加审批/自定义奖励/家长设置列
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS garden_plots (
              id TEXT PRIMARY KEY,
              name TEXT,
              icon TEXT,
              description TEXT,
              price INTEGER DEFAULT 0,
              unlocked INTEGER DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
              "ALTER TABLE redemptions ADD COLUMN status TEXT DEFAULT 'approved'");
          await db.execute(
              "ALTER TABLE redemptions ADD COLUMN tier TEXT DEFAULT 'small'");
          await db.execute(
              'ALTER TABLE rewards ADD COLUMN custom INTEGER DEFAULT 0');
          await db.execute(
              'ALTER TABLE users ADD COLUMN daily_target_score INTEGER DEFAULT 0');
          await db.execute(
              'ALTER TABLE users ADD COLUMN filter_current_stage INTEGER DEFAULT 0');
        }
        if (oldVersion < 4) {
          // v1.4：每日积分上限 + 番茄钟配置 + 允许时间段
          await db.execute(
              'ALTER TABLE users ADD COLUMN daily_score_limit INTEGER DEFAULT 0');
          await db.execute(
              'ALTER TABLE users ADD COLUMN pomodoro_enabled INTEGER DEFAULT 1');
          await db.execute(
              'ALTER TABLE users ADD COLUMN focus_minutes INTEGER DEFAULT 15');
          await db.execute(
              'ALTER TABLE users ADD COLUMN break_minutes INTEGER DEFAULT 3');
          await db.execute(
              'ALTER TABLE users ADD COLUMN allowed_start_hour INTEGER DEFAULT 0');
          await db.execute(
              'ALTER TABLE users ADD COLUMN allowed_end_hour INTEGER DEFAULT 24');
        }
        if (oldVersion < 5) {
          // v1.5 多孩子档案：全部业务表按 user_id 隔离（旧数据归入默认档案）
          for (final t in const [
            'levels', 'tasks', 'mistakes', 'records',
            'rewards', 'redemptions', 'badges', 'garden_plots',
          ]) {
            await db.execute(
                "ALTER TABLE $t ADD COLUMN user_id TEXT DEFAULT ''");
          }
        }
      },
    );
  }

  // ---------- 用户 ----------
  Future<void> upsertUser(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'users',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUser(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  /// 全部档案（v1.5 多孩子）
  Future<List<UserProfile>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'rowid');
    return rows.map(UserProfile.fromMap).toList();
  }

  /// 删除档案及其全部学习数据（v1.5）
  Future<void> deleteUserAndData(String userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    for (final t in const [
      'levels', 'tasks', 'mistakes', 'records',
      'rewards', 'redemptions', 'badges', 'garden_plots',
    ]) {
      await db.delete(t, where: 'user_id = ?', whereArgs: [userId]);
    }
  }

  // ---------- 多档案 id 前缀（业务行 id 存为 "user:orig"，避免主键冲突） ----------
  static String pid(String userId, String id) => '$userId:$id';
  static String unpid(String userId, String id) =>
      id.startsWith('$userId:') ? id.substring(userId.length + 1) : id;

  // ---------- 关卡 ----------
  Future<void> upsertLevel(String userId, Level level) async {
    final db = await database;
    await db.insert(
      'levels',
      {...level.toMap(), 'id': pid(userId, level.id), 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Level>> getLevels(String userId) async {
    final db = await database;
    final rows = await db.query('levels',
        where: 'user_id = ?', whereArgs: [userId]);
    return {
      for (final r in rows)
        unpid(userId, r['id'] as String): Level.fromMap({...r, 'id': unpid(userId, r['id'] as String)}),
    };
  }

  // ---------- 今日任务 ----------
  Future<void> replaceTasksForDay(
      String userId, String dayKey, List<Task> tasks) async {
    final db = await database;
    await db.delete('tasks',
        where: 'user_id = ? AND day_key = ?', whereArgs: [userId, dayKey]);
    final batch = db.batch();
    for (final t in tasks) {
      batch.insert('tasks', {
        ...t.toMap(),
        'id': pid(userId, t.id),
        'day_key': dayKey,
        'user_id': userId,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Task>> getTasksForDay(String userId, String dayKey) async {
    final db = await database;
    final rows = await db.query('tasks',
        where: 'user_id = ? AND day_key = ?',
        whereArgs: [userId, dayKey],
        orderBy: 'rowid');
    return rows.map((r) => Task.fromMap(
        {...r, 'id': unpid(userId, r['id'] as String)})).toList();
  }

  Future<void> updateTask(String userId, Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(),
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, pid(userId, task.id)]);
  }

  // ---------- 错题 ----------
  Future<void> upsertMistake(String userId, Mistake mistake) async {
    final db = await database;
    await db.insert(
      'mistakes',
      {...mistake.toMap(), 'id': pid(userId, mistake.id), 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Mistake>> getMistakes(String userId, {bool? resolved}) async {
    final db = await database;
    final rows = await db.query(
      'mistakes',
      where: resolved == null
          ? 'user_id = ?'
          : 'user_id = ? AND resolved = ?',
      whereArgs: resolved == null
          ? [userId]
          : [userId, resolved ? 1 : 0],
      orderBy: 'added_at DESC',
    );
    return rows.map((r) => Mistake.fromMap(
        {...r, 'id': unpid(userId, r['id'] as String)})).toList();
  }

  Future<void> deleteMistake(String userId, String id) async {
    final db = await database;
    await db.delete('mistakes',
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, pid(userId, id)]);
  }

  // ---------- 学习记录 ----------
  Future<void> insertRecord(String userId, StudyRecord record) async {
    final db = await database;
    await db.insert(
      'records',
      {...record.toMap(), 'user_id': userId},
    );
  }

  Future<List<StudyRecord>> getRecords(String userId, {int? limit}) async {
    final db = await database;
    final rows = await db.query(
      'records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(StudyRecord.fromMap).toList();
  }

  // ---------- 花园地块 ----------
  Future<void> upsertGardenPlot(String userId, GardenPlot plot) async {
    final db = await database;
    await db.insert(
      'garden_plots',
      {...plot.toMap(), 'id': pid(userId, plot.id), 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GardenPlot>> getGardenPlots(String userId) async {
    final db = await database;
    final rows = await db.query('garden_plots',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'rowid');
    return rows.map((r) => GardenPlot.fromMap(
        {...r, 'id': unpid(userId, r['id'] as String)})).toList();
  }

  Future<void> setGardenPlotUnlocked(String userId, String id,
      {required bool unlocked}) async {
    final db = await database;
    await db.update(
      'garden_plots',
      {'unlocked': unlocked ? 1 : 0},
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, pid(userId, id)],
    );
  }

  // ---------- 商城 ----------
  Future<void> upsertReward(String userId, RewardItem item) async {
    final db = await database;
    await db.insert(
      'rewards',
      {...item.toMap(), 'id': pid(userId, item.id), 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RewardItem>> getRewards(String userId) async {
    final db = await database;
    final rows = await db.query('rewards',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'price');
    return rows.map((r) => RewardItem.fromMap(
        {...r, 'id': unpid(userId, r['id'] as String)})).toList();
  }

  Future<void> insertRedemption(String userId, RedemptionRecord record) async {
    final db = await database;
    await db.insert(
      'redemptions',
      {...record.toMap(), 'user_id': userId},
    );
  }

  Future<List<RedemptionRecord>> getRedemptions(String userId) async {
    final db = await database;
    final rows = await db.query('redemptions',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'redeemed_at DESC');
    return rows.map(RedemptionRecord.fromMap).toList();
  }

  /// 更新兑换记录审批状态（v1.3 奖励审批：pending → approved / rejected）
  Future<void> updateRedemptionStatus(String userId, String id, String status) async {
    final db = await database;
    await db.update(
      'redemptions',
      {'status': status},
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, pid(userId, id)],
    );
  }

  // ---------- 勋章 ----------
  Future<void> upsertBadge({
    required String userId,
    required String id,
    required String name,
    required String icon,
    required String condition,
    bool unlocked = false,
  }) async {
    final db = await database;
    await db.insert(
      'badges',
      {
        'id': pid(userId, id),
        'user_id': userId,
        'name': name,
        'icon': icon,
        'condition': condition,
        'unlocked': unlocked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, bool>> getBadgeStatus(String userId) async {
    final db = await database;
    final rows = await db.query('badges',
        where: 'user_id = ?', whereArgs: [userId]);
    return {
      for (final r in rows)
        unpid(userId, r['id'] as String): (r['unlocked'] as num?)?.toInt() == 1,
    };
  }

  Future<void> setBadgeUnlocked(String userId, String id,
      {required bool unlocked}) async {
    final db = await database;
    await db.update(
      'badges',
      {'unlocked': unlocked ? 1 : 0},
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, pid(userId, id)],
    );
  }

  // ---------- 数据重置 ----------
  /// 一键清除本地全部数据（家长中心）
  Future<void> wipeAll() async {
    final db = await database;
    for (final table in [
      'users',
      'levels',
      'tasks',
      'mistakes',
      'records',
      'rewards',
      'redemptions',
      'badges',
      'garden_plots',
    ]) {
      await db.delete(table);
    }
  }
}
