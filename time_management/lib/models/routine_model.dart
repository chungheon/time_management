import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/helpers/date_time_helpers.dart';

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
    int? rSeq =
        int.tryParse(queryResult[SQLConstants.colRoutineSeq].toString());
    String? rName = (queryResult[SQLConstants.colRoutineName] ?? '').toString();
    String? rDesc = (queryResult[SQLConstants.colRoutineDesc] ?? '').toString();
    int? rStartDate =
        int.tryParse(queryResult[SQLConstants.colRoutineStart].toString());
    int? rEndDate =
        int.tryParse(queryResult[SQLConstants.colRoutineEnd].toString());
    return Routine(
      uid: rUid,
      seq: rSeq,
      name: rName,
      desc: rDesc,
      startDate: rStartDate,
      endDate: rEndDate,
    );
  }

  static int sortByTime(Routine a, Routine b) {
        DateTime dateA = DateTime.fromMillisecondsSinceEpoch(a.endDate ?? 0);
        DateTime dateB = DateTime.fromMillisecondsSinceEpoch(b.endDate ?? 0);
        return (dateA.millisecondsSinceEpoch -
                    dateA.dateOnly().millisecondsSinceEpoch) >=
                (dateB.millisecondsSinceEpoch -
                    dateB.dateOnly().millisecondsSinceEpoch)
            ? 1
            : -1;
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
