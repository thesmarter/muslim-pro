import 'package:intl/intl.dart';
import 'package:muslim/src/core/values/constant.dart';

extension DateTimeExt on DateTime {
  String get humanize {
    return DateFormat(kDateTimeHumanFormat).format(this);
  }
}
