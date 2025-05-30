import 'dart:developer';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:muslim/app.dart';
// import 'package:muslim/firebase_options.dart';
import 'package:muslim/init_services.dart';

void main() async {
  await initServices();
  runApp(const App());

  // final connectivityResult = await Connectivity().checkConnectivity();

  // if (connectivityResult == ConnectivityResult.mobile ||
  //     connectivityResult == ConnectivityResult.wifi) {
  //   try {
  //     Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //
  //     final fcmToken = FirebaseMessaging.instance.getToken();
  //     await FirebaseMessaging.instance.setAutoInitEnabled(true);
  //     await FirebaseMessaging.instance.subscribeToTopic("news");
  //     await FirebaseMessaging.instance.subscribeToTopic("support");
  //     log("FCMToken $fcmToken");
  //   } catch (e) {
  //     log(e.toString());
  //   }
  // } else {
  //   log("internet available");
  // }
}
