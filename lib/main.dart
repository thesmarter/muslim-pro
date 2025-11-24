import 'package:flutter/material.dart';
import 'package:muslim/app.dart';
import 'package:muslim/error_screen.dart';
import 'package:muslim/init_services.dart';

void main() async {
  await initServices();
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      ErrorScreen(details: details);
  runApp(const App());
}
