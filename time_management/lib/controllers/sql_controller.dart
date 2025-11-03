import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/helpers/sql_helper.dart';

class SQLController extends GetxController {
  Database? _database;
  Database? _archiveDatabase;
  static const String dbName = "management_database.db";
  static const String archiveDb = "archive_database.db";
  RxInt isLoading = 0.obs;

  Future<void> init() async {
    isLoading.value = 1;

    var path = join(await getDatabasesPath(), dbName);
    var archive = join(await getDatabasesPath(), archiveDb);
    // await databaseFactory.deleteDatabase(path);
    // await databaseFactory.deleteDatabase(archive);
    final database =
        await openDatabase(path, version: 2, onConfigure: (Database db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }, onCreate: (db, version) {
      db.execute(SQLConstants.createGoalsTable);
      db.execute(SQLConstants.insertDefaultGoal);
      db.execute(SQLConstants.createTagsTable);
      db.execute(SQLConstants.createTaskTable);
      db.execute(SQLConstants.createDayPlanTable);
      db.execute(SQLConstants.createDocumentTable);
      db.execute(SQLConstants.createDocumentTaskTable);
      db.execute(SQLConstants.createRoutineTable);
      db.execute(SQLConstants.createChecklistTable);
      db.execute(SQLConstants.createSessionTable);
      db.execute(SQLConstants.createSessionTaskTable);
    }, onOpen: (db) async {
      db.execute(SQLConstants.createGoalsTable);
      db.execute(SQLConstants.createTagsTable);
      db.execute(SQLConstants.createTaskTable);
      db.execute(SQLConstants.createDayPlanTable);
      db.execute(SQLConstants.createDocumentTable);
      db.execute(SQLConstants.createDocumentTaskTable);
      db.execute(SQLConstants.createRoutineTable);
      db.execute(SQLConstants.createChecklistTable);
      db.execute(SQLConstants.createSessionTable);
      db.execute(SQLConstants.createSessionTaskTable);
    }, onUpgrade: (db, oldVersion, newVersion) {
      if (newVersion - 1 > SQLConstants.upgrades.length) {
        return;
      }
      for (int currIndex = oldVersion - 1;
          currIndex < newVersion - 1;
          currIndex++) {
        List<String> upgrades = SQLConstants.upgrades[currIndex];
        for (int i = 0; i < upgrades.length; i++) {
          db.execute(upgrades[i]);
        }
      }
    });
    _archiveDatabase =
        await openDatabase(archive, version: 1, onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }, onCreate: (db, version) {
      db.execute(SQLConstants.createGoalsTable);
      db.execute(SQLConstants.insertDefaultGoal);
      db.execute(SQLConstants.createTagsTable);
      db.execute(SQLConstants.createTaskTable);
      db.execute(SQLConstants.createDayPlanTable);
      db.execute(SQLConstants.createDocumentTable);
      db.execute(SQLConstants.createDocumentTaskTable);
    }, onOpen: (db) {
      attachDb(db, path, SQLConstants.mainDatabaseAlias);
      db.execute(SQLConstants.createGoalsTable);
      db.execute(SQLConstants.createTagsTable);
      db.execute(SQLConstants.createTaskTable);
      db.execute(SQLConstants.createDayPlanTable);
      db.execute(SQLConstants.createDocumentTable);
      db.execute(SQLConstants.createDocumentTaskTable);
    });
    _database = database;
    isLoading.value = 0;
  }

  Future<List<Map<String?, Object?>>?> archiveSQL(String sql) async {
    return await _archiveDatabase?.rawQuery(sql);
  }

  Future<bool?> archiveTransactionSql(
      Future<void> Function(Transaction txn) func) async {
    try {
      return await _archiveDatabase?.transaction((txn) async {
        try {
          await func(txn);
          return true;
        } on Exception {
          rethrow;
        }
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on Exception catch (e) {
      print(e);
      return false;
    }
  }

  Future<Database> attachDb(
      Database db, String absoluteEndPath, String databaseAlias) async {
    await db.rawQuery("ATTACH DATABASE '$absoluteEndPath' AS '$databaseAlias'");
    return db;
  }

  Future<bool> transaction(Future<void> Function(Transaction txn) func) async {
    bool? result = await _database?.transaction((txn) async {
      try {
        await func(txn);
        return true;
      } on Exception catch (e) {
        throw Exception("Transaction Cancelled: ${e.toString()}");
      }
    }).onError((error, stackTrace) {
      return false;
    });

    return result ?? false;
  }

  Future<int?> transactionInsert(Transaction txn, String sql,
      {List<Object?>? args}) async {
    return await txn.rawInsert(sql, args);
  }

  Future<List<Map<String, Object?>>?> transactionQuery(
      Transaction txn, String sql,
      {List<Object?>? args}) async {
    return await txn.rawQuery(sql, args);
  }

  Future<int?> transactionDelete(Transaction txn, String sql,
      {List<Object?>? args}) async {
    return await txn.rawDelete(sql, args);
  }

  Future<int?> transactionInsertObject(
      Transaction txn, SQFLiteObject insertObj) async {
    var result =
        await txn.insert(insertObj.objTable(), insertObj.toMapSQFLITE());
    return result;
  }

  Future<int?> transactionUpdateObject(Transaction txn, SQFLiteObject updateObj,
      {String? where}) async {
    var result = await txn
        .update(updateObj.objTable(), updateObj.toMapSQFLITE(), where: where);
    return result;
  }

  Future<List<Map<String, Object?>>?> rawQuery(String sql,
      {List<Object?>? args}) async {
    var result = await _database?.rawQuery(sql, args);
    return result;
  }

  Future<int?> rawInsert(String table, List<String> cols, List vals,
      {List<Object?>? arguments}) async {
    if (cols.length != vals.length) {
      return null;
    }
    Map<String, dynamic> colVals = {};
    for (int i = 0; i < cols.length; i++) {
      colVals[cols[i]] = vals[i];
    }
    var result =
        await _database?.rawInsert(SQLHelper.insertStmt(table, colVals));
    return result;
  }

  Future<int?> rawDelete(String sql, {List<Object?>? args}) async {
    return await _database?.rawDelete(sql, args);
  }

  Future<int?> insertObject(SQFLiteObject insertObj) async {
    var result =
        await _database?.insert(insertObj.objTable(), insertObj.toMapSQFLITE());
    return result;
  }

  Future<int?> insertOrUpdateObject(SQFLiteObject insertObj) async {
    var result = await _database?.rawQuery(SQLHelper.updateRowElseInsertTable(
        insertObj.objTable(), insertObj.toMapSQFLITE()));
    return result?.length;
  }

  Future<int?> updateObject(SQFLiteObject updateObj, {String? where}) async {
    var result = await _database
        ?.update(updateObj.objTable(), updateObj.toMapSQFLITE(), where: where);
    return result;
  }
}
