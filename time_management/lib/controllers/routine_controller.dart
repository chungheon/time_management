import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/notifications_controller.dart';
import 'package:time_management/controllers/sql_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/helpers/sql_helper.dart';
import 'package:time_management/models/checklist_item_model.dart';
import 'package:time_management/models/routine_model.dart';

class RoutineController extends GetxController {
  final SQLController _sqlController = Get.find<SQLController>();
  final RxList<Routine> routineList = <Routine>[].obs;
  final RxList<ChecklistItem> checkList = <ChecklistItem>[].obs;

  Future<void> init() async {
    while (_sqlController.isLoading.value != 0) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await refreshList();
  }

  Future<void> refreshList() async {
    routineList.value = await fetchRoutines();
    routineList.sort(Routine.sortByTime);
    checkList.value = await fetchChecklist();
    update();
  }

  Future<List<Routine>> fetchRoutines() async {
    List<Map<String, Object?>>? routines = await _sqlController
        .rawQuery(SQLHelper.selectAllStmt(SQLConstants.routineTable));
    return routines?.map<Routine>((Map<String, Object?> queryResult) {
          return Routine.fromSQFLITEMap(queryResult);
        }).toList() ??
        [];
  }

  Future<List<ChecklistItem>> fetchChecklist() async {
    DateTime now = DateTime.now().dateOnly();
    List<Map<String, Object?>>? checkList = await _sqlController.rawQuery(
        SQLHelper.selectAllStmt(SQLConstants.checklistTable) +
            SQLHelper.selectAllBetweenStmt(
                now.millisecondsSinceEpoch,
                now.millisecondsSinceEpoch + 86400000,
                SQLConstants.colChecklistDate));
    return checkList?.map<ChecklistItem>((Map<String, Object?> queryResult) {
          return ChecklistItem.fromSQFLITEMap(queryResult);
        }).toList() ??
        [];
  }

  Future<void> generateTaskFromRoutine(
      GoalsController goalsController, Routine routine) async {
    if (routine.seq == null || routine.endDate == null) {
      return;
    }
    DateTime now = DateTime.now().add(const Duration(days: 1));
    goalsController
        .createTask(routine.desc ?? "", 1, now.millisecondsSinceEpoch, []);
    goalsController.refreshList();
    goalsController.update();
  }

  Future<void> deleteRoutine(NotificationsController notificationsController,
      GoalsController goalsController, Routine routine) async {
    try {
      _sqlController.rawDelete(SQLHelper.deleteStmtAnd(
          SQLConstants.routineTable,
          equal: {SQLConstants.colRoutineId: routine.uid}));
      routineList.removeWhere((element) => element.uid == routine.uid);
      notificationsController.setupNotifications(
          routineList,
          goalsController.dayPlansList[
                  DateTime.now().dateOnly().millisecondsSinceEpoch] ??
              []);
      update();
    } catch (e) {
      rethrow;
    }
    return;
  }

  Future<Routine> createRoutine(NotificationsController notificationsController,
      int seq, DateTime endDate,
      {int? uid,
      String? name,
      String? desc,
      DateTime? startDate,
      TimeOfDay? timeOfDay,
      String? payload}) async {
    int time = 6 * 60 * 60 * 1000;
    if (timeOfDay != null) {
      time = timeOfDay.hour * 60 * 60 * 1000 + timeOfDay.minute * 60 * 1000;
    }

    DateTime endUTCDate = endDate.add(Duration(milliseconds: time));
    DateTime? startUTCDate = startDate?.add(Duration(milliseconds: time));
    Routine routine = Routine(
        uid: -1,
        seq: seq,
        name: name,
        desc: desc,
        startDate:
            startUTCDate == null ? null : (startUTCDate.millisecondsSinceEpoch),
        endDate: endUTCDate.millisecondsSinceEpoch);

    int? id = await _sqlController.insertObject(routine);
    if (id == null) {
      throw Exception("Unable to create routine");
    }
    try {
      if (seq < 4) {
        await notificationsController.scheduleRoutine(routine,
            payload: 'page:2|routineUid:$id');
        routineList.add(routine);
        update();
      } else if (seq >= 5) {
        await notificationsController.scheduleRoutine(routine,
            payload: 'page:2|routineUid:$id');
        routineList.add(routine);
        update();
      }
      // } else {
      //   await notificationsController.scheduleAlarm(name ?? "", desc ?? "", endUTCDate,
      //       payload: "page:2");
      //   routineList.add(routine);
      // }
    } on Exception {
      _sqlController.rawDelete(SQLHelper.deleteStmtAnd(
          SQLConstants.routineTable,
          equal: {SQLConstants.colRoutineId: id}));
      rethrow;
    }
    return routine;
  }

  Future<bool> checkItem(int routineUid,
      {bool isChecked = false, int? checkListId}) async {
    try {
      if (!isChecked) {
        int now = DateTime.now().millisecondsSinceEpoch;

        ChecklistItem item =
            ChecklistItem(uid: -1, date: now, routineUid: routineUid);
        int? checklistId = await _sqlController.insertObject(item);
        checkList.add(ChecklistItem(
            uid: checklistId!, date: now, routineUid: routineUid));
      } else if (checkListId != null) {
        _sqlController.rawDelete(SQLHelper.deleteStmtAnd(
            SQLConstants.checklistTable,
            equal: {SQLConstants.colChecklistId: checkListId}));
        checkList.removeWhere((element) => element.uid == checkListId);
      }
    } on Exception {
      return false;
    }
    update();
    return true;
  }
}
