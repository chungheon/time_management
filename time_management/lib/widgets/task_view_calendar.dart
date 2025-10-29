import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/date_time_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/styles.dart';

class TaskViewCalendarWidget extends StatelessWidget {
  TaskViewCalendarWidget({
    super.key,
    required List<Task> tasks,
    required this.selected,
  }) {
    DateTime dateNow = DateTime.now().dateOnly();
    int now = dateNow.millisecondsSinceEpoch;
    _overdueList.value =
        tasks.where((e) => (e.actionDate ?? now) < now).toList();
    _completedList.value = tasks
        .where((e) => (e.status ?? TaskStatus.ongoing) == TaskStatus.completed)
        .toList();
    for (int i = 0; i < 14; i++) {
      dayTasksList[i] = [];
    }
    for (var task in tasks) {
      if (task.actionDate != null) {
        int dateDiff = DateTime.fromMillisecondsSinceEpoch(task.actionDate!)
            .dateOnly()
            .difference(dateNow)
            .inDays;
        if (dayTasksList[dateDiff] == null) {
          dayTasksList[dateDiff] = [task];
        } else {
          dayTasksList[dateDiff]!.add(task);
        }
      }
    }
    switch (selected.value) {
      case -1:
        _tasksList.value = _overdueList;
      case -2:
        _tasksList.value = _unscheduledList;
      default:
        _tasksList.value = tasks
            .where((e) =>
                e.actionDate != null &&
                e.actionDate! ==
                    dateNow
                        .add(Duration(days: selected.value))
                        .millisecondsSinceEpoch &&
                (e.status ?? TaskStatus.completed) != TaskStatus.completed)
            .toList();
    }
    print(selected.value);
  }
  final RxMap<int, List<Task>> dayTasksList = RxMap<int, List<Task>>();
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
                                          '${_overdueList.length} Tasks',
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
                                          '${_unscheduledList.length} Tasks',
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
              _tasksList.value = dayTasksList[difference] ?? [];
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

  Widget _taskListItem(context, Task task, int index) {
    String startDate = task.actionDate == null
        ? DateTimeConstants.noDate
        : DateTimeHelpers.getFormattedDate(
            DateTime.fromMillisecondsSinceEpoch(task.actionDate!),
            dateFormat: ('dd/MM'),
          );
    return Container(
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
                            color:
                                StateContainer.of(context)?.currTheme.hintText,
                          ),
                        ),
                      ),
                      Container(
                        height: 3.0,
                        width: 3.0,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: StateContainer.of(context)?.currTheme.hintText,
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
                            color:
                                StateContainer.of(context)?.currTheme.hintText,
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
    );
  }
}
