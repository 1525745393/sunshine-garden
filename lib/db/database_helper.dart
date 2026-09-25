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
  static const _dbVersion = 3;
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
            filter_current_stage INTEGER DEFAULT 0
          )
        ''');
        // 关卡进度
        await db.execute('''
          CREATE TABLE levels (
            id TEXT PRIMARY KEY,
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

  // ---------- 关卡 ----------
  Future<void> upsertLevel(Level level) async {
    final db = await database;
    await db.insert(
      'levels',
      level.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Level>> getLevels() async {
    final db = await database;
    final rows = await db.query('levels');
    return {for (final r in rows) r['id'] as String: Level.fromMap(r)};
  }

  // ---------- 今日任务 ----------
  Future<void> replaceTasksForDay(String dayKey, List<Task> tasks) async {
    final db = await database;
    await db.delete('tasks', where: 'day_key = ?', whereArgs: [dayKey]);
    final batch = db.batch();
    for (final t in tasks) {
      batch.insert('tasks', {...t.toMap(), 'day_key': dayKey});
    }
    await batch.commit(noResult: true);
  }

  Future<List<Task>> getTasksForDay(String dayKey) async {
    final db = await database;
    final rows = await db.query('tasks',
        where: 'day_key = ?', whereArgs: [dayKey], orderBy: 'rowid');
    return rows.map(Task.fromMap).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  // ---------- 错题 ----------
  Future<void> upsertMistake(Mistake mistake) async {
    final db = await database;
    await db.insert(
      'mistakes',
      mistake.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Mistake>> getMistakes({bool? resolved}) async {
    final db = await database;
    final rows = await db.query(
      'mistakes',
      where: resolved == null ? null : 'resolved = ?',
      whereArgs: resolved == null ? null : [resolved ? 1 : 0],
      orderBy: 'added_at DESC',
    );
    return rows.map(Mistake.fromMap).toList();
  }

  Future<void> deleteMistake(String id) async {
    final db = await database;
    await db.delete('mistakes', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- 学习记录 ----------
  Future<void> insertRecord(StudyRecord record) async {
    final db = await database;
    await db.insert('records', record.toMap());
  }

  Future<List<StudyRecord>> getRecords({int? limit}) async {
    final db = await database;
    final rows = await db.query(
      'records',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(StudyRecord.fromMap).toList();
  }

  // ---------- 花园地块 ----------
  Future<void> upsertGardenPlot(GardenPlot plot) async {
    final db = await database;
    await db.insert(
      'garden_plots',
      plot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GardenPlot>> getGardenPlots() async {
    final db = await database;
    final rows = await db.query('garden_plots', orderBy: 'rowid');
    return rows.map(GardenPlot.fromMap).toList();
  }

  Future<void> setGardenPlotUnlocked(String id, {required bool unlocked}) async {
    final db = await database;
    await db.update(
      'garden_plots',
      {'unlocked': unlocked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- 商城 ----------
  Future<void> upsertReward(RewardItem item) async {
    final db = await database;
    await db.insert(
      'rewards',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RewardItem>> getRewards() async {
    final db = await database;
    final rows = await db.query('rewards', orderBy: 'price');
    return rows.map(RewardItem.fromMap).toList();
  }

  Future<void> insertRedemption(RedemptionRecord record) async {
    final db = await database;
    await db.insert('redemptions', record.toMap());
  }

  Future<List<RedemptionRecord>> getRedemptions() async {
    final db = await database;
    final rows = await db.query('redemptions', orderBy: 'redeemed_at DESC');
    return rows.map(RedemptionRecord.fromMap).toList();
  }

  /// 更新兑换记录审批状态（v1.3 奖励审批：pending → approved / rejected）
  Future<void> updateRedemptionStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'redemptions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- 勋章 ----------
  Future<void> upsertBadge({
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
        'id': id,
        'name': name,
        'icon': icon,
        'condition': condition,
        'unlocked': unlocked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, bool>> getBadgeStatus() async {
    final db = await database;
    final rows = await db.query('badges');
    return {
      for (final r in rows)
        r['id'] as String: (r['unlocked'] as num?)?.toInt() == 1,
    };
  }

  Future<void> setBadgeUnlocked(String id, {required bool unlocked}) async {
    final db = await database;
    await db.update(
      'badges',
      {'unlocked': unlocked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
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
