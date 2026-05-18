import 'package:flutter/widgets.dart';

class AppComponent {
  final String id;
  final String Function(BuildContext context) title;
  final Widget widget;

  const AppComponent({
    required this.id,
    required this.title,
    required this.widget,
  });
}
