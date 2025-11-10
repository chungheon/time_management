import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/notifications_controller.dart';
import 'package:time_management/controllers/sql_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/helpers/notification_text_helper.dart';
import 'package:time_management/helpers/sql_helper.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/session_model.dart';

class SessionController extends GetxController {
  final Rx<Session> currentSess = Rx<Session>(Session(
    uid: -1,
  ));
  final RxList<SessionCounter> sessCounter = RxList<SessionCounter>();
  final Rxn<SessionCounter> currCounter = Rxn<SessionCounter>();
  final SQLController _sqlController = Get.find();
  final NotificationsController _notificationsController = Get.find();
  final GoalsController _goalsController = Get.find();
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
  final RxInt timerEndTime = RxInt(0);
  final RxInt currentNotifId = RxInt(0);
  final RxList<DayPlanItem> items = RxList();

  @override
  void onInit() {
    super.onInit();
    initialSecs.value = inputTimeMin.value * 60;
    sessionSecs.value = initialSecs.value;
    timer.value.cancel();
    fetchSession().then((session) async {
      currentSess.value = session;
      inputBreakMin.value = session.breakInterval ?? 5;
      breakMinController.jumpToPage(inputBreakMin.value - 1);
      fetchSessionCounters(session).then((counter) {
        sessCounter.value = counter;
        if (counter.isEmpty) {
          currCounter.value = SessionCounter(
              sessId: session.uid!, sessionCount: 0, sessionInterval: 30);
          sessCounter.add(currCounter.value!);
        } else {
          currCounter.value = counter.last;
          inputTimeMin.value = currCounter.value?.sessionInterval ?? 30;
          timeMinController.jumpToPage(inputTimeMin.value - 1);
        }
        initialSecs.value = inputTimeMin.value * 60;
        sessionSecs.value = initialSecs.value;
      }).onError((e, _) {
        //Ignore Error
      });
    }).onError((e, _) {
      //Ignore Error
    });
    int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
    items.value = _goalsController.dayPlansList[now] ?? [];
  }

  Timer createTimerFunc() {
    return Timer.periodic(const Duration(seconds: 1), (_) {
      sessionSecs.value -= 1;
      int now = DateTime.now().millisecondsSinceEpoch - 200;
      if (now >= timerEndTime.value || sessionSecs.value <= 0) {
        timer.value.cancel();
        endTimer(isSession.value, remove: false);
        if (isSession.value) {
          currCounter.value!.sessionCount =
              (currCounter.value!.sessionCount ?? 0) + 1;
          if (currCounter.value!.sessionCount == 1) {
            _sqlController.insertObject(currCounter.value!);
          } else {
            _sqlController.updateObject(currCounter.value!);
          }
        } else {
          currentSess.value.breakCount =
              (currentSess.value.breakCount ?? 0) + 1;
          _sqlController.updateObject(currentSess.value);
        }
      } else {
        int secondsLeft = ((timerEndTime.value - now) / 1000).floor();
        if (secondsLeft < sessionSecs.value) {
          sessionSecs.value = secondsLeft;
        }
      }
    });
  }

  Future<void> endTimer(bool sessionPress, {bool remove = true}) async {
    if ((isSession.value && sessionPress) ||
        (!isSession.value && !sessionPress)) {
      int sessionTime =
          isSession.value ? inputTimeMin.value : inputBreakMin.value;
      initialSecs.value = sessionTime * 60;
      sessionSecs.value = initialSecs.value;
      timer.value.cancel();
      if (remove) removeNotification(currentNotifId.value);
      update();
    }
  }

