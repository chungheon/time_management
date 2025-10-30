import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_icons.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/date_time_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/document_viewer_controller.dart';
import 'package:time_management/controllers/goal_view_controller.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/helpers/color_helpers.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/add_document_page.dart';
import 'package:time_management/screens/add_goal_page.dart';
import 'package:time_management/screens/add_task_page.dart';
import 'package:time_management/screens/edit_goal_page.dart';
import 'package:time_management/screens/edit_task_page.dart';
import 'package:time_management/screens/goal_overview_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/auto_complete_goals_input.dart';
import 'package:time_management/widgets/confirmation_dialog.dart';
import 'package:time_management/widgets/document_widget.dart';
import 'package:time_management/widgets/goal_move_dialog.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/task_view_calendar.dart';
import 'package:time_management/widgets/text_document_widget.dart';
import 'package:time_management/widgets/video_document_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final GoalsController _goalsController = Get.find<GoalsController>();
  final GoalViewController _goalViewController = Get.find<GoalViewController>();
  final DocumentViewerController _documentViewerController =
      Get.find<DocumentViewerController>();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _taskScrollController = ScrollController();
  late TabController _listTabController;
  final PageController _pageController =
      PageController(initialPage: 0, viewportFraction: 0.65);
  final RxBool _hideSearch = false.obs;
  final RxBool _hideTitle = true.obs;
  final int _scrollOffset = 40;

  double prevPos = 0;

  @override
  bool get wantKeepAlive => true;

  Future<void> onLongPressGoalAddTask(controller, index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    var currRoute = Get.currentRoute;
    Get.to(() => EditGoalPage(
          returnRoute: currRoute,
          goal: controller.goalList[index],
        ));
  }

  Future<void> onLongPressTask(Task task) async {
    if (_goalViewController.isEditing.value) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    var currRoute = Get.currentRoute;
    Get.to(() => EditTaskPage(
          returnRoute: currRoute,
          task: task,
        ));
  }

  Future<void> onTapAddGoal() async {
    var curr = Get.currentRoute;
    Get.to(() => AddGoalPage(
          returnRoute: curr,
        ));
  }

  Future<void> onTapAddDoc() async {
    var curr = Get.currentRoute;
    Get.to(() => AddDocumentPage(
          goal:
              _goalsController.goalList[_goalViewController.currentGoal.value],
          returnRoute: curr,
          onComplete: (docs) {
            _goalsController
                .goalList[_goalViewController.currentGoal.value].documents
                .addAll(docs);
            _goalsController.update();
          },
        ));
  }

  Future<void> onTapViewChange() async {
    _goalViewController.calendarView.value =
        !_goalViewController.calendarView.value;
    _goalViewController.editSelectedTasks.clear();
  }

  Future<void> onTapEdit() async {
    _goalViewController.isEditing.value = true;
  }

  Future<void> onCancelEdit() async {
    _goalViewController.editSelectedTasks.clear();
    _goalViewController.isEditing.value = false;
  }

  Future<void> onDoubleTapGoal() async {
    Get.to(
      () => const GoalOverviewPage(),
    );
  }

  Future<void> onTapMoveTasks() async {
    var currRoute = Get.currentRoute;
    showDialog(
        context: context,
        builder: (dialogContext) {
          if (_goalViewController.editSelectedTasks.isEmpty) {
            return ConfirmationDialog(
              message: "Please select atleast 1 task",
              onConfirm: () async {
                Get.until((route) => route.settings.name == currRoute);
              },
            );
          }
          return GoalMoveDialog(
            returnRoute: currRoute,
            sourceGoal: _goalsController
                    .goalList[_goalViewController.currentGoal.value].name ??
                "",
            onConfirm: (int goalUid) {
              Get.to(() => LoadingPageWidget(
                    asyncFunc: () async {
                      for (var taskId
                          in _goalViewController.editSelectedTasks) {
                        await _goalsController.moveTaskFromGoal(
                            taskId, goalUid);
                      }
                      await _goalsController.updateGoal(
                          _goalsController
                              .goalList[_goalViewController.currentGoal.value],
                          refreshPlanList: false);
                      await _goalsController.updateGoal(
                          _goalsController.goalList
                              .firstWhere((goal) => goal.uid == goalUid),
                          refreshPlanList: false);
                      await _goalsController.refreshPlanList();
                      return;
                    },
                    onComplete: (_) {
                      Get.until((route) => route.settings.name == currRoute);
                      _goalViewController.editSelectedTasks.clear();
                    },
                  ));
            },
          );
        });
  }

  void onGoalSelected(Goal selection) {
    selection.tasks.sort(Task.prioritySort);
    _goalsController.update();
    var page = _goalsController.goalList.indexOf(selection);
    _pageController.animateToPage(page,
        duration: Duration(
          milliseconds:
              300 * (_goalViewController.currentGoal.value - page).abs(),
        ),
        curve: Curves.linear);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int pos = _pageController.page?.round() ?? 0;
      if (_goalViewController.currentGoal.value != pos) {
        _goalViewController.currentGoal.value = pos;
        _scrollController.jumpTo(0);
        Future.delayed(const Duration(milliseconds: 300)).then((value) {
          _hideSearch.value = false;
        });
        _goalsController.update();
        _goalViewController.selectedDateView.value = 0;
      }
    });
    _scrollController.addListener(() {
      double currPos = _scrollController.position.pixels;
      if (currPos > 70.0) {
        _hideSearch.value = true;
        _hideTitle.value = false;
      } else {
        _hideSearch.value = false;
        _hideTitle.value = true;
      }
      prevPos = currPos;
    });

    _taskScrollController.addListener(() {
      if (_taskScrollController.position.pixels < 0) {
        _scrollController.jumpTo(max(
            _scrollController.position.pixels +
                _taskScrollController.position.pixels * 0.2,
            0));
      } else if (_scrollController.position.pixels <
          _scrollController.position.maxScrollExtent) {
        _scrollController.jumpTo(min(
            _scrollController.position.pixels +
                _taskScrollController.position.pixels * 0.05,
            _scrollController.position.maxScrollExtent));
      }
    });
    _goalViewController.currentGoal.listen((goalIndex) {
      _goalsController.goalList[goalIndex].tasks.sort(Task.prioritySort);
      _goalsController.update();
      _goalViewController.editSelectedTasks.clear();
      _goalViewController.isEditing.value = false;
      double pos = _pageController.page ?? 0;
      if (pos.round() != _goalViewController.currentGoal.value) {
        _pageController.jumpToPage(goalIndex);
      }
    });

    _listTabController = TabController(length: 4, vsync: this);
    _listTabController.addListener(() {
      _goalViewController.editIndex.value = _listTabController.index;
      _goalViewController.editSelectedTasks.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Material(
      color: StateContainer.of(context)?.currTheme.background,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _hideSearch.value ? 0.0 : 70.0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: AutoCompleteGoalsInput(
                        hintText: 'Search Goal',
                        onSelected: onGoalSelected,
                      ),
                    ),
                  );
                },
              ),
              Obx(
                () {
                  if (_goalsController.goalList.isEmpty) {
                    return Container();
                  }
                  return GestureDetector(
                    onTap: () {
                      _scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: _hideTitle.value ? 0.0 : 50.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 0.0),
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Text(
                              _goalsController
                                      .goalList[_goalViewController
                                              .currentGoal.value %
                                          _goalsController.goalList.length]
                                      .name ??
                                  "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.defaultFont.copyWith(
                                fontSize: AppFontSizes.header3,
                              ))),
                    ),
                  );
                },
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Obx(() {
                      if (_goalsController.goalList.isEmpty) {
                        return Container();
                      }
                      return ListView(
                        controller: _scrollController,
                        children: [
                          Column(
                            children: [
                              _goalsCarouselWidget(context),
                              Obx(() {
                                if (!_goalViewController.calendarView.value) {
                                  return SizedBox(
                                    height: constraints.maxHeight,
                                    child: _goalTasksWidget(context),
                                  );
                                }

                                return GetBuilder(
                                  init: _goalsController,
                                  builder: (controller) {
                                    var tasks = _goalsController
                                        .goalList[_goalViewController
                                            .currentGoal.value]
                                        .tasks;
                                    return SizedBox(
                                        height: constraints.maxHeight,
                                        child: TaskViewCalendarWidget(
                                          tasks: tasks,
                                          selected: _goalViewController
                                              .selectedDateView,
                                        ));
                                  },
                                );
                              }),
                            ],
                          ),
                        ],
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          Obx(() {
            if (!_goalViewController.isEditing.value) {
              return _footerBar(context);
            } else {
              if (_goalViewController.editIndex.value <= 2) {
                return _editBottomBar(context);
              } else {
                return _editDocumentBar(context);
              }
            }
          }),
        ],
      ),
    );
  }

  Widget _editDocumentBar(context) {
    return Positioned(
      right: 0,
      left: 0,
      bottom: 30,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Material(
          elevation: 4.0,
          color: StateContainer.of(context)?.currTheme.button,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onCancelEdit,
            customBorder: const CircleBorder(),
            child: SizedBox(
              height: 50.0,
              width: 50.0,
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: FittedBox(
                  child: Text(
                    "Cancel",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppStyles.defaultFont
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editBottomBar(context) {
    return Positioned(
      right: 0,
      left: 0,
      bottom: 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6.0),
                child: Material(
                  elevation: 4.0,
                  color: StateContainer.of(context)?.currTheme.button,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      if (_listTabController.index <= 2) {
                        if (_goalViewController.editSelectedTasks.isNotEmpty) {
                          _goalViewController.editSelectedTasks.clear();
                        } else {
                          int now =
                              DateTime.now().dateOnly().millisecondsSinceEpoch;
                          _goalViewController.editSelectedTasks.addAll(
                              _goalsController
                                  .goalList[
                                      _goalViewController.currentGoal.value]
                                  .tasks
                                  .where((e) {
                            switch (_listTabController.index) {
                              case 0:
                                return (e.status == TaskStatus.upcoming ||
                                        e.status == TaskStatus.ongoing) &&
                                    (e.actionDate != null &&
                                        e.actionDate! >= now);
                              case 1:
                                return e.status == TaskStatus.completed;
                              case 2:
                                return (e.status == TaskStatus.ongoing ||
                                        e.status == TaskStatus.upcoming) &&
                                    (e.actionDate != null &&
                                        e.actionDate! < now);
                              default:
                                return false;
                            }
                          }).map<int>((e) {
                            return e.uid ?? -1;
                          }).toList());
                        }
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: FittedBox(
                        child: Obx(
                          () => Text(
                            _goalViewController.editSelectedTasks.isNotEmpty
                                ? "Unselect"
                                : "Select\nAll",
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: AppStyles.defaultFont
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _goalViewController.editIndex.value != 1
                ? Container()
                : Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6.0),
                      child: Material(
                        elevation: 4.0,
                        color: StateContainer.of(context)?.currTheme.button,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return ConfirmationDialog(
                                    message: "Archive all tasks selected?",
                                    onConfirm: () async {
                                      Get.to(() => LoadingPageWidget(
                                            asyncFunc: () async {
                                              try {
                                                Goal goal =
                                                    _goalsController.goalList[
                                                        _goalViewController
                                                            .currentGoal.value];
                                                bool? result =
                                                    await _goalsController
                                                        .archiveTask(
                                                  _goalViewController
                                                      .editSelectedTasks,
                                                  goal.uid ?? -1,
                                                );
                                                if (result ?? false) {
                                                  _goalsController
                                                      .refreshPlanList();
                                                  _goalsController
                                                      .updateGoal(goal);
                                                  _goalsController.update();
                                                }
                                              } on Exception {
                                                rethrow;
                                              }

                                              return;
                                            },
                                            onComplete: (_) async {
                                              _goalViewController
                                                  .editSelectedTasks
                                                  .clear();
                                              _goalViewController
                                                  .isEditing.value = false;
                                              Get.until(
                                                  (route) => route.isFirst);
                                            },
                                          ));
                                    },
                                  );
                                });
                          },
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            height: 50.0,
                            width: 50.0,
                            child: Padding(
                              padding: const EdgeInsets.all(13.0),
                              child: FittedBox(
                                  child: Text(
                                "Archive",
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: AppStyles.defaultFont
                                    .copyWith(fontWeight: FontWeight.bold),
                              )),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6.0),
                child: Material(
                  elevation: 4.0,
                  color: StateContainer.of(context)?.currTheme.button,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return ConfirmationDialog(
                              message: "Delete all tasks selected?",
                              onConfirm: () async {
                                Get.to(() => LoadingPageWidget(
                                      asyncFunc: () async {
                                        try {
                                          bool result = await _goalsController
                                              .deleteTasksFromGoal(
                                                  _goalViewController
                                                      .editSelectedTasks,
                                                  _goalsController
                                                          .goalList[
                                                              _goalViewController
                                                                  .currentGoal
                                                                  .value]
                                                          .uid ??
                                                      -1);
                                          if (result) {
                                            _goalsController.refreshPlanList();
                                            _goalsController.update();
                                          }
                                        } on Exception {
                                          rethrow;
                                        }

                                        return;
                                      },
                                      onComplete: (_) {
                                        _goalViewController.editSelectedTasks
                                            .clear();
                                        _goalViewController.isEditing.value =
                                            false;
                                        Get.until((route) => route.isFirst);
                                      },
                                    ));
                              },
                            );
                          });
                    },
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: FittedBox(
                            child: Text(
                          "Delete",
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: AppStyles.defaultFont
                              .copyWith(fontWeight: FontWeight.bold),
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Material(
                  elevation: 4.0,
                  color: StateContainer.of(context)?.currTheme.button,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onTapMoveTasks,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: FittedBox(
                          child: Text(
                            "Move",
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: AppStyles.defaultFont
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Material(
                  elevation: 4.0,
                  color: StateContainer.of(context)?.currTheme.button,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onCancelEdit,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: FittedBox(
                          child: Text(
                            "Cancel",
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: AppStyles.defaultFont
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerBar(context) {
    return Positioned(
      bottom: 20.0,
      right: 20.0,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Material(
              elevation: 4.0,
              color: StateContainer.of(context)?.currTheme.button,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTapViewChange,
                customBorder: const CircleBorder(),
                child: Container(
                  height: 50.0,
                  width: 50.0,
                  padding: const EdgeInsets.all(6.0),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: FittedBox(
                      child: Text(
                    "View",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppStyles.defaultFont
                        .copyWith(fontWeight: FontWeight.bold),
                  )),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Material(
              elevation: 4.0,
              color: StateContainer.of(context)?.currTheme.button,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTapEdit,
                customBorder: const CircleBorder(),
                child: Container(
                  height: 50.0,
                  width: 50.0,
                  padding: const EdgeInsets.all(6.0),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: FittedBox(
                      child: Text(
                    "Edit",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppStyles.defaultFont
                        .copyWith(fontWeight: FontWeight.bold),
                  )),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Material(
              elevation: 4.0,
              color: StateContainer.of(context)?.currTheme.button,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTapAddDoc,
                customBorder: const CircleBorder(),
                child: Container(
                  height: 50.0,
                  width: 50.0,
                  padding: const EdgeInsets.all(6.0),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: FittedBox(
                      child: Text(
                    "+DOC",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppStyles.defaultFont
                        .copyWith(fontWeight: FontWeight.bold),
                  )),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Material(
              elevation: 4.0,
              color: StateContainer.of(context)?.currTheme.button,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  onTapAddGoal();
                },
                customBorder: const CircleBorder(),
                child: Container(
                  height: 50.0,
                  width: 50.0,
                  padding: const EdgeInsets.all(4.0),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: FittedBox(
                      child: Icon(
                    Icons.add_rounded,
                    color: StateContainer.of(context)?.currTheme.text,
                  )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskStatsWidget(
      int ongoing, int upcoming, int completed, int overdue) {
    return Row(
      children: [
        Text(
          '$ongoing ongoing',
          style: AppStyles.dateMetaHeader(context),
        ),
        Container(
          height: 3.0,
          width: 3.0,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: StateContainer.of(context)?.currTheme.text,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '$upcoming upcoming',
          style: AppStyles.dateMetaHeader(context),
        ),
        Container(
          height: 3.0,
          width: 3.0,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: StateContainer.of(context)?.currTheme.text,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '$completed completed',
          style: AppStyles.dateMetaHeader(context),
        ),
        Container(
          height: 3.0,
          width: 3.0,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: StateContainer.of(context)?.currTheme.text,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '$overdue overdue',
          style: AppStyles.dateMetaHeader(context),
        ),
      ],
    );
  }

  Widget _goalTasksWidget(context) {
    return GetBuilder(
      init: _goalsController,
      builder: (controller) {
        var tasks =
            controller.goalList[_goalViewController.currentGoal.value].tasks;
        var completedTasksList = tasks.where((task) {
          return task.status == TaskStatus.completed ||
              task.status == TaskStatus.archive;
        });
        int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
        var upcomingTasks = tasks.where((task) {
          return task.status == TaskStatus.upcoming &&
              (task.actionDate == null || task.actionDate! >= now);
        });
        var ongoingTasks = tasks.where((task) {
          return task.status == TaskStatus.ongoing &&
              (task.actionDate == null || task.actionDate! >= now);
        });
        var overdueTasks = tasks.reversed
            .where((element) =>
                element.status != TaskStatus.completed &&
                element.actionDate != null &&
                element.actionDate! <
                    DateTime.now().dateOnly().millisecondsSinceEpoch)
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Obx(() {
                  if (_goalViewController.isEditing.value) {
                    int selectedCompleted = completedTasksList
                        .where((task) => _goalViewController.editSelectedTasks
                            .contains(task.uid ?? -2))
                        .length;
                    int selectedIncompleted =
                        _goalViewController.editSelectedTasks.length -
                            selectedCompleted;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '$selectedIncompleted Incompleted tasks selected - $selectedCompleted Completed tasks selected',
                        style: AppStyles.dateMetaHeader(context),
                      ),
                    );
                  }
                  return _taskStatsWidget(
                      ongoingTasks.length,
                      upcomingTasks.length,
                      completedTasksList.length,
                      overdueTasks.length);
                }),
              ),
            ),
            TabBar(
                controller: _listTabController,
                physics: const NeverScrollableScrollPhysics(),
                isScrollable: false,
                tabs: [
                  Text(
                    "To Do",
                    style: AppStyles.defaultFont.copyWith(fontSize: 14.0),
                  ),
                  FittedBox(
                    child: Text("Completed",
                        style: AppStyles.defaultFont.copyWith(fontSize: 14.0)),
                  ),
                  Text("Overdue",
                      style: AppStyles.defaultFont.copyWith(fontSize: 14.0)),
                  GetBuilder(
                    init: _goalsController,
                    builder: (controller) {
                      return FittedBox(
                        child: Text(
                            "${controller.goalList[_goalViewController.currentGoal.value].documents.length}\nDocuments",
                            textAlign: TextAlign.center,
                            style: AppStyles.defaultFont),
                      );
                    },
                  ),
                ]),
            Expanded(
              child: TabBarView(
                controller: _listTabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _todoList(upcomingTasks.toList()..addAll(ongoingTasks)),
                  _completedList(completedTasksList),
                  _todoList(overdueTasks, reversed: true),
                  _documentList(
                    _goalsController
                        .goalList[_goalViewController.currentGoal.value]
                        .documents,
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _documentList(List<Document> documents) {
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      controller: _taskScrollController,
      padding: EdgeInsets.only(bottom: 20.0 + _scrollOffset, top: 10.0),
      itemCount: documents.length + 1,
      itemBuilder: (context, index) {
        if (index == documents.length) {
          return Container(
            margin: const EdgeInsets.only(top: 10.0),
            height: 20.0,
            alignment: Alignment.bottomCenter,
            color: StateContainer.of(context)?.currTheme.textBackground,
            child: const Text(
              'End of List',
              style: AppStyles.defaultFont,
            ),
          );
        }
        Document doc = documents[index];
        Color bgColor = ColorHelpers.generateColor();
        while (ColorHelpers.checkDarkColor(bgColor)) {
          bgColor = ColorHelpers.generateColor();
        }
        return _documentListItem(context, doc);
      },
    );
  }

  Widget _completedList(Iterable<Task> completedTasks) {
    var comTasks = completedTasks.toList()..sort(Task.prioritySort);
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      controller: _taskScrollController,
      padding: EdgeInsets.only(bottom: 20.0 + _scrollOffset, top: 10.0),
      itemCount: completedTasks.length + 1,
      itemBuilder: (context, index) {
        if (index == comTasks.length) {
          return Container(
            margin: const EdgeInsets.only(top: 10.0),
            height: 20.0,
            alignment: Alignment.bottomCenter,
            color: StateContainer.of(context)?.currTheme.textBackground,
            child: const Text(
              'End of List',
              style: AppStyles.defaultFont,
            ),
          );
        }
        Task task = comTasks.elementAt(index);
        Color bgColor = ColorHelpers.generateColor();
        while (ColorHelpers.checkDarkColor(bgColor)) {
          bgColor = ColorHelpers.generateColor();
        }
        return _goalTaskListItem(context, task);
      },
    );
  }

  Widget _todoList(List<Task> toDoTasks, {bool reversed = false}) {
    toDoTasks.sort(Task.prioritySort);
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      controller: _taskScrollController,
      padding: EdgeInsets.only(bottom: 20.0 + _scrollOffset, top: 10),
      itemCount: toDoTasks.length + 1,
      itemBuilder: (context, index) {
        if (index == toDoTasks.length) {
          return Container(
            margin: const EdgeInsets.only(
              top: 10.0,
            ),
            height: 20.0,
            alignment: Alignment.bottomCenter,
            color: StateContainer.of(context)?.currTheme.textBackground,
            child: const Text(
              'End of List',
              style: AppStyles.defaultFont,
            ),
          );
        }
        Task task = toDoTasks[reversed ? toDoTasks.length - index - 1 : index];
        Color bgColor = ColorHelpers.generateColor();
        while (ColorHelpers.checkDarkColor(bgColor)) {
          bgColor = ColorHelpers.generateColor();
        }
        return _goalTaskListItem(context, task);
      },
    );
  }

  Widget _documentListItem(context, Document doc) {
    Widget item = Container();
    switch (doc.type ?? -1) {
      case 0:
        item = _contactListItem(
          doc,
        );
        break;
      case 1:
        //Video
        item = GestureDetector(
          onTap: () {
            _documentViewerController.openDoc(doc, context);
          },
          child: VideoDocumentWidget(
            doc: doc,
          ),
        );
        break;
      case 2:
        //Text
        item = GestureDetector(
            onTap: () {
              _documentViewerController.openDoc(doc, context);
            },
            child: TextDocumentWidget(
              doc: doc,
              showOptions: true,
            ));
        break;
      case 3:
        //Document
        item = GestureDetector(
            onTap: () {
              _documentViewerController.openDoc(doc, context);
            },
            child: DocumentWidget(
              doc: doc,
            ));
        break;
    }
    return item;
  }

  Widget _contactListItem(Document contact) {
    List<String> details = contact.desc?.split("|") ?? [];
    if (details.length != 3) {
      return _errorListItem();
    }
    bool hasEmail = details[2] != "";
    bool hasPhone = details[1] != "";
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 20.0, right: 20.0),
      child: Material(
        color: Colors.white,
        elevation: 4.0,
        borderRadius: BorderRadius.circular(7.0),
        child: InkWell(
          onTap: () {
            _documentViewerController.openDoc(contact, context);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Contact",
                          style: AppStyles.defaultFont.copyWith(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          details[0],
                          style: AppStyles.defaultFont.copyWith(fontSize: 16.0),
                        ),
                      )
                    ],
                  ),
                ),
                hasPhone
                    ? GestureDetector(
                        onTap: () {
                          launchUrl(Uri(scheme: "tel", path: details[1]));
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          padding: const EdgeInsets.all(7.0),
                          margin: const EdgeInsets.only(left: 10.0),
                          decoration: BoxDecoration(
                            color: StateContainer.of(context)
                                ?.currTheme
                                .darkButton,
                            shape: BoxShape.circle,
                          ),
                          child: FittedBox(
                              child: Icon(
                            Icons.phone,
                            color:
                                StateContainer.of(context)?.currTheme.lightText,
                          )),
                        ),
                      )
                    : Container(),
                hasEmail
                    ? GestureDetector(
                        onTap: () {
                          launchUrl(Uri(scheme: "mailto", path: details[2]));
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          padding: const EdgeInsets.all(7.0),
                          margin: const EdgeInsets.only(left: 10.0),
                          decoration: BoxDecoration(
                            color: StateContainer.of(context)
                                ?.currTheme
                                .darkButton,
                            shape: BoxShape.circle,
                          ),
                          child: FittedBox(
                              child: Icon(
                            Icons.email,
                            color:
                                StateContainer.of(context)?.currTheme.lightText,
                          )),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorListItem() {
    return Container();
  }

  Widget _goalTaskListItem(context, Task task) {
    String actionDate =
        DateTimeHelpers.getDateStr(task.actionDate, dateFormat: 'dd/MM');
    return Stack(
      children: [
        Positioned.fill(
          child: Obx(() {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3.0),
              decoration: BoxDecoration(
                color: _goalViewController.editSelectedTasks
                        .contains(task.uid ?? -2)
                    ? Colors.amberAccent
                    : StateContainer.of(context)?.currTheme.textBackground,
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_goalViewController.isEditing.value) {
                  var index = _goalViewController.editSelectedTasks
                      .indexWhere((element) => element == (task.uid ?? -2));
                  if (index != -1) {
                    _goalViewController.editSelectedTasks.removeAt(index);
                  } else {
                    _goalViewController.editSelectedTasks.add(task.uid ?? -1);
                  }
                }
              },
              onDoubleTap: () async {
                if (!_goalViewController.isUpdating.value) {
                  _goalViewController.isUpdating.value = true;
                  TaskStatus taskStatus =
                      TaskStatus.values[((task.status?.index ?? 0) + 1) % 3];
                  try {
                    if (await _goalsController.editTask(task,
                        status: taskStatus)) {
                      task.status = taskStatus;
                    }
                  } finally {
                    _goalsController.update();
                    _goalViewController.isUpdating.value = false;
                  }
                }
              },
              onLongPress: () => onLongPressTask(task),
              splashColor: StateContainer.of(context)?.currTheme.lightText,
              highlightColor: StateContainer.of(context)?.currTheme.lightText,
              child: Container(
                constraints: const BoxConstraints(minHeight: 50.0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            clipBehavior: Clip.none,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    (task.goal?.name ?? ''),
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
                                Text(
                                  StringConstants
                                      .taskStatus[task.status?.index ?? 0],
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyles.defaultFont.copyWith(
                                    fontSize: AppFontSizes.paragraph,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                    color: StateContainer.of(context)
                                            ?.currTheme
                                            .priorityColors[
                                        task.status?.index ?? 0],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            (task.task ?? ''),
                            style: AppStyles.defaultFont.copyWith(
                              fontSize: AppFontSizes.body,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50.0,
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        task.actionDate == null
                            ? DateTimeConstants.noDate
                            : actionDate,
                        style: AppStyles.defaultFont.copyWith(
                            fontSize: AppFontSizes.body,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalsCarouselWidget(context) {
    return Container(
      height: 248.0,
      width: Get.mediaQuery.size.width,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      decoration: const BoxDecoration(),
      child: GetBuilder(
        init: _goalsController,
        builder: (controller) {
          return PageView.builder(
            scrollDirection: Axis.horizontal,
            controller: _pageController,
            itemCount: controller.goalList.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              Color color = ColorHelpers.generateColor();
              while (ColorHelpers.checkDarkColor(color)) {
                color = ColorHelpers.generateColor();
              }
              return Obx(() {
                bool active = index == _goalViewController.currentGoal.value;
                return GestureDetector(
                  onDoubleTap: () {
                    onDoubleTapGoal();
                  },
                  onLongPress: () {
                    onLongPressGoalAddTask(controller, index);
                  },
                  child: _goalListCard(
                      active,
                      color,
                      controller.goalList[index % controller.goalList.length],
                      context),
                );
              });
            },
          );
        },
      ),
    );
  }

  String _upcomingTask(Goal goal) {
    DateTime now = DateTime.now().dateOnly();

    Task earliestTask = goal.tasks.firstWhere((element) {
      return element.actionDate != null &&
          element.status == TaskStatus.upcoming;
    }, orElse: () => Task());
    if (earliestTask.actionDate == null) {
      Iterable<Task> upcoming = goal.tasks.where((element) {
        return element.status == TaskStatus.upcoming;
      });
      return '${upcoming.length} tasks upcoming';
    } else {
      String nextDate = DateTimeHelpers.getFormattedDate(
          DateTime.fromMillisecondsSinceEpoch(earliestTask.actionDate!),
          dateFormat: ('dd/MM/yy'));
      if (earliestTask.actionDate! < now.millisecondsSinceEpoch) {
        return 'Task overdue on $nextDate';
      }
      if (earliestTask.actionDate! == now.millisecondsSinceEpoch) {
        return 'Next Task starts Today!';
      }
      return 'Next Task starts $nextDate';
    }
  }

  Widget _goalListCard(bool active, Color bgColor, Goal goal, context) {
    const scaleVal = 0.8;
    const animateDuration = Duration(milliseconds: 300);
    return AnimatedContainer(
      duration: animateDuration,
      height: active ? 214.0 : 214.0 * scaleVal,
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: active ? 0 : 12.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [EffectConstants.shadowEffectDown(context)]),
      child: Column(
        children: [
          AnimatedContainer(
            duration: animateDuration,
            height: active ? 82.0 : 82.0 * scaleVal,
            margin: const EdgeInsets.only(bottom: 7.0),
            alignment: Alignment.center,
            child: Text(
              goal.name ?? '',
              style: AppStyles.defaultFont.copyWith(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
                color: ColorHelpers.getInvertColor(bgColor),
              ),
              maxLines: active ? 3 : 2,
            ),
          ),
          AnimatedContainer(
            duration: animateDuration,
            height: active ? 53.0 : 53.0 * scaleVal,
            alignment: Alignment.topLeft,
            child: Text(
              (goal.purpose ?? ''),
              style: AppStyles.defaultFont.copyWith(
                fontSize: AppFontSizes.footNote,
                fontStyle: FontStyle.italic,
                color: ColorHelpers.getInvertColor(bgColor),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: active ? 3 : 2,
            ),
          ),
          const SizedBox(
            height: 4.0,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _dueDateMetadata(context, goal, bgColor),
                    ),
                    Text(
                      _upcomingTask(goal),
                      maxLines: active ? 2 : 1,
                      style: AppStyles.defaultFont.copyWith(
                        fontSize: AppFontSizes.meta,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: ColorHelpers.getInvertColor(bgColor),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (active) {
                    var curr = Get.currentRoute;
                    Get.to(
                      () => AddTaskPage(
                        returnRoute: curr,
                        goal: goal,
                      ),
                    );
                  }
                },
                child: Container(
                  height: 40.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                    color: StateContainer.of(context)?.currTheme.button,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2.5, top: 3.0),
                    child: Icon(
                      AppIcons.add_tasks,
                      color: StateContainer.of(context)?.currTheme.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _dueDateMetadata(
      BuildContext context, Goal goal, Color bgColor) {
    if (goal.dueDate == null || goal.dueDate == 0) {
      return [
        Text(
          "Due in Never",
          style: AppStyles.defaultFont.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: ColorHelpers.getInvertColor(bgColor),
          ),
        ),
      ];
    }

    DateTime? now = DateTimeHelpers.tryParse(
        DateTimeHelpers.getFormattedDate(DateTime.now()));
    var goalDueDate = DateTime.fromMillisecondsSinceEpoch(goal.dueDate!);
    bool isDiffFar = DateTimeHelpers.getDayDifference(now!, goalDueDate) > 200;
    String dueDateStr = DateTimeHelpers.getFormattedDate(
        DateTime.fromMillisecondsSinceEpoch(goal.dueDate ?? 0),
        dateFormat: isDiffFar ? 'MM/yy' : 'dd/MM');
    String dayToDueStr = DateTimeHelpers.getDifferenceStr(now, goalDueDate);

    return [
      Text(
        dayToDueStr,
        style: AppStyles.defaultFont.copyWith(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ),
      ),
      Container(
        height: 3.0,
        width: 3.0,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: StateContainer.of(context)?.currTheme.text,
          shape: BoxShape.circle,
        ),
      ),
      Text(
        dueDateStr,
        style: AppStyles.defaultFont.copyWith(
          fontSize: AppFontSizes.meta,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }
}
