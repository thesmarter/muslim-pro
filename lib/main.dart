import 'package:flutter/material.dart';
import 'package:muslim/app.dart';
import 'package:muslim/error_screen.dart';
import 'package:muslim/init_services.dart';
import 'package:muslim/src/features/backup_restore/presentation/components/restart_widget.dart';

void main() async {
  await initServices();
  ErrorWidget.builder = (FlutterErrorDetails details) => ErrorScreen(details: details);
  runApp(
    const RestartWidget(
      child: App(),
    ),
  );
}