  Future<void> startTimer() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    int sessionTime =
        isSession.value ? inputTimeMin.value : inputBreakMin.value;
    initialSecs.value = sessionTime * 60;
    sessionSecs.value = initialSecs.value;
    timerEndTime.value = now + (sessionTime * 60 * 1000);
    String title = isSession.value
        ? NotificationTextHelper.sessionEndTitle(sessionTime)
        : NotificationTextHelper.breakEndTitle(sessionTime);
    String body = isSession.value
        ? NotificationTextHelper.sessionEndBody(
            (currCounter.value?.sessionCount ?? 0) + 1)
        : NotificationTextHelper.breakEndBody();
    String payload = isSession.value
        ? NotificationTextHelper.sessionEndPayload(
            currentSess.value.uid!.toString(),
            sessionTime.toString(),
            ((currCounter.value?.sessionCount ?? 0) + 1).toString())
        : NotificationTextHelper.breakEndPayload(
            currentSess.value.uid!.toString(),
            sessionTime.toString(),
            ((currentSess.value.breakCount ?? 0) + 1).toString());
    currentNotifId.value = await createNotification(
        title, body, timerEndTime.value,
        payload: payload);
    if (isSession.value) {
      currCounter.value = await createSessionTimer(sessionTime);
    } else {
      currentSess.value.breakInterval = sessionTime;
      _sqlController.updateObject(currentSess.value);
    }
    timer.value = createTimerFunc();
    update();
  }

  void resetTimer(int totalTimeMin, bool isSession) {
    if (isSession) {
      inputTimeMin.value = totalTimeMin;
    } else {
      inputBreakMin.value = totalTimeMin;
    }
    initialSecs.value = (totalTimeMin * 60).floor();
    sessionSecs.value = (totalTimeMin * 60).floor();
  }

  Future<void> fetchSessionWithUid(
      String uid, bool isSession, int interval, int updateTotal) async {
    currentSess.value = await fetchSession(uid: uid);
    sessCounter.value = await fetchSessionCounters(currentSess.value);
    if (isSession) {
      currCounter.value = await getSessionCounter(interval);
      if (currCounter.value!.sessionCount == 0) {
        _sqlController.insertObject(currCounter.value!);
      }
      if ((currCounter.value!.sessionCount ?? 0) < updateTotal) {
        currCounter.value!.sessionCount = updateTotal;
        _sqlController.updateObject(currCounter.value!);
      }
    } else {
      if ((currentSess.value.breakCount ?? 0) < updateTotal) {
        currentSess.value.breakCount = updateTotal;
      }
      _sqlController.updateObject(currentSess.value);
    }
  }

  Future<List<SessionCounter>> fetchSessionCounters(Session currSession) async {
    List<Map<String, Object?>> sessionCounter =
        await _sqlController.rawQuery(SQLHelper.selectRowFromTable(
              [currSession.uid!.toString()],
              sqlTable: SQLConstants.sessionCounterTable,
              sqlCol: SQLConstants.colSessionCounterSessId,
            )) ??
            [];
    return sessionCounter.map<SessionCounter>((sessCounter) {
      return SessionCounter.fromSQFLITEMap(sessCounter);
    }).toList();
  }

  Future<Session> fetchSession({String? uid}) async {
    String query = SQLHelper.selectRowFromTable([uid.toString()],
        sqlTable: SQLConstants.sessionTable, sqlCol: SQLConstants.colSessionId);
    int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
    if (uid == null) {
      query = SQLHelper.selectSessionByDate(now);
    }

    List<Map<String, Object?>> results =
        await _sqlController.rawQuery(query) ?? [];

    if (results.isNotEmpty) {
      try {
        return Session.fromSQFLITEMap(results.first);
      } on Exception {
        rethrow;
      }
    } else {
      try {
        var newUid = await _sqlController.insertObject(
            Session(uid: -1, date: now, breakCount: 0, breakInterval: 5));
        var result = await _sqlController.fetchSingleRow(
            SQLHelper.selectRowFromTable([newUid.toString()],
                sqlTable: SQLConstants.sessionTable,
                sqlCol: SQLConstants.colSessionId));

        return Session.fromSQFLITEMap(result);
      } on Exception {
        rethrow;
      }
    }
  }

  void removeNotification(int notifId) {
    _notificationsController.removeNotification(notifId);
  }

  Future<int> createNotification(String title, String body, int time,
      {String? payload}) async {
    return _notificationsController.scheduleAlarm(
        title, body, DateTime.fromMillisecondsSinceEpoch(time),
        payload: payload);
  }

  Future<SessionCounter> getSessionCounter(int sessInterval) async {
    return await createSessionTimer(sessInterval);
  }

  Future<void> pauseTimer() async {
    isPaused.value = true;
    timer.value.cancel();
    removeNotification(currentNotifId.value);
    update();
  }

  Future<void> resumeTimer() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    String title = isSession.value
        ? NotificationTextHelper.sessionEndTitle(
            (initialSecs.value / 60).floor())
        : NotificationTextHelper.breakEndTitle(
            (initialSecs.value / 60).floor());
    String body = isSession.value
        ? NotificationTextHelper.sessionEndBody(
            (currCounter.value?.sessionCount ?? 0) + 1)
        : NotificationTextHelper.breakEndBody();
    timerEndTime.value = now + (sessionSecs.value * 1000);
    String payload = isSession.value
        ? NotificationTextHelper.sessionEndPayload(
            currentSess.value.uid!.toString(),
            (initialSecs / 60).floor().toString(),
            ((currCounter.value?.sessionCount ?? 0) + 1).toString())
        : NotificationTextHelper.breakEndPayload(
            currentSess.value.uid!.toString(),
            (initialSecs / 60).floor().toString(),
            ((currentSess.value.breakCount ?? 0) + 1).toString());
    currentNotifId.value = await createNotification(
        title, body, timerEndTime.value,
        payload: payload);
    initialSecs.value =
        isSession.value ? inputTimeMin.value : inputBreakMin.value;
    sessionSecs.value = initialSecs.value;
    timer.value = createTimerFunc();
    isPaused.value = false;
  }

  Future<void> updateBreakTimer(Session session, int breakInterval) async {
    session.update(breakInterval: breakInterval);
    if (session.uid == -1) {
      return;
    }
    try {
      _sqlController.updateObject(session);
    } on Exception {
      rethrow;
    }
  }

  Future<SessionCounter> createSessionTimer(int sessionInterval) async {
    bool found = false;
    SessionCounter result = SessionCounter(
        sessId: currentSess.value.uid!,
        sessionCount: 0,
        sessionInterval: sessionInterval);
    for (SessionCounter c in sessCounter) {
      if (c.sessionInterval == sessionInterval) {
        found = true;
        result = c;
        break;
      }
    }
    if (!found) {
      sessCounter.add(result);
    }
    return result;
  }

  Future<void> addCountSession(SessionCounter counter) async {
    counter.sessionCount = (counter.sessionCount ?? 0) + 1;
    try {
      _sqlController.updateObject(counter);
    } on Exception {
      rethrow;
    }
  }

  Future<void> addCountBreak(Session sess) async {
    sess.breakCount = (sess.breakCount ?? 0) + 1;
    try {
      _sqlController.updateObject(sess);
    } on Exception {
      rethrow;
    }
  }
