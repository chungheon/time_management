import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/date_time_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/auto_complete_goals_input.dart';

class TaskSelectionCalendarWidget extends StatelessWidget {
  TaskSelectionCalendarWidget({
    super.key,
    this.planDate,
    required this.selectedTasks,
    required this.unscheduledTasks,
    required this.overdueTasks,
    required this.dayTasksList,
  });

  final GoalsController _goalsController = Get.find<GoalsController>();
  final DateTime? planDate;
  final RxMap<int, List<Task>> dayTasksList;
  final RxList<Task> unscheduledTasks;
  final RxList<Task> overdueTasks;
  final RxList<Task> _listSelectedTasks = RxList<Task>();
  final RxList<DayPlanItem> selectedTasks;
  final ScrollController _calendarScrollController = ScrollController();
  final RxBool isLoading = false.obs;
  @override
  Widget build(BuildContext context) {
    _calendarScrollController.addListener(() async {
      if (_calendarScrollController.position.pixels >
              _calendarScrollController.position.maxScrollExtent - 60 &&
          !isLoading.value) {
        isLoading.value = true;
        DateTime now = DateTime.now().dateOnly();
        var temp = dayTasksList.keys.toList()..sort();
        int max = temp.last;
        if (max < 30) {
          for (int i = 1; i < 7; i++) {
            var value = await _goalsController.fetchTasksByDate(
                now.add(Duration(days: i + max)).millisecondsSinceEpoch);
            value.removeWhere((element) =>
                element.status == TaskStatus.completed ||
                element.status == TaskStatus.archive);
            dayTasksList[i + max] = value;
          }
        }
        isLoading.value = false;
      }
    });
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: constraints,
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 240.0),
              height: constraints.maxHeight,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Container(
                    height: 60.0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 5.0),
                    child: AutoCompleteGoalsInput(
                      hintText: 'Search Goal',
                      onSelected: (goal) {
                        _listSelectedTasks.value = goal.tasks;
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 110.0,
                    child: Obx(
                      () {
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          controller: _calendarScrollController,
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.only(bottom: 10.0),
                          children: [
                            const SizedBox(
                              width: 20.0,
                            ),
                            ...dayTasksList
                                .map<int, Widget>((key, value) {
                                  return MapEntry(key,
                                      _dayTasksListItem(context, key, value));
                                })
                                .values
                                .toList(),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 7.0),
                    child: Row(
                      children: [
                        Flexible(
                          child: Material(
                            color: StateContainer.of(context)?.currTheme.button,
                            borderRadius: BorderRadius.circular(7.0),
                            elevation: 4.0,
                            child: InkWell(
                              onTap: () {
                                _listSelectedTasks.value = overdueTasks;
                              },
                              borderRadius: BorderRadius.circular(7.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 10.0),
                                decoration: const BoxDecoration(
                                    color: Colors.transparent),
                                child: Row(
                                  children: [
                                    Text(
                                      'Overdue',
                                      style: AppStyles.defaultFont.copyWith(
                                          fontSize: AppFontSizes.paragraph),
                                    ),
                                    const SizedBox(
                                      width: 5.0,
                                    ),
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: Obx(() {
                                        return Text(
                                          '${overdueTasks.length} Tasks',
                                          overflow: TextOverflow.ellipsis,
                                          style: AppStyles.defaultFont.copyWith(
                                              fontSize: AppFontSizes.paragraph),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10.0,
                        ),
                        Flexible(
                          child: Material(
                            color: StateContainer.of(context)?.currTheme.button,
                            borderRadius: BorderRadius.circular(7.0),
                            elevation: 4.0,
                            child: InkWell(
                              onTap: () {
                                _listSelectedTasks.value = unscheduledTasks;
                              },
                              borderRadius: BorderRadius.circular(7.0),
                              child: Container(

                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 10.0),
                                decoration: const BoxDecoration(
                                    color: Colors.transparent),
                                child: Row(
                                  children: [
                                    Text(
                                      'Unscheduled',
                                      style: AppStyles.defaultFont.copyWith(
                                          fontSize: AppFontSizes.paragraph),
                                    ),
                                    const SizedBox(
                                      width: 5.0,
                                    ),
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: Obx(() {
                                        return Text(
                                          '${unscheduledTasks.length} Tasks',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppStyles.defaultFont.copyWith(
                                              fontSize: AppFontSizes.paragraph),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () {
                  if (_listSelectedTasks.isEmpty) {
                    return Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'No tasks to select.\nSearch for a goal, or select a date.',
                        textAlign: TextAlign.center,
                        style: AppStyles.defaultFont.copyWith(
                            fontSize: AppFontSizes.header3,
                            color:
                                StateContainer.of(context)?.currTheme.hintText),
                      ),
                    );
                  }
                  List<int?> selectedTaskIds = selectedTasks.map<int?>((e) {
                    return e.task?.uid;
                  }).toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    itemCount: _listSelectedTasks.length,
                    itemBuilder: (context, index) {
                      Task task = _listSelectedTasks[index];
                      bool selected = task.uid == null
                          ? false
                          : selectedTaskIds.contains(task.uid);
                      return _taskListItem(context, task, index, selected);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayTasksListItem(
    context,
    int difference,
    List<Task> tasks,
  ) {
    DateTime now = DateTime.now();
    DateTime diffDate = now.add(Duration(days: difference));
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: Material(
          color: StateContainer.of(context)?.currTheme.background,
          borderRadius: BorderRadius.circular(15.0),
          elevation: 4.0,
          shadowColor: StateContainer.of(context)?.currTheme.shadowElevation,
          child: InkWell(
            onTap: () {
              _listSelectedTasks.value = dayTasksList[difference] ?? [];
            },
            borderRadius: BorderRadius.circular(15.0),
            child: Container(
              width: 60.0,
              alignment: Alignment.topCenter,
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateTimeHelpers.getFormattedDate(diffDate,
                            dateFormat: "dd"),
                        style: AppStyles.defaultFont.copyWith(
                            color: StateContainer.of(context)?.currTheme.text,
                            fontSize: AppFontSizes.header3,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "/${DateTimeHelpers.getFormattedDate(diffDate, dateFormat: "MM")}",
                        style: AppStyles.defaultFont.copyWith(
                            color: StateContainer.of(context)?.currTheme.text,
                            fontSize: AppFontSizes.paragraph),
                      ),
                    ],
                  ),
                  tasks.isEmpty
                      ? Container(
                          height: 25.0,
                          alignment: Alignment.center,
                          child: const Text("-"),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              tasks.length.toString(),
                              style: AppStyles.defaultFont.copyWith(
                                  color: StateContainer.of(context)
                                      ?.currTheme
                                      .text,
                                  fontSize: AppFontSizes.body),
                            ),
                            Container(
                              width: 14.0,
                              height: 14.0,
                              margin: const EdgeInsets.only(left: 2.0),
                              color: tasks.length > 10
                                  ? Colors.red
                                  : tasks.length > 5
                                      ? Colors.yellow
                                      : Colors.green,
                            ),
                          ],
                        ),
                  Text(
                    DateTimeConstants
                        .days[DateTimeHelpers.getDayValue(diffDate)]
                        .toLowerCase()
                        .substring(0, 3),
                    style: AppStyles.defaultFont.copyWith(
                        color: StateContainer.of(context)?.currTheme.text,
                        fontStyle: FontStyle.italic,
                        fontSize: AppFontSizes.body),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _taskListItem(context, Task task, int index, bool selected) {
    String startDate = task.actionDate == null
        ? DateTimeConstants.noDate
        : DateTimeHelpers.getFormattedDate(
            DateTime.fromMillisecondsSinceEpoch(task.actionDate!),
            dateFormat: ('dd/MM'),
          );
    return GestureDetector(
      onTap: () {
        if (!selected) {
          selectedTasks.add(DayPlanItem(
              taskId: task.uid,
              taskPriority: TaskPriority.mustDo,
              date: planDate?.millisecondsSinceEpoch,
              task: task));
        } else {
          selectedTasks.removeWhere((element) => element.taskId == task.uid);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: StateContainer.of(context)?.currTheme.background,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            EffectConstants.shadowEffectDown(context),
          ],
          border: selected ? Border.all(width: 1.5) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18.0,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            (task.goal?.name ?? ''),
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.defaultFont.copyWith(
                              fontSize: AppFontSizes.footNote,
                              fontStyle: FontStyle.italic,
                              color: StateContainer.of(context)
                                  ?.currTheme
                                  .hintText,
                            ),
                          ),
                        ),
                        Container(
                          height: 3.0,
                          width: 3.0,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            color:
                                StateContainer.of(context)?.currTheme.hintText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            startDate,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.defaultFont.copyWith(
                              fontSize: AppFontSizes.footNote,
                              fontStyle: FontStyle.italic,
                              color: StateContainer.of(context)
                                  ?.currTheme
                                  .hintText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (task.task ?? ''),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.defaultFont.copyWith(
                        fontSize: AppFontSizes.body,
                        decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
