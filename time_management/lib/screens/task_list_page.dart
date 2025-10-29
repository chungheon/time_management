import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:time_management/app_icons.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/date_time_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/add_task_page.dart';
import 'package:time_management/screens/document_view_page.dart';
import 'package:time_management/screens/edit_task_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/loading_page_widget.dart';

class TaskListPage extends StatelessWidget {
  final RxString result = "".obs;
  final GoalsController _goalsController = Get.find();
  final RxBool isUpdating = false.obs;
  final Rx<Timer> timer = Timer(Duration.zero, () {}).obs;
  final RxInt timerCountdown = 0.obs;

  TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StateContainer.of(context)?.currTheme.background,
      child: Stack(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: [
                Expanded(
                    child: GetBuilder(
                  init: _goalsController,
                  builder: (controller) {
                    int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
                    List<DayPlanItem>? dayPlanList =
                        controller.dayPlansList[now] ?? [];
                    if (dayPlanList.isNotEmpty) {
                      return ListView.builder(
                          itemCount: dayPlanList.length + 1,
                          itemBuilder: (context, index) {
                            if (index == dayPlanList.length) {
                              return Container(
                                margin: const EdgeInsets.only(top: 40.0),
                                height: 20.0,
                                alignment: Alignment.bottomCenter,
                                color: StateContainer.of(context)
                                    ?.currTheme
                                    .textBackground,
                                child: const Text(
                                  'End of List',
                                  style: AppStyles.defaultFont,
                                ),
                              );
                            }
                            DayPlanItem? item = dayPlanList[index];
                            return _dayPlanListItem(item, index, context);
                          });
                    }
                    return const Center(
                      child: Text(
                        "No Tasks Created",
                        style: AppStyles.defaultFont,
                      ),
                    );
                  },
                )),
              ],
            ),
          ),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: Material(
              color: StateContainer.of(context)?.currTheme.button,
              shape: const CircleBorder(),
              elevation: 4.0,
              child: InkWell(
                onTap: () {
                  var currRoute = Get.currentRoute;
                  Get.to(() => AddTaskPage(
                        returnRoute: currRoute,
                        onCreateComplete: (taskUid) {
                          Get.to(() => LoadingPageWidget(
                                onComplete: (_) async {
                                  Get.until(
                                    (route) => route.settings.name == currRoute,
                                  );
                                },
                                asyncFunc: () async {
                                  int now = DateTime.now()
                                      .dateOnly()
                                      .millisecondsSinceEpoch;
                                  if (taskUid != null &&
                                      (_goalsController.dayPlansList[now] ?? [])
                                          .isNotEmpty) {
                                    await _goalsController.addDayPlanItem(taskUid);
                                    await _goalsController.refreshPlanList();
                                    _goalsController.update();
                                  }
                                  return;
                                },
                              ));
                        },
                      ));
                },
                customBorder: const CircleBorder(),
                child: Container(
                  height: 50.0,
                  width: 50.0,
                  padding: const EdgeInsets.only(
                      left: 11.0, right: 8.0, top: 10.0, bottom: 8.0),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: FittedBox(
                    child: Icon(
                      AppIcons.add_tasks,
                      color: StateContainer.of(context)?.currTheme.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayPlanListItem(DayPlanItem dayItem, int index, context) {
    Task task = dayItem.task ?? Task();
    String startDate = DateTimeHelpers.getFormattedDate(
      DateTime.fromMillisecondsSinceEpoch(task.actionDate ?? 0),
      dateFormat: ('dd/MM'),
    );
    return GestureDetector(
      onLongPress: () {
        Get.to(() => EditTaskPage(
              task: task,
            ));
      },
      onDoubleTap: () async {
        if (!isUpdating.value) {
          isUpdating.value = true;
          TaskStatus taskStatus =
              TaskStatus.values[((task.status?.index ?? 0) + 1) % 3];
          if (await _goalsController.editTask(task, status: taskStatus)) {
            task.status = taskStatus;
          }
          _goalsController.update();
          isUpdating.value = false;
          if (!timer.value.isActive) {
            timer.value =
                Timer.periodic(const Duration(milliseconds: 500), (timer) {
              timerCountdown.value++;
              if (timerCountdown.value >= 6) {
                timerCountdown.value = 0;
                this.timer.value.cancel();
                int now = DateTime.now().dateOnly().millisecondsSinceEpoch;
                _goalsController.dayPlansList[now]
                    ?.sort(DayPlanItem.prioritySort);
                _goalsController.update();
                Fluttertoast.cancel();
                Fluttertoast.showToast(
                    msg: "Updated", toastLength: Toast.LENGTH_SHORT);
              } else if (timerCountdown.value % 2 == 1) {
                Fluttertoast.cancel();
                Fluttertoast.showToast(
                    msg: ((timerCountdown / 2).floor() + 1).toString(),
                    toastLength: Toast.LENGTH_SHORT);
              }
            });
          } else {
            timerCountdown.value = 0;
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        decoration: BoxDecoration(
            color: StateContainer.of(context)?.currTheme.background,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              EffectConstants.shadowEffectDown(context),
            ]),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: StateContainer.of(context)
                ?.currTheme
                .priorityColors[task.status?.index ?? 0]
                .withOpacity(0.1),
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.defaultFont.copyWith(
                          fontSize: AppFontSizes.body,
                          decoration: TextDecoration.underline),
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

//   Widget _taskListItem(Task task, int index, context) {
//     String startDate = DateTimeHelpers.getFormattedDate(
//       DateTime.fromMillisecondsSinceEpoch(task.actionDate ?? 0),
//       dateFormat: ('dd/MM'),
//     );
//     return GestureDetector(
//       onDoubleTap: () async {
//         if (!isUpdating.value) {
//           isUpdating.value = true;
//           TaskStatus taskStatus =
//               TaskStatus.values[((task.status?.index ?? 0) + 1) % 3];
//           if (await _goalsController.editTask(task, status: taskStatus) !=
//               null) {
//             task.status = taskStatus;
//           }
//           _goalsController.update();
//           isUpdating.value = false;
//         }
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10.0),
//         decoration: BoxDecoration(
//             color: StateContainer.of(context)?.currTheme.background,
//             borderRadius: BorderRadius.circular(15.0),
//             boxShadow: [
//               EffectConstants.shadowEffectDown(context),
//             ]),
//         child: Container(
//           padding: const EdgeInsets.all(20.0),
//           decoration: BoxDecoration(
//             color: StateContainer.of(context)
//                 ?.currTheme
//                 .priorityColors[task.status?.index ?? 0]
//                 .withOpacity(0.1),
//             borderRadius: BorderRadius.circular(15.0),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 clipBehavior: Clip.none,
//                 child: Row(
//                   children: [
//                     Flexible(
//                       child: Text(
//                         (task.goal?.name ?? ''),
//                         overflow: TextOverflow.ellipsis,
//                         style: AppStyles.defaultFont.copyWith(
//                           fontSize: AppFontSizes.paragraph,
//                           fontStyle: FontStyle.italic,
//                           color: StateContainer.of(context)?.currTheme.hintText,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       height: 3.0,
//                       width: 3.0,
//                       margin: const EdgeInsets.symmetric(horizontal: 5.0),
//                       decoration: BoxDecoration(
//                         color: StateContainer.of(context)?.currTheme.hintText,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     Text(
//                       task.actionDate == null
//                           ? DateTimeConstants.noDate
//                           : startDate,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppStyles.defaultFont.copyWith(
//                         fontSize: AppFontSizes.paragraph,
//                         fontStyle: FontStyle.italic,
//                         color: StateContainer.of(context)?.currTheme.hintText,
//                       ),
//                     ),
//                     Container(
//                       height: 3.0,
//                       width: 3.0,
//                       margin: const EdgeInsets.symmetric(horizontal: 5.0),
//                       decoration: BoxDecoration(
//                         color: StateContainer.of(context)?.currTheme.hintText,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     Text(
//                       StringConstants.taskStatus[task.status?.index ?? 0],
//                       overflow: TextOverflow.ellipsis,
//                       style: AppStyles.defaultFont.copyWith(
//                         fontSize: AppFontSizes.paragraph,
//                         fontStyle: FontStyle.italic,
//                         fontWeight: FontWeight.bold,
//                         color: StateContainer.of(context)
//                             ?.currTheme
//                             .priorityColors[task.status?.index ?? 0],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       (task.task ?? ''),
//                       maxLines: 3,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppStyles.defaultFont.copyWith(
//                           fontSize: AppFontSizes.body,
//                           decoration: TextDecoration.underline),
//                     ),
//                   ),
//                   Container(
//                     margin: const EdgeInsets.only(left: 10.0),
//                     width: 45.0,
//                     height: 45.0,
//                     padding: const EdgeInsets.all(9.0),
//                     decoration: BoxDecoration(
//                       color: StateContainer.of(context)?.currTheme.button,
//                       shape: BoxShape.circle,
//                     ),
//                     child: FittedBox(
//                         child: Icon(
//                       AppIcons.document,
//                       color: StateContainer.of(context)?.currTheme.text,
//                     )),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
}
