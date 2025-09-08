// ignore_for_file: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

mixin SQFLiteObject {
  Map<String, dynamic> toMapSQFLITE();
  String objTable();
}

class SQLConstants {
  static const List<List<String>> upgrades = [
    [
      'ALTER TABLE ' +
          SQLConstants.taskTable +
          ' ADD COLUMN ' +
          SQLConstants.colTaskAlertTime +
          ' INTEGER'
    ]
  ];
  static const String createGoalsTable =
      'CREATE TABLE IF NOT EXISTS $goalTable($colGoalId INTEGER PRIMARY KEY, $colGoalName TEXT,' +
          ' $colGoalPurpose TEXT, $colGoalDueDate INTEGER);';

  static const String createRoutineTable =
      'CREATE TABLE IF NOT EXISTS $routineTable($colRoutineId INTEGER PRIMARY KEY, $colRoutineName TEXT,' +
          ' $colRoutineDesc TEXT, $colRoutineStart INTEGER, $colRoutineEnd INTEGER, $colRoutineSeq INT1 NOT NULL);';

  static const String createChecklistTable =
      'CREATE TABLE IF NOT EXISTS $checklistTable($colChecklistId INTEGER PRIMARY KEY, $colChecklistDate INTEGER NOT NULL, ' +
          '$colChecklistRoutineId INTEGER, ' +
          'CONSTRAINT $checklistFKRoutine ' +
          'FOREIGN KEY ($colChecklistRoutineId) ' +
          'REFERENCES $routineTable($colRoutineId) ' +
          'ON DELETE CASCADE)';

  static const String insertDefaultGoal =
      'INSERT OR IGNORE INTO $goalTable($colGoalId, $colGoalName, $colGoalPurpose) ' +
          'VALUES(1, "Impromptu Tasks","Re-catagorize all tasks that have been added here temporarily.");';

  static const String createTagsTable =
      'CREATE TABLE IF NOT EXISTS $tagTable($colTagId INTEGER PRIMARY KEY, ' +
          '$colTagName TEXT, ' +
          '$colTagGoalId INTEGER,' +
          'CONSTRAINT $tagFKGoal ' +
          'FOREIGN KEY ($colTagGoalId) ' +
          'REFERENCES $goalTable($colGoalId)' +
          ' ON DELETE CASCADE);';

  static const String createDayPlanTable =
      'CREATE TABLE IF NOT EXISTS $dayPlanTable($colDayPlanId INTEGER PRIMARY KEY, ' +
          '$colDayPlanTaskId INTEGER, ' +
          '$colDayPlanPriority INTEGER,' +
          '$colDayPlanDate INTEGER NOT NULL,' +
          'UNIQUE ($colDayPlanTaskId, $colDayPlanDate)'
              'CONSTRAINT $dayPlanFKTask ' +
          'FOREIGN KEY ($colDayPlanTaskId) ' +
          'REFERENCES $taskTable($colTaskId)' +
          ' ON DELETE CASCADE);';

  static const String createTagHistoryTable =
      'CREATE TABLE IF NOT EXISTS $tagHistoryTable($colTagHistoryId INTEGER PRIMARY KEY, ' +
          '$colTagHistoryAction TEXT, $colTagHistoryDate INTEGER NOT NULL,' +
          '$colTagHistoryTaskTagHistoryId INTEGER,' +
          '$colTagHistoryTagId INTEGER,' +
          'CONSTRAINT $tagHistoryFKTag ' +
          'FOREIGN KEY ($colTagHistoryTagId) ' +
          'REFERENCES $tagTable($colTagId)' +
          ' ON DELETE CASCADE);';

