import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/date_time_constants.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/view_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/styles.dart';

class DateHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  DateHeaderWidget({super.key, this.update});
  final ViewController _viewController = Get.find<ViewController>();
  final GoalsController _goalsController = Get.find<GoalsController>();
  final Function()? update;
  @override
  Size get preferredSize => const Size.fromHeight(80.0);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        update?.call();
        _goalsController.goalList.sort(Goal.prioritySort);
        _goalsController.update();
      },
      child: GetBuilder(
        init: _viewController,
        builder: (viewController) {
          if (viewController.currDate.value == null) {
            return Container();
          }
          return Column(
            children: [
              Container(
                color: StateContainer.of(context)?.currTheme.background,
                padding:
                    const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Obx(
                          () => Text(
                            DateFormat('dd/MM/yy')
                                .format(_viewController.currDate.value!),
                            style: AppStyles.dateHeader(context),
                          ),
                        ),
                        const SizedBox(
                          width: 2.0,
                        ),
                        Obx(
                          () => Text(
                            DateTimeHelpers.getDayValueStr(
                                _viewController.currDate.value!),
                            style: AppStyles.subDateHeader(context),
                          ),
                        ),
                      ],
                    ),
                    GetBuilder(
                      init: _goalsController,
                      builder: (controller) {
                        if (_viewController.currDate.value == null) {
                          return Container();
                        }
                        int now = _viewController
                            .currDate.value!.millisecondsSinceEpoch;
                        List<DayPlanItem> dayPlanList =
                            controller.dayPlansList[now] ?? [];
                        int upcoming = dayPlanList
                            .where((e) => e.task?.status == TaskStatus.upcoming)
                            .length;
                        int ongoing = dayPlanList
                            .where((e) => e.task?.status == TaskStatus.ongoing)
                            .length;

                        int completed = dayPlanList
                            .where(
                                (e) => e.task?.status == TaskStatus.completed)
                            .length;
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$upcoming ${StringConstants.taskStatus[0]}',
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.defaultFont.copyWith(
                                  fontSize: AppFontSizes.paragraph,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: StateContainer.of(context)
                                      ?.currTheme
                                      .priorityColors[0],
                                ),
                              ),
                            ),
                            Container(
                              height: 3.0,
                              width: 3.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                color: StateContainer.of(context)
                                    ?.currTheme
                                    .hintText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              '$ongoing ${StringConstants.taskStatus[1]}',
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.defaultFont.copyWith(
                                fontSize: AppFontSizes.paragraph,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: StateContainer.of(context)
                                    ?.currTheme
                                    .priorityColors[1],
                              ),
                            ),
                            Container(
                              height: 3.0,
                              width: 3.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                color: StateContainer.of(context)
                                    ?.currTheme
                                    .hintText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              '$completed ${StringConstants.taskStatus[2]}',
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.defaultFont.copyWith(
                                fontSize: AppFontSizes.paragraph,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: StateContainer.of(context)
                                    ?.currTheme
                                    .priorityColors[2],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
