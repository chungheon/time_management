// Goals Model - Name, Purpose, Due date, tags, next actionable date, List of tasks
// Tag - Goal, Tag history (task, status, date of status change), tasks under tag, Name,
// Habit (Recurrring Goal) Model - Goal, Repeat 1d/7d/30d.

// ignore_for_file: prefer_adjacent_string_concatenation
import 'package:time_management/constants/sql_constants.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/tag_model.dart';
import 'package:time_management/models/task_model.dart';

class Goal with SQFLiteObject {
  Goal(
      {required this.uid,
      this.name,
      this.purpose,
      List<Tag>? tags,
      this.dueDate}) {
    this.tags = tags ?? [];
  }
  final int? uid;
  String? name;
  String? purpose;
  int? dueDate;
  List<Tag> tags = [];
  List<Task> tasks = [];
  List<Document> documents = [];

  factory Goal.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = int.tryParse(queryResult[SQLConstants.colGoalId].toString());
    String? rName = (queryResult[SQLConstants.colGoalName] ?? '').toString();
    String? rPurpose =
        (queryResult[SQLConstants.colGoalPurpose] ?? '').toString();
    int? rDueDate =
        int.tryParse(queryResult[SQLConstants.colGoalDueDate].toString());
    return Goal(uid: rUid, name: rName, purpose: rPurpose, dueDate: rDueDate);
  }

  void update(Goal newGoal) {
    updateFromSQFLITEMap(newGoal.toMapSQFLITE());
    tags = newGoal.tags;
    tasks = newGoal.tasks;
    documents = newGoal.documents;
    tasks.sort(Task.prioritySort);
  }

  void updateFromSQFLITEMap(Map<String, Object?> queryResult) {
    String? rName = (queryResult[SQLConstants.colGoalName] ?? '').toString();
    String? rPurpose =
        (queryResult[SQLConstants.colGoalPurpose] ?? '').toString();
    int? rDueDate =
        int.tryParse(queryResult[SQLConstants.colGoalDueDate].toString());
    name = rName;
    purpose = rPurpose;
    dueDate = rDueDate;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    if ((uid ?? -1) < 0) {
      return {
        SQLConstants.colGoalName: name,
        SQLConstants.colGoalPurpose: purpose,
        SQLConstants.colGoalDueDate: dueDate,
      };
    }
    return {
      // SQLConstants.colGoalId: uid,
      SQLConstants.colGoalName: name,
      SQLConstants.colGoalPurpose: purpose,
      SQLConstants.colGoalDueDate: dueDate,
    };
  }

  @override
  String objTable() {
    return SQLConstants.goalTable;
  }

  @override
  String toString() {
    return 'Goal{${SQLConstants.colGoalId}: $uid, ${SQLConstants.colGoalName}: $name,' +
        ' ${SQLConstants.colGoalPurpose}: $purpose, tags:$tags, '+ 
        '${SQLConstants.colGoalDueDate}: ${DateTimeHelpers.getDateStr(dueDate)}},' + 'docs: $documents';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Goal && other.name == name && other.uid == uid;
  }

  @override
  int get hashCode => Object.hash(uid, name);
}
