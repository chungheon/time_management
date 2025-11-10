import 'package:time_management/constants/sql_constants.dart';

class Session with SQFLiteObject {
  Session({
    required this.uid,
    this.date,
    this.breakCount,
    this.breakInterval,
  });
  final int? uid;
  int? date;
  int? breakCount;
  int? breakInterval;

  List<SessionCounter> linked = [];

  factory Session.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = int.tryParse(queryResult[SQLConstants.colSessionId].toString());
    if (rUid == null) {
      throw Exception("Unable to create Session Object");
    }
    int? rDate =
        int.tryParse(queryResult[SQLConstants.colSessionDate].toString());
    int? rBreakNo =
        int.tryParse(queryResult[SQLConstants.colSessionBreak].toString());
    int? rBreakInterval = int.tryParse(
        queryResult[SQLConstants.colSessionBreakInterval].toString());

    return Session(
      uid: rUid,
      date: rDate,
      breakCount: rBreakNo,
      breakInterval: rBreakInterval,
    );
  }

  void updateFromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rDate =
        int.tryParse(queryResult[SQLConstants.colSessionDate].toString());
    int? rBreakNo =
        int.tryParse(queryResult[SQLConstants.colSessionBreak].toString());
    int? rBreakInterval = int.tryParse(
        queryResult[SQLConstants.colSessionBreakInterval].toString());
    date = rDate;
    breakCount = rBreakNo;
    breakInterval = rBreakInterval;
  }

  void update({
    int? uid,
    int? date,
    int? breakCount,
    int? breakInterval,
  }) {
    this.date = date ?? this.date;
    this.breakCount = breakCount ?? this.breakCount;
    this.breakInterval = breakInterval ?? this.breakInterval;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if ((uid ?? -1) < 0) {
      return {
        SQLConstants.colSessionDate: date,
        SQLConstants.colSessionBreak: breakCount,
        SQLConstants.colSessionBreakInterval: breakInterval,
      };
    }
    return {
      SQLConstants.colSessionId: uid,
      SQLConstants.colSessionDate: date,
      SQLConstants.colSessionBreak: breakCount,
      SQLConstants.colSessionBreakInterval: breakInterval,
    };
  }

  @override
  String objTable() {
    return SQLConstants.sessionTable;
  }

  @override
  String toString() {
    // ignore: prefer_adjacent_string_concatenation
    return 'Session{${SQLConstants.colSessionId}: $uid, ${SQLConstants.colSessionDate} : $date, ' +
        '${SQLConstants.colSessionBreak}: $breakCount, ${SQLConstants.colSessionBreakInterval}: $breakInterval, linked: $linked}';
  }
}

class SessionCounter with SQFLiteObject {
  SessionCounter(
      {required this.sessId, this.sessionCount, this.sessionInterval});
  int sessId;
  int? sessionCount;
  int? sessionInterval;

  factory SessionCounter.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rsSessId = int.tryParse(
        queryResult[SQLConstants.colSessionCounterSessId].toString());
    int? rSessNo = int.tryParse(
        queryResult[SQLConstants.colSessionCounterSessNo].toString());
    int? rSessInterval = int.tryParse(
        queryResult[SQLConstants.colSessionCounterSessInterval].toString());
    return SessionCounter(
      sessId: rsSessId ?? -1,
      sessionCount: rSessNo ?? 0,
      sessionInterval: rSessInterval ?? 30,
    );
  }

  @override
  String objTable() {
    return SQLConstants.sessionCounterTable;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    return {
      SQLConstants.colSessionCounterSessId: sessId,
      SQLConstants.colSessionCounterSessNo: sessionCount,
      SQLConstants.colSessionCounterSessInterval: sessionInterval
    };
  }

  @override
  String toString() {
    // ignore: prefer_adjacent_string_concatenation
    return 'Session{${SQLConstants.colSessionCounterSessId}: $sessId, ${SQLConstants.colSessionCounterSessNo}: $sessionCount, ' +
        '${SQLConstants.colSessionCounterSessInterval}: $sessionInterval}';
  }
}