  static const String createTaskTable =
      'CREATE TABLE IF NOT EXISTS $taskTable($colTaskId INTEGER PRIMARY KEY, ' +
          '$colTaskTask TEXT,  $colTaskActionDate INTEGER,' +
          '$colTaskStatus INTEGER,' +
          '$colTaskGoalId INTEGER,' +
          '$colTaskCompletionDate INTEGER,' +
          'CONSTRAINT $taskFKGoal ' +
          'FOREIGN KEY ($colTaskGoalId) ' +
          'REFERENCES $goalTable($colGoalId)' +
          ' ON DELETE CASCADE);';

  static const String createDocumentTable =
      'CREATE TABLE IF NOT EXISTS $docTable($colDocId INTEGER PRIMARY KEY, ' +
          '$colDocPath TEXT, $colDocType SMALL INT, $colDocDesc TEXT, $colDocGoalId INTEGER, ' +
          'CONSTRAINT $docFKGoal ' +
          'FOREIGN KEY ($colDocGoalId) ' +
          'REFERENCES $goalTable($colGoalId)' +
          ' ON DELETE CASCADE)';

  static const String createDocumentTaskTable =
      'CREATE TABLE IF NOT EXISTS $docTaskTable($colDocTaskDocId INTEGER NOT NULL, ' +
          '$colDocTaskTaskId INTEGER NOT NULL, ' +
          'UNIQUE ($colDocTaskDocId, $colDocTaskTaskId), ' +
          'CONSTRAINT $docTaskDocFK ' +
          'FOREIGN KEY ($colDocTaskDocId) ' +
          'REFERENCES $docTable($colDocId)' +
          ' ON DELETE CASCADE, ' +
          'CONSTRAINT $docTaskTaskFK '
              'FOREIGN KEY ($colDocTaskTaskId) ' +
          'REFERENCES $taskTable($colTaskId)' +
          ' ON DELETE CASCADE)';

  static const String selectAllGoalsStmt =
      "SELECT * FROM ${SQLConstants.goalTable} ORDER BY ${SQLConstants.colGoalId}";

  static const String mainDatabaseAlias = "main_db";

  /*Goals Table*/
  static const String goalTable = "goals";
  //Primary Key - UID int
  static const String colGoalId = "uid";

  //Type - String
  static const String colGoalName = "name";
  static const String colGoalPurpose = "purpose";

  //Type - Int
  static const String colGoalDueDate = "due_date";

  //List of all Manual goal table columns
  static const List<String> goalCols = [
    colGoalName,
    colGoalPurpose,
    colGoalDueDate
  ];

  /*
    Routine Table
    NON NULL colRoutineSeq
  */
  static const String routineTable = "routines";
  //Primary Key - UID int
  static const String colRoutineId = "uid";

  //Type - String
  static const String colRoutineName = "name";
  static const String colRoutineDesc = "desc";

  //Type - Int
  static const String colRoutineStart = "start_time";
  static const String colRoutineEnd = "end_time";

  //Type -INT1 -128 to 127
  static const String colRoutineSeq = "sequence";

  //List of all Manual routine table columns
  static const List<String> routineCols = [
    colRoutineName,
    colRoutineDesc,
    colRoutineStart,
    colRoutineEnd,
    colRoutineSeq,
  ];

  /*
    Checklist Table
    NON NULL colChecklistDate
  */
  static const String checklistTable = "checklist";

  //Primary Key - UID int
  static const String colChecklistId = "uid";
  //Constraints
  static const String checklistFKRoutine = "fk_routine";

  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colChecklistRoutineId = "routine_uid";

  //Type - Int
  static const String colChecklistDate = "date";

  //List of all Manual goal table columns
  static const List<String> checklistCols = [
    colChecklistDate,
    colChecklistRoutineId,
  ];

  /*Tags Table 
  NON NULL colTagGoalId
  */
  static const String tagTable = "tags";
  //Primary Key - UID int
  static const String colTagId = "uid";
  //Constraints
  static const String tagFKGoal = "fk_goal";

  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colTagGoalId = "goal_uid";

  //Type - String
  static const String colTagName = "name";

  //List of all Manual tags table columns
  static const List<String> tagCols = [
    colTagName,
    colTagGoalId,
  ];

