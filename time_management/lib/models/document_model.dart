import 'package:time_management/constants/sql_constants.dart';

// ignore: constant_identifier_names
enum DocumentType { Contact, Video, String, Doc, None }

class Document with SQFLiteObject {
  Document({
    required this.uid,
    required this.goalUid,
    this.path,
    this.type,
    this.desc,
  });
  final int? uid;
  int? goalUid;
  String? path;
  final int? type;
  String? desc;
  List<Document> linked = [];

  factory Document.fromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rUid = int.tryParse(queryResult[SQLConstants.colDocId].toString());
    int? rGoalUid =
        int.tryParse(queryResult[SQLConstants.colDocGoalId].toString());
    String? rPath = (queryResult[SQLConstants.colDocPath] ?? '').toString();
    int? rType =  int.tryParse(queryResult[SQLConstants.colDocType].toString());
    String? rDesc = (queryResult[SQLConstants.colDocDesc] ?? '').toString();

    return Document(
        uid: rUid, goalUid: rGoalUid, path: rPath, type: rType, desc: rDesc);
  }

  void updateFromSQFLITEMap(Map<String, Object?> queryResult) {
    int? rGoalUid =
        int.tryParse(queryResult[SQLConstants.colDocGoalId].toString());
    String? rPath = (queryResult[SQLConstants.colDocPath] ?? '').toString();
    String? rDesc = (queryResult[SQLConstants.colDocDesc] ?? '').toString();
    goalUid = rGoalUid;
    path = rPath;
    desc = rDesc;
  }

  @override
  Map<String, dynamic> toMapSQFLITE() {
    // if ((uid ?? -1) < 0) {
    //   return {
    //     SQLConstants.colDocGoalId: goalUid,
    //     SQLConstants.colDocPath: path,
    //     SQLConstants.colDocType: type,
    //     SQLConstants.colDocDesc: desc,
    //   };
    // }
    return {
      // SQLConstants.colGoalId: uid,
      SQLConstants.colDocGoalId: goalUid,
      SQLConstants.colDocPath: path,
      SQLConstants.colDocType: type,
      SQLConstants.colDocDesc: desc,
    };
  }

  @override
  String objTable() {
    return SQLConstants.docTable;
  }

  @override
  String toString() {
    // ignore: prefer_adjacent_string_concatenation
    return 'Document{${SQLConstants.colDocId}: $uid, ${SQLConstants.colDocGoalId}: $goalUid,' +
        ' ${SQLConstants.colDocType}: $type, ${SQLConstants.colDocPath}: $path, ${SQLConstants.colDocDesc}: $desc, linked: $linked}';
  }

  @override
  bool operator ==(Object other){
    if (identical(this, other)) return true; 
    return other is Document && other.uid == uid;
  }  
}
