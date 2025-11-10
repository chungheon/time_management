// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/helpers/date_time_helpers.dart';

class SQLHelper {
  static String insertStmt(String tableName, Map<String, dynamic> colVals) {
    var colStr = '';
    var valuesStr = '';
    Iterable<MapEntry<String, dynamic>> entries = colVals.entries;
    for (int i = 0; i < entries.length; i++) {
      var key = entries.elementAt(i).key;
      var val = entries.elementAt(i).value;
      if (val is String) {
        val = "'$val'";
      } else {
        val = val.toString();
      }
      if (i == 0) {
        colStr += key;
        valuesStr += val;
      } else {
        colStr += ', $key';

        valuesStr += ", $val";
      }
    }

    var stmt = 'INSERT INTO $tableName($colStr) VALUES($valuesStr)';
    return stmt;
  }

  static String insertStmtArgs(String tableName, Map<String, dynamic> colVals) {
    var colStr = '';
    var valuesStr = '';
    Iterable<MapEntry<String, dynamic>> entries = colVals.entries;
    for (int i = 0; i < colVals.length; i++) {
      if (i == 0) {
        colStr += entries.elementAt(i).key;
        valuesStr += " ? ";
      } else {
        colStr += ', ${entries.elementAt(i).key}';
        valuesStr += ', ?';
      }
    }

    var stmt = 'INSERT INTO $tableName($colStr) VALUES($valuesStr)';
    return stmt;
  }

  static String deleteStmtAnd(String tableName, {Map<String, dynamic>? equal}) {
    var whereStr = '';
    if (equal != null) {
      for (var condition in equal.entries) {
        if (whereStr.isEmpty) {
          whereStr += '${condition.key}=${condition.value} ';
        } else {
          whereStr += 'AND ${condition.key}=${condition.value} ';
        }
      }
    }
    var stmt = 'DELETE FROM $tableName WHERE $whereStr';
    return stmt;
  }

  static String deleteStmtAndArgs(String tableName,
      {Map<String, dynamic>? equal}) {
    var whereStr = '';
    if (equal != null) {
      for (var condition in equal.entries) {
        if (whereStr.isEmpty) {
          whereStr += '${condition.key}= ? ';
        } else {
          whereStr += 'AND ${condition.key}= ? ';
        }
      }
    }
    var stmt = 'DELETE FROM $tableName WHERE $whereStr';
    return stmt;
  }

  static String convertToStmtStr(value) {
    if (value.runtimeType == String) {
      return '"$value"';
    } else {
      return value.toString();
    }
  }

  static String selectGoalStmt(int goalUid) {
    return "SELECT * FROM ${SQLConstants.goalTable} WHERE ${SQLConstants.colGoalId} = $goalUid";
  }

  static String selectAllStmt(String table,
      {int? uid, String? column, String? sortColumn}) {
    String stmt = "SELECT * FROM $table";
    if (uid != null && column != null) {
      stmt += " WHERE $column = $uid";
    }
    if (sortColumn != null) {
      stmt += " ORDER BY $sortColumn";
    }
    return stmt;
  }

  static String selectAllBetweenStmt(
      int lowerBound, int upperBound, String col) {
    return " WHERE $col BETWEEN $lowerBound AND $upperBound";
  }

  static String selectAllDocsStmt(int goalUid) {
    return "SELECT * FROM ${SQLConstants.docTable} WHERE ${SQLConstants.colDocGoalId} = $goalUid " +
        "ORDER BY ${SQLConstants.colDocId}";
  }

  static String selectAllDocsByTaskId(int taskUid) {
    return "SELECT * FROM ${SQLConstants.docTaskTable} WHERE ${SQLConstants.colDocTaskTaskId} = $taskUid " +
        "ORDER BY ${SQLConstants.colDocTaskDocId}";
  }

  static String selectAllTagsStmt(int goalUid) {
    return "SELECT * FROM ${SQLConstants.tagTable} WHERE ${SQLConstants.colTagGoalId} = $goalUid";
  }

  static String selectAllTasksStmt(int goalUid) {
    return "SELECT * FROM ${SQLConstants.taskTable} WHERE ${SQLConstants.colTaskGoalId} = $goalUid";
  }

  static String selectTasksWithinDate(int goalUid, int startDate,
      {int? endDate}) {
    String selectStmt =
        "SELECT * FROM ${SQLConstants.taskTable} WHERE ${SQLConstants.colTaskGoalId} = $goalUid " +
            "AND (${SQLConstants.colTaskActionDate} IS NULL OR (${SQLConstants.colTaskActionDate} >= $startDate ";
    if (endDate == null) {
      return selectStmt + "))";
    }
    return selectStmt + " AND ${SQLConstants.colTaskActionDate} <= $endDate))";
  }