//   Future<void> fetchLatestSession() async {
//     _sqlController.rawQuery(SQLHelper.selectSessionLastDate()).then((result) {
//       int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
//       if (result?.isEmpty ?? true) {
//         latestSess.value = Session(
//           uid: -1,
//           date: now,
//           breaks: 0,
//           breakInterval: 5,
//         );
//         return;
//       }
//       var sorted = result!.toList();
//       sorted.sort(sortSessionMapDate);
//       latestSess.value = Session.fromSQFLITEMap(sorted[0]);
//       if ((latestSess.value?.date ?? 0) >= now) {
//         inputBreakMin.value = latestSess.value?.breakInterval ?? 5;
//         sessionSecs.value = inputTimeMin.value * 60;
//         timeMinController.jumpToPage(inputTimeMin.value - 1);
//         breakMinController.jumpToPage(inputBreakMin.value - 1);
//         print(latestSess.value);
//         print(inputBreakMin.value);
//         latestSess.value = Session(
//           uid: -1,
//           breaks: 0,
//           breakInterval: inputBreakMin.value,
//         );
//       } else {
//         latestSess.value = Session(
//           uid: -1,
//           breaks: 0,
//           breakInterval: latestSess.value?.breakInterval ?? 5,
//         );
//       }
//     });
//     update();
//   }

