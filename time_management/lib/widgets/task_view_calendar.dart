import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/date_time_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/goal_view_controller.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/edit_task_page.dart';
import 'package:time_management/styles.dart';

class TaskViewCalendarWidget extends StatelessWidget {
  TaskViewCalendarWidget({
    super.key,
    required List<Task> tasks,
    required this.selected,
  }) {
    DateTime dateNow = DateTime.now().dateOnly();
    int now = dateNow.millisecondsSinceEpoch;
    _unscheduledList.value = tasks
        .where(
            (e) => (e.actionDate == null) && (e.status != TaskStatus.completed))
        .toList();
    _overdueList.value = tasks
        .where((e) =>
            ((e.actionDate ?? now) < now) && (e.status != TaskStatus.completed))
        .toList();
    _completedList.value = tasks
        .where((e) => (e.status ?? TaskStatus.ongoing) == TaskStatus.completed)
        .toList();
    for (int i = 0; i < 14; i++) {
      _dayTasksList[i] = [];
    }
    for (var task in tasks) {
      if (task.actionDate != null) {
        int dateDiff = DateTime.fromMillisecondsSinceEpoch(task.actionDate!)
            .dateOnly()
            .difference(dateNow)
            .inDays;
        if(dateDiff < 0){
          continue;
        }
        if (_dayTasksList[dateDiff] == null) {
          _dayTasksList[dateDiff] = [task];
        } else {
          _dayTasksList[dateDiff]!.add(task);
        }
      }
    }
    switch (selected.value) {
      case -1:
        _tasksList.value = _overdueList;
        break;
      case -2:
        _tasksList.value = _unscheduledList;
        break;
      case -3:
        _tasksList.value = _completedList;
        break;
      default:
        _tasksList.value = _dayTasksList[selected.value] ?? [];
    }
  }
  final GoalsController _goalsController = Get.find();
  final GoalViewController _goalViewController = Get.find();
  final RxMap<int, List<Task>> _dayTasksList = RxMap<int, List<Task>>();
  final RxList<Task> _tasksList = RxList<Task>();
  final RxList<Task> _overdueList = RxList<Task>();
  final RxList<Task> _completedList = RxList<Task>();
  final RxList<Task> _unscheduledList = RxList<Task>();
  final RxInt selected;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: constraints,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 110.0,
                    child: Obx(
                      () {
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.only(bottom: 10.0),
                          children: [
                            const SizedBox(
                              width: 20.0,
                            ),
                            ..._dayTasksList
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
                                _tasksList.value = _overdueList;
                                selected.value = -1;
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
                                      'Due',
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
                                          '${_overdueList.length}',
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
                                _tasksList.value = _unscheduledList;
                                selected.value = -2;
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
                                      'Unschdl',
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
                                          '${_unscheduledList.length}',
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
                                _tasksList.value = _completedList;
                                selected.value = -3;
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
                                      'Compl',
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
                                          '${_completedList.length}',
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
            const SizedBox(
              height: 10.0,
            ),
            Expanded(
              child: Obx(
                () {
                  if (_tasksList.isEmpty) {
                    return Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'No tasks',
                        textAlign: TextAlign.center,
                        style: AppStyles.defaultFont.copyWith(
                            fontSize: AppFontSizes.header3,
                            color:
                                StateContainer.of(context)?.currTheme.hintText),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    itemCount: _tasksList.length,
                    itemBuilder: (context, index) {
                      Task task = _tasksList[index];
                      return _taskListItem(context, task, index);
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
              _tasksList.value = _dayTasksList[difference] ?? [];
              selected.value = difference;
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
                    DateTimeHelpers.getDayValueStr(diffDate)
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

  Widget _taskListItem(context, Task task, int index) {
    String startDate = task.actionDate == null
        ? DateTimeConstants.noDate
        : DateTimeHelpers.getFormattedDate(
            DateTime.fromMillisecondsSinceEpoch(task.actionDate!),
            dateFormat: ('dd/MM'),
          );
    return GestureDetector(
      onLongPress: () {
        Get.to(() => EditTaskPage(
              task: task,
            ));
      },
      onDoubleTap: () async {
        if (!_goalViewController.isUpdating.value) {
          _goalViewController.isUpdating.value = true;
          TaskStatus taskStatus =
              TaskStatus.values[((task.status?.index ?? 0) + 1) % 3];
          try {
            if (await _goalsController.editTask(task, status: taskStatus)) {
              task.status = taskStatus;
            }
          } finally {
            _goalsController.update();
            _goalViewController.isUpdating.value = false;
          }
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
                            StringConstants.taskStatus[task.status?.index ?? 0],
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
