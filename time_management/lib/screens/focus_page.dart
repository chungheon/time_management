import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_icons.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/date_time_constants.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/goal_view_controller.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/session_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/session_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/document_view_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/scrolling_options_widget.dart';

class FocusPage extends StatelessWidget {
  FocusPage({super.key, this.returnRoute});
  final GoalsController _goalsController = Get.find();
  final SessionController _sessionController = Get.find();
  final GoalViewController _goalViewController = Get.find();
  final String? returnRoute;
  final RxBool hasFetched = false.obs;

  static final List<Image> _timerImages = [
    Image.asset("assets/png/0.png"),
    Image.asset("assets/png/1.png"),
    Image.asset("assets/png/2.png"),
    Image.asset("assets/png/3.png"),
    Image.asset("assets/png/4.png"),
    Image.asset("assets/png/5.png"),
    Image.asset("assets/png/6.png"),
    Image.asset("assets/png/7.png"),
    Image.asset("assets/png/8.png"),
    Image.asset("assets/png/9.png"),
  ];

  List<Widget> _generateTimer(int timeInSec) {
    int mins = (timeInSec / 60).floor();
    int tenthMins = (mins / 10).floor();
    int onethMins = mins % 10;
    int secs = timeInSec % 60;
    int tenthSecs = (secs / 10).floor();
    int onethSecs = secs % 10;

    return [
      _numberImage(tenthMins),
      _numberImage(onethMins),
      _numberImage(tenthSecs),
      _numberImage(onethSecs)
    ];
  }