//   Future<void> fetchLatestSessionWithId(String uid) async {
//     print("FETCH BY ID! $uid");
//     latestSess.value = Session.fromSQFLITEMap(
//         await _sqlController.fetchSingleRow(SQLHelper.selectRowFromTable([uid],
//             sqlTable: SQLConstants.sessionTable,
//             sqlCol: SQLConstants.colSessionId)));
//     inputBreakMin.value = latestSess.value?.breakInterval ?? 5;
//     sessionSecs.value = inputTimeMin.value * 60;
//     timeMinController.jumpToPage(inputTimeMin.value - 1);
//     breakMinController.jumpToPage(inputBreakMin.value - 1);
//     if (routeArgs.value['break'] != null) {
//       updateSession(latestSess,
//           breakNo: ((latestSess.value?.breaks ?? 0) +
//               (int.tryParse(routeArgs.value['break']!.toString()) ?? 0)));
//     }
//     if (routeArgs.value['session'] != null) {
//       updateSession(latestSess,
//           sessionNo: ((latestSess.value?.sessions ?? 0) +
//               (int.tryParse(routeArgs.value['session']!.toString()) ?? 0)));
//     }

//     print(inputBreakMin.value);
//     print(latestSess.value);
//     List<Map<String, Object?>> results = (await _sqlController.rawQuery(
//             SQLHelper.selectTaskIdFromSessId(latestSess.value?.uid ?? -1))) ??
//         [];
//     fetchTasksFromSession(int.tryParse(uid) ?? -1, this.items);
//     update();
//   }

//   int sortSessionMapDate(
//       Map<String, Object?> first, Map<String, Object?> second) {
//     int? firstDate =
//         int.tryParse(first[SQLConstants.colSessionDate].toString());
//     int? secDate = int.tryParse(second[SQLConstants.colSessionDate].toString());
//     if (firstDate == null) {
//       return 1;
//     } else if (secDate == null) {
//       return -1;
//     }
//     int val = firstDate == secDate
//         ? 0
//         : firstDate < secDate
//             ? 1
//             : -1;
//     return val;
//   }

//   Future<void> startBreak(Rx<Timer> timer, RxBool isPaused,
//       Rxn<Session> latestSession, List<DayPlanItem> items) async {
//     if (timer.value.isActive || isPaused.value) {
//       if (!isSession.value) {
//         timer.value.cancel();
//         timer.value = Timer(Duration.zero, () {});
//         initialSecs.value = (inputBreakMin.value * 60);
//         sessionSecs.value = initialSecs.value;
//       }
//       isPaused.value = false;
//     } else {
//       print(latestSession.value);
//       print(inputBreakMin.value);
//       if (latestSess.value?.breakInterval != inputBreakMin.value) {
//         if (latestSess.value?.breaks == 0) {
//           latestSess.value?.breakInterval = inputBreakMin.value;
//         } else {
//           int uid = await createSessionData(latestSess, items,
//                   sessInterval: inputTimeMin.value,
//                   breakInterval: inputBreakMin.value) ??
//               -1;
//           latestSess.value = Session.fromSQFLITEMap(await _sqlController
//               .fetchSingleRow(SQLHelper.selectRowFromTable([uid.toString()],
//                   sqlTable: SQLConstants.sessionTable,
//                   sqlCol: SQLConstants.colSessionId)));
//         }
//       }
//       timer.value.cancel();
//       isSession.value = false;
//       initialSecs.value = (inputBreakMin.value);
//       sessionSecs.value = initialSecs.value;
//       int startTime = DateTime.now().millisecondsSinceEpoch + 500;
//       timerEndTime.value = startTime + (initialSecs.value * 1000);
//       currentNotifId.value = await _notificationsController.scheduleAlarm(
//           "BREAK OVER!",
//           "BREAK'S OVER TIME TO CONTINUE!",
//           DateTime.fromMillisecondsSinceEpoch(timerEndTime.value),
//           payload:
//               "page:0|route:focus|uid:${latestSess.value?.uid ?? -1}|break:1|taskId:${items.map((e) => e.taskId).toList()}");
//       timer.value = Timer.periodic(const Duration(seconds: 1), (_) async {
//         sessionSecs.value -= 1;
//         int now = DateTime.now().millisecondsSinceEpoch;
//         if (((timerEndTime.value - now) / 1000).floor() < sessionSecs.value) {
//           sessionSecs.value = ((timerEndTime.value - now) / 1000).floor();
//         }
//         print(now);
//         print(timerEndTime.value);
//         if (sessionSecs.value == 0 || (now - 500) >= timerEndTime.value) {
//           initialSecs.value = (inputBreakMin.value * 60);
//           sessionSecs.value = initialSecs.value;
//           breakComplete(latestSess, items);
//           timer.value.cancel();
//           update();
//         }
//       });
//     }
//     update();
//   }

