import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  Future<T?> push<T extends Object?>(Widget route) {
    // rootNavigator:true → يدفع فوق PersistentTabView فيخفي التاب السفلي
    // وزر العداد العالمي مع الشاشات الداخلية (ZikrViewer/Tally/Quran).
    return Navigator.of(this, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) {
          return route;
        },
      ),
    );
  }
}
