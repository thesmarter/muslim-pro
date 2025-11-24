import 'package:muslim/app.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/functions/print.dart';

class SX {
  static late final S _s;
  // ignore: use_setters_to_change_properties
  static void init(S s) {
    _s = s;
  }

  static S get current {
    final context = App.navigatorKey.currentState?.context;
    if (context == null) {
      hisnPrint("Localization access before context ready");
      return _s;
    }

    return S.of(context);
  }
}
