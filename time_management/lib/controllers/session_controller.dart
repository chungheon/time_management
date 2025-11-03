import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/controllers/sql_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/helpers/sql_helper.dart';
import 'package:time_management/models/session_model.dart';

class SessionController extends GetxController {
  final Rxn<Session> latestSess = Rxn<Session>();
  final SQLController _sqlController = Get.find();
  final RxInt totalBreaks = RxInt(0);
  final RxInt sessionSecs = RxInt(1800);
  final RxInt initialSecs = RxInt(1800);
  final Rx<Timer> timer = Rx<Timer>(Timer(Duration.zero, () {}));
  final RxInt inputTimeMin = RxInt(30);
  final RxInt inputBreakMin = RxInt(5);
  final PageController timeMinController = PageController();
  final PageController breakMinController = PageController();
  final RxBool isSession = true.obs;
  final RxBool isPaused = false.obs;
  final int incrementMax = 120;
  final int incrementMin = 1;
  final int breakMin = 1;
  final int breakMax = 30;
  @override
  void onInit() {
    super.onInit();
    initialSecs.value = inputTimeMin.value * 60;
    sessionSecs.value = initialSecs.value;
    timer.value.cancel();
    updateLatestSession();
  }

  void updateLatestSession() {
    _sqlController.rawQuery(SQLHelper.selectSessionLastDate()).then((result) {
      int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
      if (result?.isEmpty ?? true) {
        latestSess.value = Session(
          uid: -1,
          sessions: 0,
          breaks: 0,
          sessInterval: 30,
          breakInterval: 5,
        );
        return;
      }
      var sorted = result!.toList()..sort(sortSessionMapDate);
      print(sorted);
      latestSess.value = Session.fromSQFLITEMap(sorted[0]);
      if ((latestSess.value?.date ?? 0) >= now) {
        inputTimeMin.value = latestSess.value?.sessInterval ?? 30;
        inputBreakMin.value = latestSess.value?.breakInterval ?? 5;
      } else {
        latestSess.value = Session(
          uid: -1,
          sessions: 0,
          breaks: 0,
          sessInterval: latestSess.value?.sessInterval ?? 30,
          breakInterval: latestSess.value?.breakInterval ?? 5,
        );
      }
    });
  }

  int sortSessionMapDate(
      Map<String, Object?> first, Map<String, Object?> second) {
    int? firstDate =
        int.tryParse(first[SQLConstants.colSessionDate].toString());
    int? secDate = int.tryParse(first[SQLConstants.colSessionDate].toString());
    if (firstDate == null) {
      return -1;
    } else if (secDate == null) {
      return 1;
    }
    return firstDate == secDate
        ? 0
        : firstDate < secDate
            ? 1
            : -1;
  }

  void sessionComplete(Rxn<Session> session) async {
    if (session.value != null) {
      if (session.value!.uid != -1) {
        session.value!.sessions = (session.value!.sessions ?? 0) + 1;
        await updateSession(session);
      } else {
        await createSessionData(session);
        session.value!.sessions = (session.value!.sessions ?? 0) + 1;
        await updateSession(session);
      }
    }
  }

  void breakComplete(Rxn<Session> session) async {
    if (session.value != null) {
      if (session.value!.uid != -1) {
        session.value!.breaks = (session.value!.breaks ?? 0) + 1;
        updateSession(session, date: DateTime.now().millisecondsSinceEpoch);
        print(session.value.toString());
        update();
      } else {
        createSessionData(session);
        session.value!.breaks = (session.value!.breaks ?? 0) + 1;
        updateSession(session);
      }
    }
  }

  Future<int?> createSessionData(Rxn<Session> session,
      {int? sessInterval, int? breakInterval}) async {
    Session newSession = Session(
      uid: -1,
      date: DateTime.now().millisecondsSinceEpoch,
      sessions: 0,
      breaks: 0,
      sessInterval: sessInterval ?? session.value?.sessInterval ?? 30,
      breakInterval: breakInterval ?? session.value?.breakInterval ?? 5,
    );
    return await _sqlController
        .rawQuery(SQLHelper.updateRowElseInsertTable(
            SQLConstants.sessionTable, newSession.toMapSQFLITE()))
        .then((sessList) {
      if (sessList?.length == 1) {
        session.value = Session.fromSQFLITEMap(sessList!.first);
        return session.value?.uid ?? -1;
      }
      return -1;
    });
  }

  Future<int?> updateSession(Rxn<Session> session,
      {int? date,
      int? sessInterval,
      int? breakInterval,
      int? sessionNo,
      int? breakNo}) async {
    Session newSession = Session(
        uid: session.value?.uid ?? -1,
        date: date ??
            session.value?.date ??
            DateTime.now().millisecondsSinceEpoch,
        sessInterval: sessInterval ?? session.value?.sessInterval ?? 30,
        sessions: sessionNo ?? session.value?.sessions ?? 0,
        breakInterval: breakInterval ?? session.value?.breakInterval ?? 5,
        breaks: breakNo ?? session.value?.breaks ?? 0);
    return await _sqlController
        .rawQuery(SQLHelper.updateRowElseInsertTable(
            SQLConstants.sessionTable, newSession.toMapSQFLITE()))
        .then((sessList) {
      if (sessList?.length == 1) {
        session.value = Session.fromSQFLITEMap(sessList!.first);
        return session.value?.uid ?? -1;
      }
      return -1;
    });
  }
}
