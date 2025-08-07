import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_icons.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/add_task_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/custom_bottom_sheet.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/task_selection_calendar.dart';

class DayPlanReviewPage extends StatefulWidget {
  const DayPlanReviewPage(
      {super.key, this.returnRoute, required this.planDate, this.dayList});
  final String? returnRoute;
  final List<DayPlanItem>? dayList;
  final DateTime planDate;

  @override
  State<DayPlanReviewPage> createState() => _DayPlanReviewPageState();
}

class _DayPlanReviewPageState extends State<DayPlanReviewPage>
    with TickerProviderStateMixin {
  final GoalsController _goalsController = Get.find<GoalsController>();
  final RxBool _forwardTasks = true.obs;
  final RxBool _hasTasksDue = false.obs;
  final RxBool _dueTasks = false.obs;
  final RxBool _showTaskList = false.obs;
  final RxList<DayPlanItem> _selectedTasks = RxList<DayPlanItem>();
  final RxList<Task> _unscheduledTasks = RxList<Task>();
  final RxList<Task> _overdueTasks = RxList<Task>();
  final RxMap<int, List<Task>> _dayTasksList = RxMap<int, List<Task>>();

  @override
  void initState() {
    super.initState();
    if (widget.dayList != null) {
      _selectedTasks.value = List<DayPlanItem>.from(widget.dayList!);
    }
  }

  String dateStr() {
    return DateTimeHelpers.getFormattedDate(widget.planDate,
        dateFormat: 'dd/MM');
  }

  Future<void> refereshOverdueTasks() async {
    await _goalsController
        .fetchOverdueTasks(widget.planDate.millisecondsSinceEpoch)
        .then((value) {
      _overdueTasks.value = value;
    });
  }

  void addOverdueTasks() {
    var tasksUid = _selectedTasks.map<int?>((e) => e.taskId);
    for (var e in _overdueTasks) {
      if (!tasksUid.contains(e.uid)) {
        _selectedTasks.add(DayPlanItem(
            date: widget.planDate.millisecondsSinceEpoch,
            taskId: e.uid,
            taskPriority: TaskPriority.mustDo,
            task: e));
      }
    }
  }

  Future<void> fetchDayListTasks({bool? refresh}) async {
    if (refresh != null && refresh) {
      _dayTasksList.value = {};
    }
    DateTime now = DateTime.now().dateOnly();

    for (int i = 0; i < 7; i++) {
      var date = now.add(Duration(days: i));
      var result =
          await _goalsController.fetchTasksByDate(date.millisecondsSinceEpoch);
      result.removeWhere((element) =>
          element.status == TaskStatus.completed ||
          element.status == TaskStatus.archive);
      if (date == widget.planDate && result.isNotEmpty) {
        _hasTasksDue.value = true;
        _dueTasks.value = true;
      }
      _dayTasksList[i] = result;
    }
  }

  void addTaskDue() {
    DateTime now = DateTime.now().dateOnly();
    int dayDiff = DateTimeHelpers.getDayDifference(widget.planDate, now);
    var tasksUid = _selectedTasks.map<int?>((e) => e.taskId);
    List<Task>? tasks = _dayTasksList[dayDiff];
    if (tasks != null) {
      for (var e in tasks) {
        if (!tasksUid.contains(e.uid)) {
          _selectedTasks.add(DayPlanItem(
              date: widget.planDate.millisecondsSinceEpoch,
              taskId: e.uid,
              taskPriority: TaskPriority.mustDo,
              task: e));
        }
      }
    }
  }

  void removeOverdueTasks() {
    var tasksUid = _overdueTasks.map<int?>((e) => e.uid);
    _selectedTasks.removeWhere((element) {
      return tasksUid.contains(element.taskId);
    });
  }

  void removeTaskDue() {
    DateTime now = DateTime.now().dateOnly();
    int dayDiff = DateTimeHelpers.getDayDifference(widget.planDate, now);
    List<Task> tasks = _dayTasksList[dayDiff]!;
    for (var e in tasks) {
      _selectedTasks.removeWhere((element) {
        return element.taskId == e.uid;
      });
    }
  }

  void onForwardTasksToggle() {
    _forwardTasks.value = !_forwardTasks.value;
    if (_forwardTasks.value) {
      addOverdueTasks();
    } else {
      removeOverdueTasks();
    }
  }

  void onTaskDueToggle() {
    _dueTasks.value = !_dueTasks.value;
    if (_dueTasks.value) {
      addTaskDue();
    } else {
      removeTaskDue();
    }
  }

  void onCreateTap() {
    if (_selectedTasks.isEmpty) {
      return;
    }
    Get.off(() => LoadingPageWidget(
          asyncFunc: () async {
            if (widget.dayList == null) {
              await _goalsController.createDayPlan(_selectedTasks);
              try {
                await _goalsController.updatePlanList(
                    _goalsController.dayPlansList,
                    planDate: widget.planDate.millisecondsSinceEpoch);

                print(_goalsController.dayPlansList);
                _goalsController.update();
              } on Exception {
                //TODO:on create plan fails
              }
            } else {
              await _goalsController.updateDayPlan(
                  _selectedTasks, widget.dayList!);
              try {
                await _goalsController.updatePlanList(
                    _goalsController.dayPlansList,
                    planDate: widget.planDate.millisecondsSinceEpoch);
                _goalsController.update();
              } on Exception {
                //TODO:on create plan fails
              }
            }

            return;
          },
          onComplete: (_) async {
            Get.until((route) {
              return widget.returnRoute != null
                  ? route.settings.name == widget.returnRoute
                  : route.isFirst;
            });
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timestamp) async {
      _goalsController.fetchTasksByDate(null).then((value) {
        _unscheduledTasks.value = value.where((element) {
          return element.status != TaskStatus.completed;
        }).toList();
      });

      refereshOverdueTasks().then((value) {
        if (widget.dayList == null) {
          addOverdueTasks();
        }
      });
      fetchDayListTasks(refresh: true).then((value) {
        if (widget.dayList == null) {
          addTaskDue();
        }
      });
    });
    return PopScope(
      canPop: false,
      onPopInvoked: (pop) async {
        if (!pop) {
          if (_showTaskList.value) {
            _showTaskList.value = !_showTaskList.value;
          } else {
            showDialog(
              context: context,
              builder: (_) =>
                  DialogConstants.exitDialog(returnRoute: widget.returnRoute),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: StateContainer.of(context)?.currTheme.background,
        resizeToAvoidBottomInset: false,
        appBar: PageHeaderWidget(
          title: '${dateStr()} Plan',
          exitDialog:
              DialogConstants.exitDialog(returnRoute: widget.returnRoute),
        ),
        body: Stack(
          fit: StackFit.passthrough,
          children: [
            Column(
              children: [
                _reviewPlanHeader(context),
                Expanded(
                  child: Obx(
                    () {
                      return ListView.builder(
                        itemCount: _selectedTasks.length,
                        itemBuilder: (context, index) {
                          return _dayPlanItem(
                              context, _selectedTasks[index], index);
                        },
                      );
                    },
                  ),
                ),
                _createPlanButton(context),
              ],
            ),
            _taskSelectionCalendarSheet(context),
          ],
        ),
      ),
    );
  }

  Widget _createPlanButton(context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context)?.currTheme.background,
      ),
      child: Obx(
        () => Material(
          color: _selectedTasks.isEmpty
              ? StateContainer.of(context)?.currTheme.hintText
              : StateContainer.of(context)?.currTheme.darkButton,
          borderRadius: BorderRadius.circular(8.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: _selectedTasks.isEmpty ? null : onCreateTap,
            splashColor: StateContainer.of(context)?.currTheme.splashEffect,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              color: Colors.transparent,
              child: Center(
                child: Text(
                  widget.dayList == null ? "Create Plan" : "Update Plan",
                  style: AppStyles.actionButtonText(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayPlanItem(
    context,
    DayPlanItem item,
    int index,
  ) {
    Color priorityColor = (item.taskPriority?.index ?? 0) == 0
        ? Colors.red
        : (item.taskPriority?.index ?? 0) == 1
            ? Colors.green
            : Colors.blue;
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                item.taskPriority = TaskPriority.values[
                    (item.taskPriority!.index + 1) %
                        TaskPriority.values.length];
                _selectedTasks.refresh();
              },
              child: Container(
                padding: const EdgeInsets.all(12.0),
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
                            clipBehavior: Clip.none,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: Get.size.width / 2.2),
                                  child: Text(
                                    (item.task?.goal?.name ?? 'No Goal'),
                                    overflow: TextOverflow.ellipsis,
                                    style: AppStyles.defaultFont.copyWith(
                                      fontSize: AppFontSizes.paragraph,
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
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: StateContainer.of(context)
                                        ?.currTheme
                                        .hintText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    StringConstants.taskPriorities[
                                        item.taskPriority!.index],
                                    overflow: TextOverflow.ellipsis,
                                    style: AppStyles.defaultFont.copyWith(
                                      fontSize: AppFontSizes.paragraph,
                                      fontStyle: FontStyle.italic,
                                      color: priorityColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            (item.task?.task ?? ''),
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
            ),
          ),
          GestureDetector(
            onTap: () {
              _selectedTasks.removeAt(index);
            },
            child: Container(
              height: 50.0,
              width: 50.0,
              padding:
                  const EdgeInsets.only(left: 10.0, top: 10.0, bottom: 10.0),
              child: const FittedBox(
                  child: Icon(
                Icons.cancel_outlined,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskSelectionCalendarSheet(context) {
    return CustomBottomSheet(
      showBottomSheet: _showTaskList,
      child: TaskSelectionCalendarWidget(
        planDate: widget.planDate,
        selectedTasks: _selectedTasks,
        overdueTasks: _overdueTasks,
        unscheduledTasks: _unscheduledTasks,
        dayTasksList: _dayTasksList,
      ),
    );
  }

  Widget _reviewPlanHeader(context) {
    return Column(
      children: [
        const SizedBox(
          height: 10.0,
        ),
        Obx(() {
          return _overdueTasks.isEmpty || widget.dayList != null
              ? Container()
              : Container(
                  height: 41.0,
                  padding: const EdgeInsets.only(
                      left: 20.0, right: 20.0, bottom: 10.0),
                  // color: StateContainer.of(context)?.currTheme.textBackground,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Forward all overdue tasks (${_overdueTasks.length} Tasks)',
                          style: AppStyles.defaultFont
                              .copyWith(fontSize: AppFontSizes.body),
                        ),
                      ),
                      GestureDetector(
                        onTap: onForwardTasksToggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          height: 25.0,
                          width: 55.0,
                          alignment: _forwardTasks.value
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: _forwardTasks.value
                                ? StateContainer.of(context)
                                    ?.currTheme
                                    .splashEffect
                                : StateContainer.of(context)
                                    ?.currTheme
                                    .shadowElevation,
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Container(
                            height: 22.0,
                            width: 22.0,
                            margin: const EdgeInsets.all(3.0),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: StateContainer.of(context)
                                    ?.currTheme
                                    .background),
                          ),
                        ),
                      )
                    ],
                  ),
                );
        }),
        Obx(() {
          if (!_hasTasksDue.value || widget.dayList != null) {
            return Container();
          }
          var dayDiff = DateTimeHelpers.getDayDifference(
              widget.planDate, DateTime.now().dateOnly());
          List<Task> tasks = _dayTasksList[dayDiff] ?? [];
          return Container(
            height: 41.0,
            padding:
                const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
            margin: const EdgeInsets.only(bottom: 7.0),
            // color: StateContainer.of(context)?.currTheme.textBackground,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add all tasks due on ${dateStr()} (${tasks.length} Tasks)',
                    style: AppStyles.defaultFont
                        .copyWith(fontSize: AppFontSizes.body),
                  ),
                ),
                GestureDetector(
                  onTap: onTaskDueToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: 25.0,
                    width: 55.0,
                    alignment: _dueTasks.value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: _dueTasks.value
                          ? StateContainer.of(context)?.currTheme.splashEffect
                          : StateContainer.of(context)
                              ?.currTheme
                              .shadowElevation,
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Container(
                      height: 22.0,
                      width: 22.0,
                      margin: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              StateContainer.of(context)?.currTheme.background),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        _selectedTasksMeta(context),
      ],
    );
  }

  Widget _selectedTasksMeta(context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () {
                        return Text(
                          'Selected ${_selectedTasks.length} Tasks',
                          style: AppStyles.defaultFont.copyWith(
                              fontSize: AppFontSizes.body,
                              fontStyle: FontStyle.italic),
                        );
                      },
                    ),
                    Obx(
                      () {
                        return Row(
                          children: [
                            Text(
                              '${_selectedTasks.where((e) => e.taskPriority == TaskPriority.mustDo).length} Must-Do',
                              style: AppStyles.defaultFont.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppFontSizes.paragraph,
                                  fontStyle: FontStyle.italic),
                            ),
                            Container(
                              height: 3.0,
                              width: 3.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                color:
                                    StateContainer.of(context)?.currTheme.text,
                                shape: BoxShape.circle,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _selectedTasks
                                        .where((e) =>
                                            e.taskPriority ==
                                            TaskPriority.quickTask)
                                        .length
                                        .toString(),
                                    style: AppStyles.defaultFont.copyWith(
                                        fontSize: AppFontSizes.paragraph,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: ' Quick Tasks',
                                    style: AppStyles.defaultFont.copyWith(
                                        fontSize: AppFontSizes.paragraph,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 3.0,
                              width: 3.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                color:
                                    StateContainer.of(context)?.currTheme.text,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${_selectedTasks.where((e) => e.taskPriority == TaskPriority.niceToHave).length.toString()} Nice-To-Have',
                                style: AppStyles.defaultFont.copyWith(
                                    fontSize: AppFontSizes.paragraph,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        var currentRoute = Get.currentRoute;
                        Get.to(() => AddTaskPage(
                              returnRoute: currentRoute,
                              onCreateComplete: (taskUid) async {
                                refereshOverdueTasks();
                                fetchDayListTasks(refresh: true);
                                if (taskUid != null) {
                                  Task? taskCreated = (await _goalsController
                                      .fetchTaskById(taskUid));
                                  _selectedTasks.add(DayPlanItem(
                                      task: taskCreated,
                                      taskId: taskCreated?.uid,
                                      taskPriority: TaskPriority.mustDo,
                                      date: taskCreated?.actionDate ??
                                          widget.planDate
                                              .millisecondsSinceEpoch));
                                }
                              },
                            ));
                      },
                      child: Container(
                        height: 40.0,
                        width: 40.0,
                        padding: const EdgeInsets.only(
                            left: 8.0, right: 6.0, top: 3.0),
                        margin: const EdgeInsets.only(top: 10.0),
                        decoration: BoxDecoration(
                            color: StateContainer.of(context)?.currTheme.button,
                            shape: BoxShape.circle,
                            boxShadow: [
                              EffectConstants.shadowEffectDown(context)
                            ]),
                        child: const FittedBox(child: Icon(AppIcons.add_tasks)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              _showTaskList.value = true;
            },
            child: Container(
              padding: const EdgeInsets.all(5.0),
              margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
              decoration: BoxDecoration(
                  color: StateContainer.of(context)?.currTheme.button,
                  border: Border.all(
                    color: StateContainer.of(context)?.currTheme.text ??
                        Colors.black,
                  ),
                  borderRadius: BorderRadius.circular(10.0)),
              alignment: Alignment.center,
              child: Text('View Calendar',
                  style: AppStyles.defaultFont.copyWith(
                      color: StateContainer.of(context)?.currTheme.text,
                      fontSize: AppFontSizes.body)),
            ),
          ),
        ],
      ),
    );
  }
}