//   Future<void> startTimer(Rx<Timer> timer, RxBool isPaused,
//       Rxn<Session> latestSess, List<DayPlanItem> items) async {
//     print("START TIMER");
//     if (timer.value.isActive || isPaused.value) {
//       if (isSession.value) {
//         timer.value.cancel();
//         initialSecs.value = (inputTimeMin.value * 60);
//         sessionSecs.value = initialSecs.value;
//       }
//       isPaused.value = false;
//     } else {
//       if (latestSess.value?.sessInterval != inputTimeMin.value) {
//         if (latestSess.value?.sessions == 0) {
//           latestSess.value?.sessInterval = inputTimeMin.value;
//         } else {
//           int uid = await createSessionData(latestSess, items) ?? -1;
//           latestSess.value = Session.fromSQFLITEMap(await _sqlController
//               .fetchSingleRow(SQLHelper.selectRowFromTable([uid.toString()],
//                   sqlTable: SQLConstants.sessionTable,
//                   sqlCol: SQLConstants.colSessionId)));
//         }
//       }
//       timer.value.cancel();
//       isSession.value = true;
//       initialSecs.value = (inputTimeMin.value * 60);
//       sessionSecs.value = initialSecs.value;
//       int startTime = DateTime.now().millisecondsSinceEpoch + 500;
//       timerEndTime.value = startTime + (initialSecs.value * 1000);
//       currentNotifId.value = await _notificationsController.scheduleAlarm(
//           "SESSION COMPLETE!",
//           "You've FINISHED a WHOLE SESSION OF ${inputTimeMin.value} MINUTE!",
//           DateTime.fromMillisecondsSinceEpoch(timerEndTime.value),
//           payload:
//               "page:0|route:focus|uid:${latestSess.value?.uid ?? -1}|session:1|taskId:${items.map((e) => e.taskId).toList()}");
//       timer.value = Timer.periodic(const Duration(seconds: 1), (_) {
//         sessionSecs.value -= 1;
//         int now = DateTime.now().millisecondsSinceEpoch;
//         if (((timerEndTime.value - now) / 1000).floor() < sessionSecs.value) {
//           sessionSecs.value = ((timerEndTime.value - now) / 1000).floor();
//         }
//         print(now);
//         print(timerEndTime.value);
//         if (sessionSecs.value == 0 || (now - 500) >= timerEndTime.value) {
//           initialSecs.value = (inputTimeMin.value * 60);
//           sessionSecs.value = initialSecs.value;
//           sessionComplete(latestSess, items);
//           timer.value.cancel();
//           update();
//         }
//       });
//     }
//     update();
//   }

//   void pauseTimer(Rx<Timer> timer, RxBool isPaused, int notifUid) {
//     if (timer.value.isActive) {
//       isPaused.value = true;
//       timer.value.cancel();
//       _notificationsController.removeNotification(notifUid);
//     }
//   }

//   Future<void> resumeTimer(Rx<Timer> timer, RxBool isPaused,
//       Rxn<Session> latestSess, List<DayPlanItem> items) async {
//     isPaused.value = false;
//     int startTime = DateTime.now().millisecondsSinceEpoch;
//     timerEndTime.value = startTime + (sessionSecs.value * 1000);
//     currentNotifId.value = await _notificationsController.scheduleAlarm(
//         isSession.value ? "SESSION COMPLETE!" : "BREAK OVER!",
//         isSession.value
//             ? "You've FINISHED a WHOLE SESSION OF ${inputTimeMin.value} MINUTE!"
//             : "BREAK'S OVER TIME TO CONTINUE!",
//         DateTime.fromMillisecondsSinceEpoch(timerEndTime.value));
//     timer.value = Timer.periodic(const Duration(seconds: 1), (_) {
//       sessionSecs.value -= 1;
//       int now = DateTime.now().millisecondsSinceEpoch - 50;
//       print(now);
//       print(timerEndTime.value);
//       if (sessionSecs.value == 0 || now >= timerEndTime.value) {
//         initialSecs.value =
//             ((isSession.value ? inputTimeMin.value : inputBreakMin.value) * 60);
//         sessionSecs.value = initialSecs.value;
//         if (isSession.value) {
//           sessionComplete(latestSess, items)
//               .then((_) => {print(latestSess.value)});
//         } else {
//           breakComplete(latestSess, items)
//               .then((_) => {print(latestSess.value)});
//         }
//         timer.value.cancel();
//       }
//     });
//   }

