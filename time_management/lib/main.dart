import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/controllers/document_viewer_controller.dart';
import 'package:time_management/controllers/goal_view_controller.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/notifications_controller.dart';
import 'package:time_management/controllers/routine_controller.dart';
import 'package:time_management/controllers/session_controller.dart';
import 'package:time_management/controllers/shared_preferences_controller.dart';
import 'package:time_management/controllers/sql_controller.dart';
import 'package:time_management/controllers/view_controller.dart';
import 'package:time_management/screens/home_page.dart';
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  await flutterInit();
  runApp(const StateContainer(child: MainApp()));
}

//All required initialization for the app
Future<void> flutterInit() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  tzd.initializeTimeZones();
  tz.Location location = tz.getLocation('GMT');
  tz.setLocalLocation(location);
}

//Initialize SQLFlite, setup all the databases
Future<void> initSQL() async {
  SQLController controller = SQLController();
  Get.put(controller, permanent: true);
  await controller.init();
}

//Initialize Notifications
Future<void> initNotifications() async {
  NotificationsController notificationsController = NotificationsController();
  RoutineController routineController = RoutineController();
  GoalsController goalsController = GoalsController();
  SharedPreferencesController sharedPreferencesController =
      SharedPreferencesController();
  Get.put(routineController, permanent: true);
  Get.put(notificationsController, permanent: true);
  Get.put(goalsController, permanent: true);
  Get.put(sharedPreferencesController, permanent: true);
  await routineController.init();
  notificationsController.init(routineController, goalsController);
}

//Create all controllers that REQUIRE initialization and whole lifecycle before removing splash screen
Future<void> initialization() async {
  initSQL();
  initNotifications();
  Get.lazyPut(() => DocumentViewerController(), fenix: true);
  Get.lazyPut(() => GoalViewController(), fenix: true);
  Get.lazyPut(() => ViewController(), fenix: true);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        //All initialization of controllers done in initialization function
        initialization();
      }),
      builder: (context, widget) {
        return SafeArea(
            child: GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: widget!));
      },
      initialRoute: "/",
      getPages: [GetPage(name: '/', page: () => const HomePage())],
    );
  }
}