  static String selectSessionByDate(int now) {
    return "SELECT * FROM ${SQLConstants.sessionTable} WHERE ${SQLConstants.colSessionDate} == $now";
  }

  static String selectTaskById(int taskUid) {
    return "SELECT * FROM ${SQLConstants.taskTable} WHERE ${SQLConstants.colTaskId} = $taskUid";
  }

  static String selectDocumentById(int docUid) {
    return "SELECT * FROM ${SQLConstants.docTable} WHERE ${SQLConstants.colDocId} = $docUid";
  }

  static String selectGoalByUidStmt(int goalUid) {
    return "SELECT * FROM ${SQLConstants.goalTable} WHERE ${SQLConstants.colGoalId} = $goalUid";
  }

  static String selectTaskByDate(int startDate, int endDate) {
    return "SELECT * FROM ${SQLConstants.taskTable} WHERE ${SQLConstants.colTaskActionDate} BETWEEN $startDate AND $endDate";
  }

  static String selectOverDueTasks(int startDate) {
    int prevDate = startDate - 86400000;
    return "SELECT * FROM ${SQLConstants.taskTable} " +
        "WHERE ${SQLConstants.colTaskActionDate} < $startDate AND ${SQLConstants.colTaskActionDate} >= $prevDate " +
        " AND (${SQLConstants.colTaskStatus} = 0  OR ${SQLConstants.colTaskStatus} = 1)";
  }

  static String selectTaskByWithoutDate() {
    return "SELECT * FROM ${SQLConstants.taskTable} WHERE ${SQLConstants.colTaskActionDate} IS NULL";
  }

  static String selectDayList(int date) {
    return "SELECT * FROM ${SQLConstants.dayPlanTable} WHERE ${SQLConstants.colDayPlanDate} = $date";
  }

  static String linkDocToTaskStmt(List<int> docUids, int taskUid) {
    String stmt =
        "INSERT INTO ${SQLConstants.docTaskTable} (${SQLConstants.colDocTaskDocId}, ${SQLConstants.colDocTaskTaskId}) VALUES ";
    for (int i = 0; i < docUids.length; i++) {
      if (i == docUids.length - 1) {
        stmt += " (${docUids[i]}, $taskUid);";
      } else {
        stmt += " (${docUids[i]}, $taskUid),";
      }
    }
    return stmt;
  }

  static String removeDocToTaskStmt(List<int> docUids, int taskUid) {
    String stmt =
        "DELETE FROM ${SQLConstants.docTaskTable} WHERE ${SQLConstants.colDocTaskDocId} IN (";
    for (int i = 0; i < docUids.length; i++) {
      if (i == docUids.length - 1) {
        stmt += "${docUids[i]}) AND ${SQLConstants.colDocTaskTaskId}=$taskUid;";
      } else {
        stmt += "${docUids[i]},";
      }
    }
    return stmt;
  }

  static String removeDocToGoalStmt(List<int> docUids, int goalUid) {
    String stmt =
        "DELETE FROM ${SQLConstants.docTable} WHERE ${SQLConstants.colDocId} IN (";
    for (int i = 0; i < docUids.length; i++) {
      if (i == docUids.length - 1) {
        stmt += "${docUids[i]}) AND ${SQLConstants.colDocGoalId}=$goalUid;";
      } else {
        stmt += "${docUids[i]},";
      }
    }
    return stmt;
  }

  static String selectRowFromTable(List<String> val,
      {String sqlTable = SQLConstants.goalTable,
      String sqlCol = SQLConstants.colGoalId}) {
    String stmt = "SELECT * FROM $sqlTable WHERE $sqlCol IN (";
    for (int i = 0; i < val.length; i++) {
      if (i == val.length - 1) {
        stmt += "${val[i].toString()});";
      } else {
        stmt += "${val[i].toString()},";
      }
    }
    return stmt;
  }

  static String updateRowElseInsertTable(
      String tableName, Map<String, dynamic> colVals) {
    String sqlStr = "";
    String colStr = "(";
    String valStr = "(";
    for (var i = 0; i < colVals.length; i++) {
      String key = colVals.keys.elementAt(i);
      var val = colVals.values.elementAt(i);
      if (val is String) {
        val = "'$val'";
      }
      if (i == colVals.length - 1) {
        colStr += "$key)";

        valStr += "${val.toString()})";
      } else {
        colStr += "$key, ";
        valStr += "$val, ";
      }
    }
    sqlStr = "INSERT OR REPLACE INTO $tableName $colStr values $valStr";
    return sqlStr;
  }
}
