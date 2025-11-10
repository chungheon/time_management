import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/routine_controller.dart';
import 'package:time_management/controllers/session_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/routine_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/focus_page.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsController extends GetxController {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('background');
  static const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  static const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  static const InitializationSettings initializationSettings =
      InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
          linux: initializationSettingsLinux);
  final StreamController<NotificationResponse> selectNotificationStream =
      StreamController<NotificationResponse>.broadcast();
  int idCounter = 0;

  Future<void> init(RoutineController routineController,
      GoalsController goalsController) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: selectNotificationStream.add);
    _configureRecievedNotifications();
  }

  Future<void> refreshNotifications(RoutineController routineController,
      GoalsController goalsController) async {
    int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
    setupRoutineNotifications(
        routineController.routineList, goalsController.dayPlansList[now] ?? []);
  }

  Future<void> showNotificationInstant(String title, String body) async {
    flutterLocalNotificationsPlugin.show(
        await getActiveNotificationsId(),
        title,
        body,
        const NotificationDetails(
            android: AndroidNotificationDetails(
          "Pomodoro",
          "Pomodoro",
          channelDescription: 'For Pomodoro Tracking',
          importance: Importance.max,
          priority: Priority.max,
          onlyAlertOnce: true,
        )));
  }

  Future<void> setupRoutineNotifications(
      List<Routine> routines, List<DayPlanItem> todayPlanItems) async {
    flutterLocalNotificationsPlugin.cancelAll();
    for (var routine in routines) {
      try {
        if ((routine.seq ?? -1) < 4) {
          scheduleRoutine(routine);
        }
        // } else if ((routine.seq ?? -1) == 4 &&
        //     routine.endDate != null &&
        //     DateTime.now().millisecondsSinceEpoch < routine.endDate!) {
        //   scheduleAlarm(routine.name ?? "", routine.desc ?? "",
        //       DateTime.fromMillisecondsSinceEpoch(routine.endDate!));
        // }
      } on Exception {
        // Ignore for now
      }
    }
    for (var dayItem in todayPlanItems) {
      try {
        if (dayItem.task != null && dayItem.task!.alertTime != null) {
          Task task = dayItem.task!;

          DateTime alertTime = DateTime.now().dateOnly();
          DateTime now = DateTime.now();
          TimeOfDay alert = TimeOfDay.fromDateTime(
              DateTime.fromMillisecondsSinceEpoch(task.alertTime!));
          int time = alert.hour * 60 * 60 * 1000 + alert.minute * 60 * 1000;
          alertTime = alertTime.add(Duration(milliseconds: time));
          if (now.isBefore(alertTime)) {
            scheduleAlarm(
                alert.hour.toString().padLeft(2, '0') +
                    ":" +
                    alert.minute.toString().padLeft(2, '0') +
                    " " +
                    StringConstants
                        .taskPriorities[dayItem.taskPriority?.index ?? 0]
                        .toUpperCase(),
                task.task ?? "",
                alertTime);
          }
        }
      } on Exception {
        // Ignore for now
      }
    }
  }

  Future<void> removeNotification(int uid) async {
    await flutterLocalNotificationsPlugin.cancel(uid);
  }

  void _configureRecievedNotifications() {
    selectNotificationStream.stream
        .listen((NotificationResponse? response) async {
      if (response != null) {
        List<String> payloadSplit = (response.payload ?? "").split("|");
        Map<String, String> args = Map.fromEntries(
            payloadSplit.map<MapEntry<String, String>>((String e) {
          List<String> data = e.split(":");
          if (data.length == 2) {
            return MapEntry(data[0], data[1]);
          } else {
            return MapEntry(e, e);
          }
        }));
        if (response.payload != null) {
          if (args['route'] != null) {
            Get.offAllNamed(
              '/',
            );
            switch (args['route']) {
              case 'focus':
                Get.lazyPut(() => SessionController());
                Get.to(() => FocusPage(), arguments: args);
            }
          } else {
            Get.offAllNamed(
              '/',
              arguments: args,
            );
          }
        }
      }
    });
  }

  Future<int> requestPermission() async {
    bool notification = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
    bool exactAlarm = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission() ??
        false;
    return (exactAlarm ? 1 : 0) + (notification ? 2 : 0);
  }

  Future<List<PendingNotificationRequest>> getActiveNotifications() async {
    List<PendingNotificationRequest> active =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return active;
  }

  Future<int> getActiveNotificationsId() async {
    List<PendingNotificationRequest> sortedList =
        await getActiveNotifications();
    List<int> sortedId = sortedList.map((element) => element.id).toList()
      ..sort();
    return sortedList.isEmpty
        ? 2147483647
        : (min(sortedId.first, sortedId.last) - 1);
  }

  Future<int> scheduleAlarm(String title, String body, DateTime time,
      {String? payload}) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('Scheduled Alarm', 'Alarm',
            channelDescription: 'Alarms that are scheduled to show once',
            importance: Importance.max,
            priority: Priority.high,
            onlyAlertOnce: true,
            when: time.millisecondsSinceEpoch);
    DateTime date = time;
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, date.year, date.month,
            date.day, date.hour, date.minute, date.second)
        .subtract(date.timeZoneOffset);
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    int id = await getActiveNotificationsId();
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    return id;
  }

  Future<int> scheduleRoutine(Routine routine, {String? payload}) async {
    DateTimeComponents schedule;
    String channelData;
    switch (routine.seq) {
      //Daily
      case 0:
      case 5:
        schedule = DateTimeComponents.time;
        channelData = 'Daily Routine';
        break;
      //Weekly
      case 1:
      case 6:
        schedule = DateTimeComponents.dayOfWeekAndTime;
        channelData = 'Weekly Routine';
        break;
      //Monthly
      case 2:
      case 7:
        schedule = DateTimeComponents.dayOfMonthAndTime;
        channelData = 'Monthly Routine';
        break;
      //Yearly
      case 3:
      case 8:
        schedule = DateTimeComponents.dateAndTime;
        channelData = 'Yearly Routine';
        break;
      default:
        throw Exception("Invalid Sequence");
    }
    DateTime date = DateTime.fromMillisecondsSinceEpoch(routine.endDate ?? 0);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, date.year, date.month,
            date.day, date.hour, date.minute, date.second)
        .subtract(date.timeZoneOffset);
    int id = await getActiveNotificationsId();
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        routine.name,
        routine.desc,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'Routine',
            channelData,
            channelDescription: channelData,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: schedule,
      );
    } on Exception {
      rethrow;
    }
    return id;
  }
}
