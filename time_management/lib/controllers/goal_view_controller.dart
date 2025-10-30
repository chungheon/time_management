import 'package:get/get.dart';

class GoalViewController extends GetxController{
  final RxInt currentGoal = 0.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isEditing = false.obs;
  final RxList<int> editSelectedTasks = RxList<int>();
  final RxInt editIndex = 0.obs;
  final RxBool calendarView = true.obs;
  final RxInt selectedDateView = 0.obs;

}