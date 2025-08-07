// ignore_for_file: prefer_adjacent_string_concatenation

import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/task_model.dart';

enum TaskPriority { mustDo, quickTask, niceToHave }

class DayPlanItem with SQFLiteObject {
  DayPlanItem({this.uid, this.taskId, this.taskPriority, this.date, this.task});
  final int? uid;
  int? taskId;
  TaskPriority? taskPriority;
  int? date;
  Task? task;

  factory DayPlanItem.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = int.tryParse(queryResult[SQLConstants.colDayPlanId].toString());
    int? rTaskId = queryResult[SQLConstants.colDayPlanTaskId] as int?;
    TaskPriority? rTaskPriority =
        queryResult[SQLConstants.colDayPlanPriority] == null
            ? null
            : TaskPriority
                .values[queryResult[SQLConstants.colDayPlanPriority] as int];
    int? rDate = queryResult[SQLConstants.colDayPlanDate] as int?;
    return DayPlanItem(
        uid: rUid, taskId: rTaskId, taskPriority: rTaskPriority, date: rDate);
  }

  void updateFromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rTaskId = queryResult[SQLConstants.colDayPlanTaskId] as int?;
    TaskPriority? rTaskPriority =
        queryResult[SQLConstants.colDayPlanPriority] == null
            ? null
            : TaskPriority
                .values[queryResult[SQLConstants.colDayPlanPriority] as int];
    int? rDate = queryResult[SQLConstants.colDayPlanDate] as int?;
    taskId = rTaskId;
    taskPriority = rTaskPriority;
    date = rDate;
  }

  static int prioritySort(DayPlanItem first, DayPlanItem second) {
    if (first.task == null) {
      if (second.task != null) {
        return 1;
      }
    } else if (second.task == null) {
      return -1;
    }
    
    if((first.taskPriority?.index == second.taskPriority?.index)){
      return Task.prioritySort(first.task!, second.task!);
    }

    if(first.task!.status == TaskStatus.completed || first.task!.status == TaskStatus.archive){
      if(second.task!.status != TaskStatus.completed && second.task!.status != TaskStatus.archive)
      {
        return 1;
      }
    }else if(second.task!.status == TaskStatus.completed || second.task!.status == TaskStatus.archive){
      return -1;
    }

    return (first.taskPriority?.index ?? 0) - (second.taskPriority?.index ?? 0);

    
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if ((uid ?? -1) < 0) {
      return {
        SQLConstants.colDayPlanTaskId: taskId,
        SQLConstants.colDayPlanPriority: taskPriority?.index,
        SQLConstants.colDayPlanDate: date,
      };
    }
    return {
      SQLConstants.colDayPlanId: uid,
      SQLConstants.colDayPlanTaskId: taskId,
      SQLConstants.colDayPlanPriority: taskPriority?.index,
      SQLConstants.colDayPlanDate: date,
    };
  }

  @override
  String objTable() {
    return SQLConstants.dayPlanTable;
  }

  @override
  String toString() {
    return 'DayTimePlan{${SQLConstants.colDayPlanId}: $uid, ${SQLConstants.colDayPlanTaskId}: $taskId,' +
        ' ${SQLConstants.colGoalPurpose}: $taskPriority, ${SQLConstants.colDayPlanDate}: ${DateTimeHelpers.getDateStr(date)}}';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType && other.runtimeType != int) {
      return false;
    }
    bool isEqual = false;
    if (other is DayPlanItem) {
      isEqual = other.uid == uid;
    } else if (other is int) {
      isEqual = (other == taskId);
    }
    return isEqual;
  }

  @override
  int get hashCode => super.hashCode;
}
