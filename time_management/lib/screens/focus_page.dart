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
import 'package:time_management/controllers/notifications_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/document_view_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/scrolling_options_widget.dart';

class FocusPage extends StatelessWidget {
  FocusPage({super.key, this.returnRoute, required this.dayPlanItems}) {
    _initialSecs.value = _inputTimeMin.value * 60;
    _sessionSecs.value = _initialSecs.value;
    _timer.value.cancel();
  }
  final NotificationsController _notificationsController = Get.find();
  final GoalsController _goalsController = Get.find();
  final GoalViewController _goalViewController = Get.find();
  final String? returnRoute;
  final List<DayPlanItem> dayPlanItems;
  final RxInt _sessionSecs = RxInt(1800);
  final RxInt _initialSecs = RxInt(1800);
  final Rx<Timer> _timer = Rx<Timer>(Timer(Duration.zero, () {}));
  final RxInt _sessions = RxInt(0);
  final RxInt _inputTimeMin = RxInt(30);
  final RxInt _inputBreakMin = RxInt(5);
  final PageController _timeMinController = PageController();
  final PageController _breakMinController = PageController();
  final RxBool _isSession = true.obs;
  final RxBool _isPaused = false.obs;

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

  @override
  Widget build(BuildContext context) {
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
                  _timer.value.cancel();
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
                _timer.value.cancel();
              }),
        ),
        body: GetBuilder(
            init: _goalsController,
            builder: (controller) {
              return ListView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20.0,
                      ),
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            if (_timer.value.isActive) {
                              _isPaused.value = true;
                              _timer.value.cancel();
                            } else {
                              _isPaused.value = false;
                              _timer.value = Timer.periodic(
                                  const Duration(seconds: 1), (_) {
                                _sessionSecs.value -= 1;
                                if (_sessionSecs.value == 0) {
                                  _initialSecs.value =
                                      (_inputTimeMin.value * 60);
                                  _sessionSecs.value = _initialSecs.value;
                                  _notificationsController
                                      .showNotificationInstant("TIME UP!",
                                          "FINISHED ${_initialSecs.value} SECS");
                                  _timer.value.cancel();
                                }
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ..._generateTimer(_sessionSecs.value),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Obx(
                                  () => Opacity(
                                    opacity: _isPaused.value ? 1 : 0,
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
                              onTap: () {
                                if (_inputTimeMin.value > 1) {
                                  _inputTimeMin.value -= 1;
                                  _timeMinController
                                      .jumpToPage(_inputTimeMin.value - 1);
                                }
                              },
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
                              controller: _timeMinController,
                              initialValue: _inputTimeMin.value - 1,
                              onChanged: (index) {
                                _inputTimeMin.value = index + 1;
                                _initialSecs.value = (_inputTimeMin.value * 60);
                              },
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_inputTimeMin.value < 120) {
                                  _inputTimeMin.value += 1;
                                  _timeMinController
                                      .jumpToPage(_inputTimeMin.value - 1);
                                }
                              },
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
                      Container(
                        height: 50.0,
                        decoration: BoxDecoration(
                            color: StateContainer.of(Get.context!)
                                ?.currTheme
                                .darkButton),
                        child: GestureDetector(
                          onTap: () {
                            if (_timer.value.isActive || _isPaused.value) {
                              if (_isSession.value) {
                                _timer.value.cancel();
                                _timer.value = Timer(Duration.zero, () {});
                                _initialSecs.value = (_inputTimeMin.value * 60);
                                _sessionSecs.value = _initialSecs.value;
                              }
                              _isPaused.value = false;
                            } else {
                              _timer.value.cancel();
                              _isSession.value = true;
                              _initialSecs.value = (_inputTimeMin.value * 60);
                              _sessionSecs.value = _initialSecs.value;
                              _timer.value = Timer.periodic(
                                  const Duration(seconds: 1), (_) {
                                _sessionSecs.value -= 1;
                                if (_sessionSecs.value == 0) {
                                  _initialSecs.value =
                                      (_inputTimeMin.value * 60);
                                  _sessionSecs.value = _initialSecs.value;
                                  _notificationsController
                                      .showNotificationInstant("TIME UP!",
                                          "FINISHED ${_initialSecs.value} SECS");
                                  _timer.value.cancel();
                                }
                              });
                            }
                          },
                          child: Center(
                            child: Obx(
                              () => Text(
                                _isSession.value
                                    ? _timer.value.isActive
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
                              onTap: () {
                                if (_inputBreakMin.value > 1) {
                                  _inputBreakMin.value -= 1;
                                  _breakMinController
                                      .jumpToPage(_inputBreakMin.value - 1);
                                }
                              },
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
                              controller: _breakMinController,
                              initialValue: _inputBreakMin.value - 1,
                              onChanged: (index) {
                                _inputBreakMin.value = index + 1;
                                _initialSecs.value =
                                    (_inputBreakMin.value * 60);
                              },
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_inputBreakMin.value < 30) {
                                  _inputBreakMin.value += 1;
                                  _breakMinController
                                      .jumpToPage(_inputBreakMin.value - 1);
                                }
                              },
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
                      Container(
                        height: 50.0,
                        decoration: BoxDecoration(
                            color: StateContainer.of(Get.context!)
                                ?.currTheme
                                .darkButton),
                        child: GestureDetector(
                          onTap: () {
                            if (_timer.value.isActive || _isPaused.value) {
                              if (!_isSession.value) {
                                _timer.value.cancel();
                                _timer.value = Timer(Duration.zero, () {});
                                _initialSecs.value =
                                    (_inputBreakMin.value * 60);
                                _sessionSecs.value = _initialSecs.value;
                              }
                              _isPaused.value = false;
                            } else {
                              _timer.value.cancel();
                              _isSession.value = false;
                              _initialSecs.value = (_inputBreakMin.value * 60);
                              _sessionSecs.value = _initialSecs.value;
                              _timer.value = Timer.periodic(
                                  const Duration(seconds: 1), (_) {
                                _sessionSecs.value -= 1;
                                if (_sessionSecs.value == 0) {
                                  _initialSecs.value =
                                      (_inputTimeMin.value * 60);
                                  _sessionSecs.value = _initialSecs.value;
                                  _notificationsController
                                      .showNotificationInstant("TIME UP!",
                                          "FINISHED ${_initialSecs.value} SECS");
                                  _timer.value.cancel();
                                }
                              });
                            }
                          },
                          child: Center(
                            child: Obx(
                              () => Text(
                                _isSession.value
                                    ? "Start Break"
                                    : _timer.value.isActive
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
                  ...[
                    for (var dayPlanItem in dayPlanItems)
                      Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: _dayPlanListItem(dayPlanItem, context))
                  ],
                  const SizedBox(
                    height: 30.0,
                  ),
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
                      (task.task ?? '') ,
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
                        onLongPress: () {},
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
