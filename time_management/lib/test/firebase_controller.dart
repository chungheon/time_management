// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart';

// class FirebaseController extends GetxController {
//   final FirebaseMessaging _fbMessaging = FirebaseMessaging.instance;
//   @override
//   void onInit() {
//     // TODO: implement onInit
//     super.onInit();
//   }

//   @pragma('vm:entry-point')
//   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

//     await setupFlutterNotifications();
//     showFlutterNotification(message);
//     // If you're going to use other Firebase services in the background, such as Firestore,
//     // make sure you call `initializeApp` before using other Firebase services.
//     print('Handling a background message ${message.messageId}');
//   }  
// }