//   Future<void> sessionComplete(
//       Rxn<Session> session, List<DayPlanItem> items) async {
//     if (session.value != null) {
//       if (session.value!.uid != -1) {
//         session.value!.sessions = (session.value!.sessions ?? 0) + 1;
//         await updateSession(session,
//             date: DateTime.now().millisecondsSinceEpoch);
//         update();
//       }
//     }
//   }

//   Future<void> linkTaskToSession(
//       List<DayPlanItem> items, Session session) async {
//     print(await _sqlController
//         .rawQuery('Select * FROM ${SQLConstants.sessTaskTable}'));
//     for (DayPlanItem item in items) {
//       if (item.task?.uid != null) {
//         SessionTask sessTask = SessionTask.fromDayPlanItem(item, session);
//         await _sqlController.insertObject(sessTask);
//         print(await _sqlController
//             .rawQuery('Select * FROM ${SQLConstants.sessTaskTable}'));
//       }
//     }
//   }

//   Future<void> fetchTasksFromSession(
//       int uid, RxList<DayPlanItem> dayPlanItems) async {
//     List<Map<String, Object?>> taskIds =
//         (await _sqlController.rawQuery(SQLHelper.selectTaskIdFromSessId(uid)) ??
//             []);
//     print(taskIds);
//     if (taskIds.isNotEmpty) {
//       int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
//       List<DayPlanItem> list = _goalsController.dayPlansList[now] ?? [];
//       if (list.isNotEmpty) {
//         dayPlanItems.value =
//             list.where((e) => taskIds.contains(e.taskId ?? -1)).toList();
//       }
//     }
//   }

//   Future<void> breakComplete(
//       Rxn<Session> session, List<DayPlanItem> items) async {
//     if (session.value != null) {
//       if (session.value!.uid != -1) {
//         session.value!.breaks = (session.value!.breaks ?? 0) + 1;
//         await updateSession(session,
//             date: DateTime.now().millisecondsSinceEpoch);
//         update();
//       }
//     }
//   }

//   Future<int?> createSessionData(Rxn<Session> session, List<DayPlanItem> items,
//       {int? sessInterval, int? breakInterval}) async {
//     Session newSession = Session(
//       uid: -1,
//       date: DateTime.now().millisecondsSinceEpoch,
//       sessions: 0,
//       breaks: 0,
//       sessInterval: sessInterval ?? session.value?.sessInterval ?? 30,
//       breakInterval: breakInterval ?? session.value?.breakInterval ?? 5,
//     );
//     print("CREATE");
//     await linkTaskToSession(items, session.value!);
//     return await _sqlController.insertObject(newSession);
//   }

//   Future<int?> updateSession(Rxn<Session> session,
//       {int? date,
//       int? sessInterval,
//       int? breakInterval,
//       int? sessionNo,
//       int? breakNo}) async {
//     Session newSession = Session(
//         uid: session.value?.uid ?? -1,
//         date: date ??
//             session.value?.date ??
//             DateTime.now().millisecondsSinceEpoch,
//         sessInterval: sessInterval ?? session.value?.sessInterval ?? 30,
//         sessions: sessionNo ?? session.value?.sessions ?? 0,
//         breakInterval: breakInterval ?? session.value?.breakInterval ?? 5,
//         breaks: breakNo ?? session.value?.breaks ?? 0);
//     return _sqlController.insertOrUpdateObject(newSession);
//   }
}
