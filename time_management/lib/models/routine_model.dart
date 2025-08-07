import 'package:time_management/constants/sql_constants.dart';

//Seq - sequence each value represents a different frequency of the routine
// 0 - every day
// 1 - every week specific day
// 2 - every month
// 3 - every year
// 4 - alarm once
class Routine with SQFLiteObject {
  Routine({
    required this.uid,
    required this.seq,
    this.name,
    this.desc,
    this.startDate,
    this.endDate,
  });
  final int? uid;
  final int? seq;
  String? name;
  String? desc;
  int? startDate;
  int? endDate;

  factory Routine.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = int.tryParse(queryResult[SQLConstants.colRoutineId].toString());
    int? rSeq = queryResult[SQLConstants.colRoutineSeq] as int?;
    String? rName = (queryResult[SQLConstants.colRoutineName] ?? '').toString();
    String? rDesc = (queryResult[SQLConstants.colRoutineDesc] ?? '').toString();
    int? rStartDate = queryResult[SQLConstants.colRoutineStart] as int?;
    int? rEndDate = queryResult[SQLConstants.colRoutineEnd] as int?;
    return Routine(
      uid: rUid,
      seq: rSeq,
      name: rName,
      desc: rDesc,
      startDate: rStartDate,
      endDate: rEndDate,
    );
  }

  @override
  String objTable() {
    return SQLConstants.routineTable;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if (uid != null && uid! > 0) {
      return {
        SQLConstants.colRoutineId: uid,
        SQLConstants.colRoutineName: name,
        SQLConstants.colRoutineDesc: desc,
        SQLConstants.colRoutineSeq: seq,
        SQLConstants.colRoutineStart: startDate,
        SQLConstants.colRoutineEnd: endDate,
      };
    }
    return {
      SQLConstants.colRoutineName: name,
      SQLConstants.colRoutineDesc: desc,
      SQLConstants.colRoutineSeq: seq,
      SQLConstants.colRoutineStart: startDate,
      SQLConstants.colRoutineEnd: endDate,
    };
  }
}
