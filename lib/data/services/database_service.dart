import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/member.dart';
import '../../domain/entities/membership_plan.dart';
import '../../domain/entities/check_in.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'gym_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE membership_plans (
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        durationDays INTEGER,
        description TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        phone TEXT,
        membershipPlanId TEXT,
        joinDate INTEGER,
        expiryDate INTEGER,
        isActive INTEGER,
        FOREIGN KEY (membershipPlanId) REFERENCES membership_plans(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE check_ins (
        id TEXT PRIMARY KEY,
        memberId TEXT,
        checkInTime INTEGER,
        checkOutTime INTEGER,
        FOREIGN KEY (memberId) REFERENCES members(id)
      );
    ''');

    await db.execute(
      'CREATE INDEX idx_checkins_memberId ON check_ins(memberId);',
    );
    await db.execute('CREATE INDEX idx_members_joinDate ON members(joinDate);');
  }

  // Membership plan CRUD
  Future<void> insertOrUpdatePlan(MembershipPlan plan) async {
    final database = await db;
    await database.insert(
      'membership_plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MembershipPlan>> getAllPlans() async {
    final database = await db;
    final maps = await database.query('membership_plans');
    return maps.map((m) => MembershipPlan.fromMap(m)).toList();
  }

  // Member CRUD
  Future<void> insertOrUpdateMember(Member member) async {
    final database = await db;
    await database.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMember(String id) async {
    final database = await db;
    await database.delete('members', where: 'id = ?', whereArgs: [id]);
    await database.delete('check_ins', where: 'memberId = ?', whereArgs: [id]);
  }

  Future<void> deletePlan(String id) async {
    final database = await db;
    await database.delete('membership_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<Member?> getMemberById(String id) async {
    final database = await db;
    final maps = await database.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Member.fromMap(maps.first);
  }

  Future<List<Member>> fetchMembersPaginated({
    required int offset,
    required int limit,
  }) async {
    final database = await db;
    final maps = await database.query(
      'members',
      orderBy: 'joinDate DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Member.fromMap(m)).toList();
  }

  Future<int> countMembers() async {
    final database = await db;
    final res = await database.rawQuery('SELECT COUNT(*) as c FROM members');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // Check-in CRUD
  Future<void> insertCheckIn(CheckIn ci) async {
    final database = await db;
    await database.insert(
      'check_ins',
      ci.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CheckIn>> getActiveCheckIns() async {
    final database = await db;
    final maps = await database.query(
      'check_ins',
      where: 'checkOutTime IS NULL',
    );
    return maps.map((m) => CheckIn.fromMap(m)).toList();
  }

  Future<void> updateCheckIn(CheckIn ci) async {
    final database = await db;
    await database.update(
      'check_ins',
      ci.toMap(),
      where: 'id = ?',
      whereArgs: [ci.id],
    );
  }

  // Bulk upsert helpers
  Future<void> bulkUpsertMembers(List<Member> members) async {
    final database = await db;
    await database.transaction((txn) async {
      final batch = txn.batch();
      for (final m in members) {
        batch.insert(
          'members',
          m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> bulkUpsertPlans(List<MembershipPlan> plans) async {
    final database = await db;
    await database.transaction((txn) async {
      final batch = txn.batch();
      for (final p in plans) {
        batch.insert(
          'membership_plans',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> bulkUpsertCheckIns(List<CheckIn> checkIns) async {
    final database = await db;
    await database.transaction((txn) async {
      final batch = txn.batch();
      for (final ci in checkIns) {
        batch.insert(
          'check_ins',
          ci.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Migration helper: move data from SharedPreferences (JSON) into SQLite once
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('migrated_to_sqlite') ?? false;
    if (migrated) return;

    final database = await db;
    await database.transaction((txn) async {
      final membersStr = prefs.getString('members');
      if (membersStr != null) {
        final membersList = jsonDecode(membersStr) as List;
        for (final m in membersList) {
          final member = Member.fromJson(m as Map<String, dynamic>);
          await txn.insert(
            'members',
            member.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      final plansStr = prefs.getString('membershipPlans');
      if (plansStr != null) {
        final plansList = jsonDecode(plansStr) as List;
        for (final p in plansList) {
          final plan = MembershipPlan.fromJson(p as Map<String, dynamic>);
          await txn.insert(
            'membership_plans',
            plan.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      final checkInsStr = prefs.getString('checkIns');
      if (checkInsStr != null) {
        final checkInsList = jsonDecode(checkInsStr) as List;
        for (final ci in checkInsList) {
          final checkIn = CheckIn.fromJson(ci as Map<String, dynamic>);
          await txn.insert(
            'check_ins',
            checkIn.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    await prefs.setBool('migrated_to_sqlite', true);
  }

  Future<void> close() async {
    final database = await db;
    await database.close();
    _db = null;
  }
}
