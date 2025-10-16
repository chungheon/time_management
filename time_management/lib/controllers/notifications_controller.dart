import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:time_management/models/routine_model.dart';
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

  Future<void> init(List<Routine> routines) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: selectNotificationStream.add);
    _configureRecievedNotifications();
    setupRoutineNotifications(routines);
  }

  Future<void> setupRoutineNotifications(List<Routine> routines) async {
    flutterLocalNotificationsPlugin.cancelAll();
    idCounter = 0;
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
  }

  Future<void> removeNotification(int uid) async {
    await flutterLocalNotificationsPlugin.cancel(uid);
  }

  void _configureRecievedNotifications() {
    selectNotificationStream.stream
        .listen((NotificationResponse? response) async {
      if (response != null) {
        List<String> payloadSplit = (response.payload ?? "").split("|");
        if (response.payload != null) {
          Get.offAllNamed(
            '/',
            arguments: Map.fromEntries(
              payloadSplit.map<MapEntry<String, String>>((String e) {
                List<String> data = e.split(":");
                if (data.length == 2) {
                  return MapEntry(data[0], data[1]);
                } else {
                  return MapEntry(e, e);
                }
              }),
            ),
          );
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

  Future<List<ActiveNotification>> getActiveNotifications() async {
    List<ActiveNotification> active =
        await flutterLocalNotificationsPlugin.getActiveNotifications();
    return active;
  }

  Future<int> getActiveNotificationsId() async {
    List<ActiveNotification> sortedList = await getActiveNotifications();
    List<int> sortedId = sortedList.map((element) => element.id ?? -1).toList()
      ..sort();
    return sortedList.isEmpty
        ? 2147483647
        : (min(sortedId.first, sortedId.last) - 1);
  }

  // Future<void> scheduleAlarm(String title, String body, DateTime time,
  //     {String? payload}) async {
  //   final AndroidNotificationDetails androidNotificationDetails =
  //       AndroidNotificationDetails(
  //     'Scheduled Alarm',
  //     'Alarm',
  //     channelDescription: 'Alarms that are scheduled to show once',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     when: time.millisecondsSinceEpoch,
  //   );
  //   final NotificationDetails notificationDetails =
  //       NotificationDetails(android: androidNotificationDetails);
  //   await flutterLocalNotificationsPlugin.show(
  //       await getActiveNotificationsId(), title, body, notificationDetails,
  //       payload: payload);
  // }

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
        date.day, date.hour, date.minute, date.second).subtract(date.timeZoneOffset);
    int id = ++idCounter;
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
