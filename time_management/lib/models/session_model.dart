import 'package:time_management/constants/sql_constants.dart';

class Session with SQFLiteObject {
  Session({
    required this.uid,
    this.date,
    this.sessions,
    this.breaks,
    this.sessInterval,
    this.breakInterval,
  });
  final int? uid;
  int? date;
  int? sessions;
  int? breaks;
  int? sessInterval;
  int? breakInterval;
  List<int> linked = [];

  factory Session.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = int.tryParse(queryResult[SQLConstants.colSessionId].toString());
    int? rDate =
        int.tryParse(queryResult[SQLConstants.colSessionDate].toString());
    int? rSessions =
        int.tryParse(queryResult[SQLConstants.colSessionNo].toString());
    int? rBreaks =
        int.tryParse(queryResult[SQLConstants.colSessionBreak].toString());
    int? rSessInterval =
        int.tryParse(queryResult[SQLConstants.colSessionInterval].toString());
    int? rBreakInterval = int.tryParse(
        queryResult[SQLConstants.colSessionBreakInterval].toString());

    return Session(
      uid: rUid,
      date: rDate,
      sessions: rSessions,
      sessInterval: rSessInterval,
      breaks: rBreaks,
      breakInterval: rBreakInterval,
    );
  }

  void updateFromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rDate =
        int.tryParse(queryResult[SQLConstants.colSessionDate].toString());
    int? rSessions =
        int.tryParse(queryResult[SQLConstants.colSessionNo].toString());
    int? rBreaks =
        int.tryParse(queryResult[SQLConstants.colSessionBreak].toString());
    int? rSessInterval =
        int.tryParse(queryResult[SQLConstants.colSessionInterval].toString());
    int? rBreakInterval = int.tryParse(
        queryResult[SQLConstants.colSessionBreakInterval].toString());
    date = rDate;
    sessions = rSessions;
    breaks = rBreaks;
    sessInterval = rSessInterval;
    breakInterval = rBreakInterval;
  }

  void update({
    int? uid,
    int? date,
    int? sessions,
    int? breaks,
    int? sessInterval,
    int? breakInterval,
  }) {
    this.date = date ?? this.date;
    this.sessions = sessions ?? this.sessions;
    this.breaks = breaks ?? this.breaks;
    this.sessInterval = sessInterval ?? this.sessInterval;
    this.breakInterval = breakInterval ?? this.breakInterval;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if ((uid ?? -1) < 0) {
      return {
        SQLConstants.colSessionDate: date,
        SQLConstants.colSessionNo: sessions,
        SQLConstants.colSessionBreak: breaks,
        SQLConstants.colSessionInterval: sessInterval,
        SQLConstants.colSessionBreakInterval: breakInterval,
      };
    }
    return {
      SQLConstants.colSessionId: uid,
      SQLConstants.colSessionDate: date,
      SQLConstants.colSessionNo: sessions,
      SQLConstants.colSessionBreak: breaks,
      SQLConstants.colSessionInterval: sessInterval,
      SQLConstants.colSessionBreakInterval: breakInterval,
    };
  }

  @override
  String objTable() {
    return SQLConstants.docTable;
  }

  @override
  String toString() {
    // ignore: prefer_adjacent_string_concatenation
    return 'Session{${SQLConstants.colSessionId}: $uid, ${SQLConstants.colSessionNo}: $sessions,' +
        ' ${SQLConstants.colSessionBreak}: $breaks, ${SQLConstants.colSessionInterval}: $sessInterval,' +
        ' ${SQLConstants.colSessionBreakInterval}: $breakInterval, linked: $linked}';
  }
}
