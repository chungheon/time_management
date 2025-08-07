import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/models/goal_model.dart';

class Tag with SQFLiteObject {
  Tag({required this.uid, required this.goalUid, this.name, this.goal});
  final int? uid;
  final int? goalUid;
  String? name = '';
  Goal? goal;

  factory Tag.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = int.tryParse(queryResult[SQLConstants.colTagId].toString());
    String? rName = (queryResult[SQLConstants.colTagName] ?? '').toString();
    int rGoalUid = queryResult[SQLConstants.colTagGoalId]! as int;
    return Tag(uid: rUid, goalUid: rGoalUid, name: rName);
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if ((uid ?? -1) < 0) {
      return {
        SQLConstants.colTagGoalId: goalUid,
        SQLConstants.colTagName: name,
      };
    }
    return {
      SQLConstants.colTagId: uid,
      SQLConstants.colTagGoalId: goalUid,
      SQLConstants.colTagName: name,
    };
  }

  @override
  String objTable() {
    return SQLConstants.tagTable;
  }

  @override
  String toString() {
    return 'Tag{${SQLConstants.colTagId}: $uid,${SQLConstants.colTagGoalId}: $goalUid, ${SQLConstants.colTagName}: $name}';
  }
}

class TagHistory {
  int? tagHistoryId;
  String? action;
  int? taskTagHistoryId;
  int? date;

  @override
  String toString() {
    return 'TagHistory{${SQLConstants.colTagId}: $tagHistoryId,${SQLConstants.colTagGoalId}: $action, ${SQLConstants.colTagName}: $date, $taskTagHistoryId}';
  }
}
