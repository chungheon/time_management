class NotificationTextHelper {
  static String sessionEndTitle(int sessMin) {
    return "$sessMin Session Completed!";
  }

  static String breakEndTitle(int breakMin) {
    return "$breakMin Break Completed!";
  }

  static String sessionEndBody(int totalSessions) {
    return "You have completed another session! $totalSessions in total!";
  }

  static String breakEndBody() {
    return "You are well rested! Continue working!";
  }

  static String sessionEndPayload(String sessionUid, String sessionInterval) {
    return "page:0|route:focus|uid:$sessionUid|session:$sessionInterval";
  }

  static String breakEndPayload(String sessionUid, String breakInterval) {
    return "page:0|route:focus|uid:$sessionUid|break:$breakInterval";
  }
}
