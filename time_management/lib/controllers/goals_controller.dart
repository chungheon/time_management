// ignore_for_file: prefer_adjacent_string_concatenation

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/controllers/sql_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/helpers/sql_helper.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/models/tag_model.dart';
import 'package:time_management/models/task_model.dart';

class GoalsController extends GetxController {
  final SQLController _sqlController = Get.find<SQLController>();
  final RxList<Goal> goalList = RxList<Goal>();
  final RxMap<int, List<DayPlanItem>> dayPlansList = RxMap();
  final int maxRetries = 50;

  @override
  onInit() {
    super.onInit();
    refreshList().then((value) {
      FlutterNativeSplash.remove();
    });
  }

  Future<List<DayPlanItem>> fetchDayPlan(int date) async {
    List<Map<String, Object?>>? dayPlanItems =
        await _sqlController.rawQuery(SQLHelper.selectDayList(date));
    return dayPlanItems?.map<DayPlanItem>((e) {
          return DayPlanItem.fromSQFLITEMap(e);
        }).toList() ??
        [];
  }

  Future<List<Goal>> fetchAllGoals() async {
    List<Map<String, Object?>>? goals =
        await _sqlController.rawQuery(SQLConstants.selectAllGoalsStmt);
    return goals?.map<Goal>((e) {
          return Goal.fromSQFLITEMap(e);
        }).toList() ??
        [];
  }

  Future<List<Tag>> fetchAllTags(Goal goal) async {
    List<Map<String, Object?>>? tags =
        await _sqlController.rawQuery(SQLHelper.selectAllTagsStmt(goal.uid!));

    return tags?.map<Tag>((e) {
          Tag tag = Tag.fromSQFLITEMap(e);
          tag.goal = goal;
          return tag;
        }).toList() ??
        [];
  }

  Future<List<Task>> fetchAllTasks(Goal goal) async {
    var now = DateTime.now().dateOnly();
    var beforeNow =
        now.subtract(const Duration(days: 14)).millisecondsSinceEpoch;
    var stmt = SQLHelper.selectTasksWithinDate(goal.uid!, beforeNow);
    List<Map<String, Object?>>? tasks = await _sqlController.rawQuery(stmt);
    return tasks?.map<Task>((e) {
          Task task = Task.fromSQFLITEMap(e);
          task.goal = goal;
          setDocumentsToTask(task, goal.documents);
          return task;
        }).toList() ??
        [];
  }

  Future<List<Document>> fetchAllDocuments(Goal goal) async {
    var docTablestmt = SQLHelper.selectAllDocsStmt(goal.uid!);

    List<Map<String, Object?>>? tasks =
        await _sqlController.rawQuery(docTablestmt);
    return tasks?.map<Document>((e) {
          Document doc = Document.fromSQFLITEMap(e);
          return doc;
        }).toList() ??
        [];
  }

  Future<Task?> fetchTaskById(int taskId) async {
    List<Map<String, Object?>>? tasks =
        await _sqlController.rawQuery(SQLHelper.selectTaskById(taskId));
    return tasks?.map<Task>((e) {
      Task task = Task.fromSQFLITEMap(e);
      for (var element in goalList) {
        if (element.uid == task.goalTaskId) {
          task.goal = element;
          break;
        }
      }

      return task;
    }).firstOrNull;
  }

  Future<Document?> fetchDocById(int docId) async {
    List<Map<String, Object?>>? documents =
        await _sqlController.rawQuery(SQLHelper.selectDocumentById(docId));
    return documents?.map<Document>((e) {
      Document doc = Document.fromSQFLITEMap(e);

      return doc;
    }).firstOrNull;
  }

