import 'package:time_management/constants/sql_constants.dart';

class ChecklistItem with SQFLiteObject {
  ChecklistItem(
      {required this.uid, required this.date, required this.routineUid});
  final int uid;
  final int date;
  final int routineUid;

  factory ChecklistItem.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int rUid =
        int.tryParse(queryResult[SQLConstants.colChecklistId].toString()) ?? -1;
    int rDate =
        int.tryParse(queryResult[SQLConstants.colChecklistDate].toString()) ??
            -1;
    int rRoutineId = int.tryParse(
            queryResult[SQLConstants.colChecklistRoutineId].toString()) ??
        -1;
    return ChecklistItem(uid: rUid, date: rDate, routineUid: rRoutineId);
  }

  @override
  String objTable() {
    return SQLConstants.checklistTable;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if (uid < 0) {
      return {
        SQLConstants.colChecklistDate: date,
        SQLConstants.colChecklistRoutineId: routineUid,
      };
    }

    return {
      SQLConstants.colChecklistId: uid,
      SQLConstants.colChecklistDate: date,
      SQLConstants.colChecklistRoutineId: routineUid,
    };
  }
}