  /*Tag History Table
      taskId linked to action
      NON-NULL colTagHistoryId, colTagHistoryTagId, colTagHistoryDate
  */
  static const String tagHistoryTable = "tags_history";
  //Primary Key - UID int
  static const String colTagHistoryId = "uid";
  //Constraints
  static const String tagHistoryFKTag = "fk_tag";

  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colTagHistoryTagId = "tag_uid";

  //Type - String
  static const String colTagHistoryAction = "action";

  //Type - int
  static const String colTagHistoryTaskTagHistoryId = "task_tag_history_id";
  static const String colTagHistoryDate = "date";

  //List of all Manual tags history table columns
  static const List<String> tagHistoryCols = [
    colTagHistoryAction,
    colTagHistoryDate,
  ];

  /*Task Table
  NON-NULL colTaskStatus, colTaskGoalId
  */
  static const String taskTable = "tasks";
  //Primary Key - UID int
  static const String colTaskId = "uid";
  //Constraints
  static const String taskFKGoal = "fk_goal";
  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colTaskGoalId = "goal_uid";

  //Type - String
  static const String colTaskTask = "task";

  //Type - int
  static const String colTaskActionDate = "action_date";
  static const String colTaskStatus = "status";
  static const String colTaskCompletionDate = "completion_date";
  static const String colTaskAlertTime = "task_alert_time";

  //List of all Manual tasks table columns
  static const List<String> taskCols = [
    colTaskGoalId,
    colTaskActionDate,
    colTaskStatus,
    colTaskCompletionDate,
    colTaskAlertTime
  ];

  /*
    Tags Task Table (Look Up Table)
     UNIQUE - (colTagTaskTaskId, colTagTaskTagId)
  */
  static const String tagTaskTable = "tags_tasks";

  //Constraints
  static const String tagTaskFK = "fk_tag_task";
  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colTagTaskTaskId = "task_uid";
  static const String colTagTaskTagId = "tag_uid";

  //List of all Manual tag task table columns
  static const List<String> tagTaskCol = [colTagTaskTaskId, colTagTaskTagId];

  /*
    Document Task Table (Look Up Table)

    UNIQUE - (colDocTaskTaskId, colDocTaskDocId)
  */
  static const String docTaskTable = "docs_tasks";

  //Constraints
  static const String docTaskTaskFK = "fk_doc_task_task";
  static const String docTaskDocFK = "fk_doc_task_doc";
  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colDocTaskTaskId = "task_uid";
  static const String colDocTaskDocId = "doc_uid";

  //List of all Manual doc task table columns
  static const List<String> docTaskCols = [colDocTaskTaskId, colDocTaskDocId];

  /*
    Document Table
  */
  static const String docTable = "docs";

  //Primary Key - UID int
  static const String colDocId = "uid";

  //Type - String
  static const String colDocPath = "path";
  static const String colDocType = "type";
  static const String colDocDesc = "desc";

  //Constraints
  static const String docFKGoal = "fk_doc_goal";
  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colDocGoalId = "goal_uid";

  //List of all Manual doc goal table columns
  static const List<String> docCols = [
    colDocGoalId,
    colDocPath,
    colDocType,
    colDocDesc,
  ];

  /*
    DayPlanItem Table
  */
  static const String dayPlanTable = "day_plan";

  //Primary Key - UID int
  static const String colDayPlanId = "uid";

  //Type - int
  static const String colDayPlanDate = "path";
  static const String colDayPlanPriority = "type";

  //Constraints
  static const String dayPlanFKTask = "fk_day_task";
  //Foreign Key - Linked to Goals Table Primary Key id
  static const String colDayPlanTaskId = "task_uid";

  //List of all Manual doc goal table columns
  static const List<String> dayPlanCols = [
    colDayPlanTaskId,
    colDayPlanDate,
    colDayPlanPriority,
  ];
}
