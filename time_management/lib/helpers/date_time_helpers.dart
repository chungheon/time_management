import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_management/constants/date_time_constants.dart';

class DateTimeHelpers {
  static int getDayValue(DateTime time) {
    DateTime gmtTime = DateTime.fromMillisecondsSinceEpoch(
        DateTimeConstants.monTimeStampGMT,
        isUtc: true);

    int timeDiff =
        (gmtTime.millisecondsSinceEpoch - time.millisecondsSinceEpoch).abs();
    double timeDiffSeconds = timeDiff / 1000;
    int days = (timeDiffSeconds / DateTimeConstants.secsADay).floor();
    return days % 7;
  }

  static List<String> dateFormats = ['dd/MM/yy', 'dd/MM/yyyy'];

  static DateTime? tryParse(
    String dateTimeStr, {
    bool utc = false,
  }) {
    var dtSplit = dateTimeStr.split('/');
    for (var format in dateFormats) {
      try {
        var dt = DateFormat(format).tryParse(dateTimeStr, utc);
        if (dt?.month != null && dt?.month != int.tryParse(dtSplit[1])) {
          throw Exception;
        }
        if (dtSplit[2].length > 4) {
          throw Exception;
        }

        return dt;
      } on FormatException {
        // Ignore.
      } catch (e) {
        //Ignore
      }
    }

    return DateTime.tryParse(dateTimeStr);
  }

  static String getFormattedDate(DateTime date, {String? dateFormat}) {
    return DateFormat(dateFormat ?? "dd/MM/yy").format(date);
  }

  static int getDayDifference(DateTime currDate, DateTime futureDate) {
    var diffDay =
        ((currDate.millisecondsSinceEpoch - futureDate.millisecondsSinceEpoch) /
            1000 /
            86400);
    if (diffDay < 0) {
      return diffDay.abs().floor() * -1;
    } else {
      return diffDay.floor();
    }
  }

  static getDateStr(int? date, {String? dateFormat}) {
    if (date == null) {
      return 'Error';
    } else {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(date);
      return DateTimeHelpers.getFormattedDate(dateTime, dateFormat: dateFormat);
    }
  }

  static Map<String, int> getDifferenceMap(
      DateTime currDate, DateTime futureDate) {
    int dayDiff = getDayDifference(futureDate, currDate);
    int yrDiff = (dayDiff / 365.25).abs().floor();
    int mthDiff = (dayDiff / 30.44).abs().floor();
    if (yrDiff != 0) {
      mthDiff = ((dayDiff.abs() % 365.25) / 30.44).abs().floor();
    }
    if (yrDiff > 0 || mthDiff > 0) {
      int tempDiff = dayDiff.abs();
      tempDiff -= (mthDiff * 30.44).floor() + (yrDiff * 365.25).floor();
      if (dayDiff < 0) {
        dayDiff = tempDiff * -1;
      } else {
        dayDiff = tempDiff;
      }
    }
    return {
      'y': yrDiff,
      'm': mthDiff,
      'd': (dayDiff),
    };
  }

  static String getDifferenceStr(DateTime currDate, DateTime futureDate) {
    Map<String, int> diffMap = getDifferenceMap(currDate, futureDate);
    if (diffMap['d'] == null) {
      return '';
    }
    if ((diffMap['d'] ?? 0) == 0) {
      return 'Due Today';
    }
    String dueStr = 'Due in';
    if ((diffMap['d'] ?? 0) < 0) {
      dueStr = 'Overdue by ';
      diffMap["d"] = diffMap["d"]!.abs();
    }

    if (diffMap['y'] != null && diffMap['y']! > 0) {
      dueStr += ' ${diffMap["y"]}Y';
    }
    if (diffMap['m'] != null && diffMap['m']! > 0) {
      dueStr += ' ${diffMap["m"]}M';
    }
    if (diffMap['d'] != null) {
      var dayDiff = diffMap["d"];
      dueStr += ' ${dayDiff}D';
    }

    return dueStr;
  }
}

extension Date on DateTime {
  DateTime dateOnly() {
    return DateTime(year, month, day);
  }
}

extension DateFormatTryParse on DateFormat {
  DateTime? tryParse(String inputString, [bool utc = false]) {
    try {
      return parse(inputString, utc);
    } on FormatException {
      return null;
    }
  }
}

extension TimeFormatTryParse on TimeOfDay {
  TimeOfDay? tryParse(String inputString) {
    try {
      List<String> timeSplit = inputString.split(":");
      if (timeSplit.length == 2) {
        int? hourVal = int.tryParse(timeSplit[0]);
        int? minuteVal = int.tryParse(timeSplit[1]);
        if (hourVal == null ||
            hourVal > 24 ||
            hourVal < 0 ||
            minuteVal == null ||
            minuteVal > 60 ||
            minuteVal < 0) {
          return null;
        } else {
          return TimeOfDay(hour: hourVal, minute: minuteVal);
        }
      }
      return null;
    } on Exception {
      return null;
    }
  }
}

extension StringFormatTime on TimeOfDay {
  String timeFormat() {
    return "${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}";
  }
}
