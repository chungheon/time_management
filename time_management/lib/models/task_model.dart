// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

/* Task - Name, Descrpt, Tied tag, Next Actionable Date, 
“History” number of times task has been pushed back, Status, 
“Documents TBD”, On completion linked tasks.*/

//Missing number of times tasked pushed back
//On Completion Linked Tasks (To flag it out to user these tasks were waiting for task to be completed)

import 'package:flutter/material.dart';
import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/models/tag_model.dart';

enum TaskStatus {
  upcoming,
  ongoing,
  completed,
  archive,
}

class Task with SQFLiteObject {
  Task({
    this.uid,
    this.task,
    this.goalTaskId,
    this.actionDate,
    this.status,
    this.completionDate,
    this.alertTime,
    List<Tag>? tags,
    List<String>? docs,
    this.goal,
  }) {
    if (tags != null) {
      this.tags = tags;
    }
  }
  final int? uid;
  String? task;
  int? goalTaskId;
  int? actionDate;
  TaskStatus? status;
  int? completionDate;
  int? alertTime;
  List<Tag> tags = [];
  List<Document> documents = [];
  Goal? goal;

  factory Task.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = queryResult[SQLConstants.colTaskId] as int?;
    String? rTask = queryResult[SQLConstants.colTaskTask] as String?;
    TaskStatus? rStatus = queryResult[SQLConstants.colTaskStatus] == null
        ? null
        : TaskStatus.values[queryResult[SQLConstants.colTaskStatus] as int];
    int? rActionDate = queryResult[SQLConstants.colTaskActionDate] as int?;
    int? rGoalTaskId = queryResult[SQLConstants.colTaskGoalId] as int?;
    int? rCompDate = queryResult[SQLConstants.colTaskCompletionDate] as int?;
    int? alertTime = queryResult[SQLConstants.colTaskAlertTime] as int?;
    return Task(
      uid: rUid,
      task: rTask,
      status: rStatus,
      actionDate: rActionDate,
      goalTaskId: rGoalTaskId,
      completionDate: rCompDate,
      alertTime: alertTime,
    );
  }

  //1 lower -1 higher
  static int prioritySort(Task first, Task second) {
    int firstDate = first.actionDate ?? 0;
    int secondDate = second.actionDate ?? 0;

    if (first.status == TaskStatus.completed ||
        first.status == TaskStatus.archive) {
      if (second.status != TaskStatus.completed &&
          second.status != TaskStatus.archive) {
        return 1;
      }
    } else if (second.status == TaskStatus.completed ||
        second.status == TaskStatus.archive) {
      return -1;
    }
    if (first.status == TaskStatus.ongoing &&
        second.status != TaskStatus.ongoing) {
      return -1;
    } else if (second.status == TaskStatus.ongoing &&
        first.status != TaskStatus.ongoing) {
      return 1;
    } else {
      if (firstDate == secondDate) {
        return (first.task ?? "").compareTo(second.task ?? "");
      } else {
        if (firstDate == 0 && secondDate == 0) {
          return 0;
        } else if (firstDate != 0 && secondDate == 0) {
          return -1;
        } else if (firstDate == 0 && secondDate != 0) {
          return 1;
        } else {
          return firstDate > secondDate ? 1 : -1;
        }
      }
    }
  }

  void updateFromSQFLITEMap(Map<String, Object?> queryResult) {
    String? rTask = (queryResult[SQLConstants.colTaskTask] ?? '').toString();
    TaskStatus? rStatus = queryResult[SQLConstants.colTaskStatus] == null
        ? null
        : TaskStatus.values[queryResult[SQLConstants.colTaskStatus] as int];
    int? rActionDate = queryResult[SQLConstants.colTaskActionDate] as int?;
    int? rGoalTaskId = queryResult[SQLConstants.colTaskGoalId] as int?;
    int? rCompDate = queryResult[SQLConstants.colTaskCompletionDate] as int?;
    int? rAlertTime = queryResult[SQLConstants.colTaskAlertTime] as int?;
    task = rTask;
    status = rStatus;
    actionDate = rActionDate;
    goalTaskId = rGoalTaskId;
    completionDate = rCompDate;
    alertTime = rAlertTime;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if ((uid ?? -1) < 0) {
      return {
        SQLConstants.colTaskTask: task,
        SQLConstants.colTaskStatus: status?.index,
        SQLConstants.colTaskActionDate: actionDate,
        SQLConstants.colTaskGoalId: goalTaskId,
        SQLConstants.colTaskCompletionDate: completionDate,
        SQLConstants.colTaskAlertTime: alertTime,
      };
    }
    return {
      SQLConstants.colTaskId: uid,
      SQLConstants.colTaskTask: task,
      SQLConstants.colTaskStatus: status?.index,
      SQLConstants.colTaskActionDate: actionDate,
      SQLConstants.colTaskGoalId: goalTaskId,
      SQLConstants.colTaskCompletionDate: completionDate,
      SQLConstants.colTaskAlertTime: alertTime,
    };
  }

  @override
  String objTable() {
    return SQLConstants.taskTable;
  }

  @override
  String toString() {
    return 'Task{${SQLConstants.colTaskId}: $uid, ${SQLConstants.colTaskTask}: $task, ' +
        '${SQLConstants.colTaskActionDate}: ${DateTimeHelpers.getDateStr(actionDate)},' +
        ' ${SQLConstants.colTaskCompletionDate}:${DateTimeHelpers.getDateStr(completionDate)}}' +
        '${SQLConstants.colTaskStatus} : $status, ${SQLConstants.colTaskGoalId} : $goalTaskId,${SQLConstants.colTaskAlertTime} : $alertTime,' +
        'tags:$tags, ';
  }
}