  Widget _numberImage(int value) {
    return Container(
      height: 80.0,
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: _timerImages[value],
      ),
    );
  }

  void onTapTimer(SessionController controller) async {
    if (controller.isPaused.value) {
      controller.resumeTimer();
    } else {
      controller.pauseTimer();
    }
  }

  void onTapDecrementTimer(SessionController controller) {
    if (controller.inputTimeMin.value > controller.incrementMin) {
      controller.inputTimeMin.value -= 1;
      controller.timeMinController
          .jumpToPage(controller.inputTimeMin.value - 1);
    }
  }

  void onTapIncrementTimer(SessionController controller) {
    if (controller.inputTimeMin.value < controller.incrementMax) {
      controller.inputTimeMin.value += 1;
      controller.timeMinController
          .jumpToPage(controller.inputTimeMin.value - 1);
    }
  }

  void onTapDecrementBreak(SessionController controller) {
    if (controller.inputBreakMin.value > controller.breakMin) {
      controller.inputBreakMin.value -= 1;
      controller.breakMinController
          .jumpToPage(controller.inputBreakMin.value - 1);
    }
  }

  void onTapIncrementBreak(SessionController controller) {
    if (controller.inputBreakMin.value < controller.breakMax) {
      controller.inputBreakMin.value += 1;
      controller.breakMinController
          .jumpToPage(controller.inputBreakMin.value - 1);
    }
  }

  void onTapStartTimer(SessionController controller) {
    if (controller.timer.value.isActive) {
      controller.endTimer(true);
    } else {
      controller.isSession.value = true;
      controller.startTimer();
    }
  }

  void onTapStartBreak(SessionController controller) {
    if (controller.timer.value.isActive) {
      controller.endTimer(false);
    } else {
      controller.isSession.value = false;
      controller.startTimer();
    }
  }

  void onTapViewStatus(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              height: 300,
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateTimeConstants.days[(DateTimeHelpers.getDayValue(
                            DateTime.now().dateOnly()))] +
                        " " +
                        DateTimeHelpers.getFormattedDate(
                            DateTime.now().dateOnly()),
                    style: AppStyles.defaultFont
                        .copyWith(fontSize: AppFontSizes.header2),
                  ),
                  Text(
                    _sessionController.currentSess.value.breakInterval
                            .toString() +
                        " Minute: " +
                        _sessionController.currentSess.value.breakCount
                            .toString() +
                        " Breaks",
                    style: AppStyles.defaultFont
                        .copyWith(fontSize: AppFontSizes.header3),
                  ),
                  Expanded(
                    child: ListView.builder(
                        itemCount: _sessionController.sessCounter.length,
                        itemBuilder: (context, index) => _counterListItem(
                            _sessionController.sessCounter.elementAt(index))),
                  )
                ],
              ),
            ),
          );
        });
  }

  Widget _counterListItem(SessionCounter counter) {
    return Container(
        child: Text(
      counter.sessionInterval.toString() +
          " Minute: " +
          counter.sessionCount.toString() +
          " Sessions",
      style: AppStyles.defaultFont.copyWith(fontSize: AppFontSizes.body),
    ));
  }

  void notificationRoute(BuildContext context) {
    hasFetched.value = true;
    bool hasArgs = ModalRoute.of(context)!.settings.arguments != null;
    if (!hasArgs) {
      return;
    }
    Map<String, String> routeArgs =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      String? uid = routeArgs['uid'];
      bool isSession = !(routeArgs['session'] == null);
      bool isBreak = !(routeArgs['break'] == null);
      int totalTime = int.tryParse(routeArgs['session'].toString()) ?? 30;
      int updateNum = int.tryParse(routeArgs['total'].toString()) ?? 0;
      if (isBreak) {
        totalTime = int.tryParse(routeArgs['break'].toString()) ?? 5;
        _sessionController.inputBreakMin.value = totalTime;
      }

      if (isSession) {
        _sessionController.inputTimeMin.value = totalTime;
      }

      _sessionController.resetTimer(totalTime, !isBreak);
      if (uid != null) {
        _sessionController.fetchSessionWithUid(
            uid, !isBreak, totalTime, updateNum);
      }
    });
    hasFetched.value = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasFetched.value) {
      notificationRoute(context);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (pop, _) {
        if (!pop) {
          showDialog(
            context: context,
            builder: (_) => DialogConstants.exitDialog(
                returnRoute: returnRoute,
                msg: "Exit Focus Mode?",
                onConfirm: () async {
                  _sessionController.timer.value.cancel();
                  _sessionController.removeNotification(
                      _sessionController.currentNotifId.value);
                }),
          );
        }
      },
      child: Scaffold(
        appBar: PageHeaderWidget(
          title: 'Focus',
          exitDialog: DialogConstants.exitDialog(
              returnRoute: returnRoute,
              msg: "Exit Focus Mode?",
              onConfirm: () async {
                _sessionController.timer.value.cancel();
                _sessionController.removeNotification(
                    _sessionController.currentNotifId.value);
              }),
          additionalAction: [
            InkWell(
              child: const Material(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(Icons.copy)),
              ),
              onTap: () => onTapViewStatus(context),
            ),
          ],
        ),
        body: GetBuilder(
            init: _sessionController,
            builder: (controller) {
              return Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20.0,
                      ),
                      Obx(
                        () => GestureDetector(
                          onTap: () => onTapTimer(controller),
                          child: Stack(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ..._generateTimer(
                                      controller.sessionSecs.value),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Obx(
                                  () => Opacity(
                                    opacity: _sessionController.isPaused.value
                                        ? 1
                                        : 0,
                                    child: Center(
                                        child: Text(
                                      "-PAUSED-",
                                      style: AppStyles.defaultFont.copyWith(
                                          fontSize: 50.0, color: Colors.grey),
                                    )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  onTapDecrementTimer(_sessionController),
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.minimize,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "Session:",
                            style: AppStyles.defaultFont.copyWith(
                                fontSize: 25.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            width: 5.0,
                          ),
                          SizedBox(
                            width: 90.0,
                            child: ScrollingOptionsWidget(
                              options: [
                                for (int i = 1; i <= 120; i++) i.toString()
                              ],
                              controller: controller.timeMinController,
                              initialValue: controller.inputTimeMin.value - 1,
                              onChanged: (index) {
                                controller.inputTimeMin.value = index + 1;
                                controller.initialSecs.value =
                                    (controller.inputTimeMin.value * 60);
                              },
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => onTapIncrementTimer(controller),
                              child: Container(
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.add,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      GestureDetector(
                        onTap: () => onTapStartTimer(controller),
                        child: Container(
                          height: 50.0,
                          decoration: BoxDecoration(
                              color: StateContainer.of(Get.context!)
                                  ?.currTheme
                                  .darkButton),
                          child: Center(
                            child: GetBuilder(
                              init: controller,
                              builder: (controller) => Text(
                                controller.isSession.value
                                    ? controller.timer.value.isActive
                                        ? "Stop"
                                        : "Start"
                                    : "Start",
                                style: AppStyles.actionButtonText(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => onTapDecrementBreak(controller),
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.minimize,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            "Break:",
                            style: AppStyles.defaultFont.copyWith(
                                fontSize: 25.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            width: 5.0,
                          ),
                          SizedBox(
                            width: 90.0,
                            child: ScrollingOptionsWidget(
                              options: [
                                for (int i = 1; i <= 30; i++) i.toString()
                              ],
                              controller: controller.breakMinController,
                              initialValue: controller.inputBreakMin.value - 1,
                              onChanged: (index) {
                                controller.inputBreakMin.value = index + 1;
                                controller.initialSecs.value =
                                    (controller.inputBreakMin.value * 60);
                              },
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => onTapIncrementBreak(controller),
                              child: Container(
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: const Icon(
                                  Icons.add,
                                  size: 30.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      GestureDetector(
                        onTap: () => onTapStartBreak(controller),
                        child: Container(
                          height: 50.0,
                          decoration: BoxDecoration(
                              color: StateContainer.of(Get.context!)
                                  ?.currTheme
                                  .darkButton),
                          child: Center(
                            child: GetBuilder(
                              init: _sessionController,
                              builder: (controller) => Text(
                                _sessionController.isSession.value
                                    ? "Start Break"
                                    : _sessionController.timer.value.isActive
                                        ? "Stop Break"
                                        : "Start Break",
                                style: AppStyles.actionButtonText(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.items.length,
                      itemBuilder: (context, index) {
                        return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: _dayPlanListItem(
                                controller.items[index], context));
                      },
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }

  Widget _dayPlanListItem(
    DayPlanItem dayItem,
    context,
  ) {
    Task task = dayItem.task ?? Task();
    String startDate = DateTimeHelpers.getFormattedDate(
      DateTime.fromMillisecondsSinceEpoch(task.actionDate ?? 0),
      dateFormat: ('dd/MM'),
    );

    return GestureDetector(
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
        margin: const EdgeInsets.only(bottom: 15.0),
        decoration: BoxDecoration(
          color: StateContainer.of(context)?.currTheme.background,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            EffectConstants.shadowEffectDown(context),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: StateContainer.of(context)
                ?.currTheme
                .priorityColors[task.status?.index ?? 0]
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: StateContainer.of(context)?.currTheme.hintText,
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
                    Text(
                      task.actionDate == null
                          ? DateTimeConstants.noDate
                          : startDate,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.defaultFont.copyWith(
                        fontSize: AppFontSizes.paragraph,
                        fontStyle: FontStyle.italic,
                        color: StateContainer.of(context)?.currTheme.hintText,
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
                    Text(
                      StringConstants
                          .taskPriorities[dayItem.taskPriority?.index ?? 0],
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.defaultFont.copyWith(
                        fontSize: AppFontSizes.paragraph,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: StateContainer.of(context)
                            ?.currTheme
                            .priorityColors[dayItem.taskPriority?.index ?? 0],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (task.task ?? ''),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.defaultFont.copyWith(
                          fontSize: AppFontSizes.header3,
                          fontWeight: FontWeight.bold,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.underline),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Material(
                      color: StateContainer.of(context)?.currTheme.button,
                      shape: const CircleBorder(),
                      child: InkWell(
                        splashColor:
                            StateContainer.of(context)?.currTheme.splashEffect,
                        customBorder: const CircleBorder(),
                        onTap: () {
                          Get.to(() => DocumentViewPage(task: task));
                        },
                        child: Container(
                          width: 45.0,
                          height: 45.0,
                          padding: const EdgeInsets.all(9.0),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: FittedBox(
                              child: Icon(
                            AppIcons.document,
                            color: StateContainer.of(context)?.currTheme.text,
                          )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