  Future<void> refreshList() async {
    if (_sqlController.isLoading.value != 0) {
      int retries = 0;
      while (_sqlController.isLoading.value != 0 && retries < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 300));
        retries++;
      }
      if (_sqlController.isLoading.value != 0) {
        return;
      }
    }
    _sqlController.isLoading.value = 1;

    List<Goal> goals = await fetchAllGoals();
    for (Goal goal in goals) {
      if (goal.uid != null) {
        goal.tags = await fetchAllTags(goal);
        goal.documents = await fetchAllDocuments(goal);
        goal.tasks = await fetchAllTasks(goal);
        goal.tasks.sort(Task.prioritySort);
      }
    }
    goalList.value = goals;
    await refreshPlanList();
    _sqlController.isLoading.value = 0;

    update();
  }

  Future<void> refreshPlanList() async {
    int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
    await updatePlanList(dayPlansList, planDate: now);
    await updatePlanList(dayPlansList, planDate: now + 86400000);
  }

  Future<void> updatePlanList(RxMap<int, List<DayPlanItem>> dayPlansList,
      {int? planDate}) async {
    int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
    List<DayPlanItem> dayPlan = await fetchDayPlan(planDate ?? now);
    if (dayPlan.isEmpty) {
      for (Goal goal in goalList) {
        for (Task t in goal.tasks) {
          if (t.status == TaskStatus.upcoming ||
              t.status == TaskStatus.ongoing) {
            dayPlan.add(DayPlanItem(
                taskId: t.uid,
                task: t,
                taskPriority: TaskPriority.mustDo,
                date: planDate ?? now));
          }
        }
      }
    } else {
      for (DayPlanItem d in dayPlan) {
        Task? task = (await fetchTaskById(d.taskId ?? -1));
        try {
          if (task?.goalTaskId != null) {
            d.task = goalList[task!.goalTaskId! - 1]
                .tasks
                .firstWhere((element) => element.uid == d.taskId);
          }
        } on StateError {
          //Ignore
        }
      }
    }

    dayPlan.sort(DayPlanItem.prioritySort);
    dayPlansList[planDate ?? now] = dayPlan;
  }

  Future<void> updateTask(Task task, Goal goal) async {
    try {
      Task updatedTask = (await fetchTaskById(task.uid!))!;
      task.updateFromSQFLITEMap(updatedTask.toMapSQFLITE());
      await setDocumentsToTask(task, goal.documents);
      update();
    } on Exception {
      return;
    }
  }

  Future<void> updateGoal(Goal goal, {bool refreshPlanList = true}) async {
    try {
      Goal updatedGoal = (await fetchGoal(goal.uid!))!;
      goal.update(updatedGoal);
      if (refreshPlanList) {
        this.refreshPlanList();
      }
      update();
    } on Exception {
      return;
    }
  }

  Future<Goal?> fetchGoal(int goalUid) async {
    List<Map<String, Object?>>? goals =
        await _sqlController.rawQuery(SQLHelper.selectGoalStmt(goalUid));
    try {
      Goal? goal = goals?.map<Goal>((e) {
        return Goal.fromSQFLITEMap(e);
      }).first;

      goal!.tags = await fetchAllTags(goal);
      goal.documents = await fetchAllDocuments(goal);
      goal.tasks = await fetchAllTasks(goal);

      return goal;
    } on StateError {
      //Ignore
    }
    return null;
  }

  Future<int?> createGoal(
      String name, String purpose, String date, List<Tag> tags) async {
    int? newGoalUid = await _sqlController.insertObject(Goal(
      uid: -1,
      name: name,
      purpose: purpose,
      dueDate: DateTimeHelpers.tryParse(date)?.millisecondsSinceEpoch,
    ));
    if (newGoalUid != null) {
      for (Tag tag in tags) {
        createTag(tag.name ?? "", newGoalUid);
      }
    }
    return newGoalUid;
  }

  Future<bool> deleteGoal(Goal goal) async {
    bool result = await _sqlController.transaction((txn) async {
      try {
        goalList.removeWhere((element) => goal.uid == element.uid);
        await txn.rawDelete(
            SQLHelper.deleteStmtAndArgs(SQLConstants.goalTable,
                equal: {SQLConstants.colGoalId: goal.uid}),
            [goal.uid]);
      } on Exception {
        rethrow;
      }
    });
    return result;
  }

  Future<bool> editGoal(Goal goal,
      {String? name,
      String? purpose,
      DateTime? date,
      List<Tag>? tags,
      List<int>? docList}) async {
    Goal updatedGoal = Goal(
      uid: goal.uid,
      name: name ?? goal.name,
      purpose: purpose,
      dueDate: date?.millisecondsSinceEpoch,
    );
    List<int> diffUids = List.empty();
    if (docList != null) {
      List<int> currUids = goal.documents.map<int>((e) => e.uid ?? -1).toList();
      if (currUids.length != docList.length) {
        diffUids = currUids.toSet().difference(docList.toSet()).toList();
      }
    }
    bool result = await _sqlController.transaction((txn) async {
      try {
        int goalUid = await txn.update(
            updatedGoal.objTable(), updatedGoal.toMapSQFLITE(),
            where: "${SQLConstants.colGoalId}=${goal.uid!}");
        List<Tag> remainingTags = [];
        if (tags != null) {
          tags.removeWhere((e) {
            if (e.uid != -1) {
              remainingTags.add(e);
              return true;
            }
            return false;
          });
          List<int> remainingTagsID = remainingTags.map<int>((e) {
            return e.uid ?? -1;
          }).toList();
          for (Tag tag in goal.tags) {
            if (!remainingTagsID.contains(tag.uid ?? -2)) {
              deleteTag(tag);
            }
          }
          for (Tag tag in tags) {
            createTag(tag.name ?? "", goalUid);
          }

          remainingTags.addAll(tags);
          goal.tags = remainingTags;
        }
        if (diffUids.isNotEmpty) {
          await txn
              .rawQuery(SQLHelper.removeDocToGoalStmt(diffUids, goal.uid!));
        }
      } on Exception {
        rethrow;
      }
    });

    return result;
  }

  Future<bool> editTask(
    Task task, {
    String? taskStr,
    int? goalId,
    TaskStatus? status,
    int? actionDate,
    int? completionDate,
    List<int>? docList,
    List<Document>? addDocs,
  }) async {
    Task updatedTask = Task(
        uid: task.uid,
        goalTaskId: goalId ?? task.goalTaskId,
        task: taskStr ?? task.task,
        actionDate: actionDate == 0 ? null : actionDate ?? task.actionDate,
        status: status ?? task.status,
        completionDate:
            completionDate == 0 ? null : completionDate ?? task.completionDate);
    List<int> diffUids = List.empty();
    if (docList != null) {
      List<int> currUids = task.documents.map<int>((e) => e.uid ?? -1).toList();
      if (currUids.length != docList.length) {
        diffUids = currUids.toSet().difference(docList.toSet()).toList();
      }
    }
    bool result = await _sqlController.transaction((txn) async {
      try {
        await txn.update(updatedTask.objTable(), updatedTask.toMapSQFLITE(),
            where: "${SQLConstants.colTaskId}=${task.uid!}");
        if (addDocs != null && addDocs.isNotEmpty) {
          await txn.rawQuery(SQLHelper.linkDocToTaskStmt(
              addDocs.map<int>((e) => e.uid!).toList(), task.uid!));
        }
        if (diffUids.isNotEmpty) {
          await txn
              .rawQuery(SQLHelper.removeDocToTaskStmt(diffUids, task.uid!));
        }
      } on Exception {
        rethrow;
      }
    });
    return result;
  }

  Future<int?> createTag(String name, int goalUid) async {
    return await _sqlController.insertObject(Tag(
      uid: -1,
      goalUid: goalUid,
      name: name,
    ));
  }

  Future<int?> createDocument(Document doc, int goalUid) async {
    doc.goalUid = goalUid;
    return await _sqlController.insertObject(doc);
  }

  Future<int?> linkDocumentToTask(int docUid, int taskUid) async {
    return await _sqlController.rawInsert(
        SQLConstants.docTaskTable, SQLConstants.docTaskCols, [docUid, taskUid]);
  }

  Future<void> setDocumentsToTask(Task task, List<Document> documents) async {
    task.documents.clear();
    List<Map<String, Object?>> results = await _sqlController
            .rawQuery(SQLHelper.selectAllDocsByTaskId(task.uid ?? -1)) ??
        [];
    for (int i = 0; i < results.length; i++) {
      Document? doc = documents.firstWhereOrNull((element) =>
          int.tryParse(results[i][SQLConstants.colDocTaskDocId].toString()) ==
          (element.uid ?? -1));
      if (doc != null) {
        task.documents.add(doc);
      }
    }

    return;
  }

  Future<int?> deleteTag(Tag tag) async {
    return await _sqlController.rawDelete(
        SQLHelper.deleteStmtAndArgs(SQLConstants.tagTable,
            equal: {SQLConstants.colTagId: tag.uid}),
        args: [tag.uid]);
  }

  Future<int?> createTask(
    String task,
    int goalUid,
    int? actionDate,
    List<Document> docs,
  ) async {
    Task newTask =
        Task(goalTaskId: goalUid, task: task, actionDate: actionDate);
    int? creation;
    bool result = await _sqlController.transaction((txn) async {
      try {
        int? taskId =
            await _sqlController.transactionInsertObject(txn, newTask);
        if (taskId == null) {
          throw Exception("Failed to create task");
        }
        if (docs.isNotEmpty) {
          await txn.rawQuery(SQLHelper.linkDocToTaskStmt(
              docs.map<int>((e) => e.uid!).toList(), taskId));
        }
        creation = taskId;
      } on Exception {
        rethrow;
      }
    });

    return creation;
  }

  Future<List<Task>> fetchTasksByDate(int? date) async {
    String sql = date == null
        ? SQLHelper.selectTaskByWithoutDate()
        : SQLHelper.selectTaskByDate(date, date + 86399999);
    List<Map<String, Object?>> result =
        await _sqlController.rawQuery(sql) ?? [];
    return result.map<Task>((e) {
      Task task = Task.fromSQFLITEMap(e);
      try {
        task.goal = goalList.firstWhere((e) => e.uid == task.goalTaskId);
      } on Exception {
        // Ignore
      }

      return task;
    }).toList();
  }

  Future<List<Task>> fetchOverdueTasks(int date) async {
    String sql = SQLHelper.selectOverDueTasks(date);
    List<Map<String, Object?>> result =
        await _sqlController.rawQuery(sql) ?? [];
    return result.map<Task>((e) {
      Task task = Task.fromSQFLITEMap(e);
      try {
        task.goal = goalList.firstWhere((e) => e.uid == task.goalTaskId);
      } on Exception {
        // Ignore
      }
      return task;
    }).toList();
  }

  Future<bool> createDayPlan(List<DayPlanItem> dayList) async {
    for (DayPlanItem item in dayList) {
      int? newDayPlanItem = await _sqlController.insertObject(item);
      if (newDayPlanItem == null) {
        return false;
      }
    }
    return true;
  }

  Future<bool> updateDayPlan(
      List<DayPlanItem> dayList, List<DayPlanItem> previousDayList) async {
    List<DayPlanItem> toRemoveList = List<DayPlanItem>.from(previousDayList);
    for (DayPlanItem item in dayList) {
      if (item.uid != null) {
        toRemoveList.removeWhere((element) => element.uid == item.uid);
        int? updateDayPlanItem = await _sqlController.updateObject(item,
            where:
                "${SQLConstants.colDayPlanId}=${item.uid} AND ${SQLConstants.colDayPlanDate}=${item.date}");
        if (updateDayPlanItem == null) {
          return false;
        }
      } else {
        int? newDayPlanItem = await _sqlController.insertObject(item);
        if (newDayPlanItem == null) {
          return false;
        }
      }
    }
    for (DayPlanItem remove in toRemoveList) {
      await _sqlController.rawDelete(
          SQLHelper.deleteStmtAndArgs(SQLConstants.dayPlanTable, equal: {
            SQLConstants.colDayPlanId: remove.uid,
          }),
          args: [remove.uid]);
    }
    return true;
  }

  Future<int> moveTaskFromGoal(int taskUid, int newGoalUid) async {
    try {
      await _sqlController.rawQuery(
          "UPDATE ${SQLConstants.taskTable} SET ${SQLConstants.colTaskGoalId}=$newGoalUid WHERE " +
              "${SQLConstants.colTaskId}=$taskUid;");
    } on Exception {
      return -1;
    }
    return 1;
  }

  Future<int?> deleteTaskFromGoal(int taskUid, int goalUid) async {
    try {
      int? result = await _sqlController.rawDelete(
          SQLHelper.deleteStmtAndArgs(SQLConstants.taskTable,
              equal: {SQLConstants.colTaskId: taskUid}),
          args: [taskUid]);
      goalList
          .firstWhere((element) => element.uid == goalUid)
          .tasks
          .removeWhere((element) => element.uid == taskUid);
      return result;
    } on Exception {
      rethrow;
    }
  }

  Future<bool> deleteTasksFromGoal(List<int> taskUids, int goalUid) async {
    try {
      bool result = await _sqlController.transaction((txn) async {
        for (int taskUid in taskUids) {
          await txn.rawQuery("DELETE FROM ${SQLConstants.taskTable} WHERE " +
              "${SQLConstants.colTaskId}=$taskUid;");
        }
      });
      if (result) {
        var goal = goalList.firstWhere((element) => element.uid == goalUid);
        for (int uid in taskUids) {
          goal.tasks.removeWhere((element) => element.uid == uid);
        }
      } else {
        throw Exception("Unable to Delete Tasks From Goal");
      }
      return result;
    } on Exception {
      rethrow;
    }
  }

  Future<bool?> archiveTask(List<int> taskUids, int goalUid) async {
    return await _sqlController.archiveTransactionSql((txn) async {
      await _sqlController.transactionInsert(
          txn,
          SQLHelper.updateRowElseInsertTable(SQLConstants.goalTable,
              {SQLConstants.colGoalId: goalUid.toString()}));
      String query = SQLHelper.selectRowFromTable(
          taskUids.map((e) => e.toString()).toList(),
          sqlCol: SQLConstants.colTaskId,
          sqlTable:
              "${SQLConstants.mainDatabaseAlias}.${SQLConstants.taskTable}");
      var taskList = await _sqlController.transactionQuery(
        txn,
        query,
      );
      for (var task in taskList ?? []) {
        query =
            SQLHelper.updateRowElseInsertTable(SQLConstants.taskTable, task);
        await _sqlController.transactionInsert(txn, query);
        query = SQLHelper.deleteStmtAnd(
            "${SQLConstants.mainDatabaseAlias}.${SQLConstants.taskTable}",
            equal: {SQLConstants.colTaskId: task[SQLConstants.colTaskId]});
        _sqlController.transactionDelete(txn, query);
      }
    });
  }

  Future<List<Map<String?, Object?>?>?> archiveSQL(String sql) async {
    return await _sqlController.archiveSQL(sql);
  }
}
