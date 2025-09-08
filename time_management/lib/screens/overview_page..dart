import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_icons.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/notifications_controller.dart';
import 'package:time_management/controllers/routine_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/checklist_item_model.dart';
import 'package:time_management/models/day_plan_item_model.dart';
import 'package:time_management/models/routine_model.dart';
import 'package:time_management/screens/add_routine_page.dart';
import 'package:time_management/screens/day_plan_review_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/loading_page_widget.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with TickerProviderStateMixin {
  final GoalsController _goalsController = Get.find<GoalsController>();

  final NotificationsController _notificationsController =
      Get.find<NotificationsController>();

  final RoutineController _routineController = Get.find<RoutineController>();

  late TabController _tabController;
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        print((arguments as Map)['routineUid']);

        // if ((arguments as Map)['routineUid'] != null) {
        //   Routine? rActionRecv = _routineController.routineList
        //       .firstWhereOrNull((element) =>
        //           element.uid == int.tryParse(arguments['routineUid']));
        //   if ((rActionRecv?.seq ?? -1) >= 5) {
        //     _routineController.generateTaskFromRoutine(
        //         _goalsController, rActionRecv!);
        //   }
        // }
      });
    }

    return Material(
      color: StateContainer.of(context)?.currTheme.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              TabBar(
                  controller: _tabController,
                  tabs: [Tab(text: 'Checklist'), Tab(text: 'Routines')]),
              Expanded(
                child: TabBarView(controller: _tabController, children: [
                  _checklistView(context),
                  _routinesList(),
                ]),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _createRoutineButton(context),
          ),
        ],
      ),
    );
  }

  Widget _checklistView(context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: Text(
            'Checklist for the day',
            style: AppStyles.defaultFont.copyWith(
                fontSize: AppFontSizes.header3, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              GetBuilder(
                init: _goalsController,
                builder: (controller) {
                  DateTime now = DateTime.now().dateOnly();
                  DateTime nextDay =
                      now.add(const Duration(days: 1)).dateOnly();

                  String currDayStr = DateTimeHelpers.getFormattedDate(now,
                      dateFormat: "dd/MM");

                  String nextDayStr = DateTimeHelpers.getFormattedDate(nextDay,
                      dateFormat: "dd/MM");
                  List<DayPlanItem> nextDayPlan =
                      controller.dayPlansList[nextDay.millisecondsSinceEpoch] ??
                          [];
                  bool nextDayHas =
                      nextDayPlan.isNotEmpty && nextDayPlan.first.uid != null;
                  List<DayPlanItem> thisDayPLan =
                      controller.dayPlansList[now.millisecondsSinceEpoch] ?? [];
                  bool thisDayHas =
                      thisDayPLan.isNotEmpty && thisDayPLan.first.uid != null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: StateContainer.of(context)?.currTheme.button,
                        child: InkWell(
                          onTap: () {
                            if (nextDayHas) {
                              var currRoute = Get.currentRoute;
                              Get.to(() => DayPlanReviewPage(
                                    returnRoute: currRoute,
                                    planDate: nextDay,
                                    dayList: nextDayPlan,
                                  ));
                            } else {
                              var currRoute = Get.currentRoute;
                              Get.to(() => DayPlanReviewPage(
                                    returnRoute: currRoute,
                                    planDate: nextDay,
                                  ));
                            }
                          },
                          splashColor: Colors.green,
                          child: Container(
                            width: double.infinity,
                            height: 40.0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 7.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Review Plans for $nextDayStr',
                                    style: AppStyles.defaultFont
                                        .copyWith(fontSize: AppFontSizes.body),
                                  ),
                                ),
                                !nextDayHas
                                    ? const FittedBox(
                                        child:
                                            Icon(Icons.check_box_outline_blank))
                                    : const FittedBox(
                                        child: Icon(Icons.check_box_outlined)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 7.0,
                      ),
                      Material(
                        color: StateContainer.of(context)?.currTheme.button,
                        child: InkWell(
                          onTap: () {
                            if (thisDayHas) {
                              var currRoute = Get.currentRoute;
                              Get.to(() => DayPlanReviewPage(
                                    returnRoute: currRoute,
                                    planDate: now,
                                    dayList: _goalsController.dayPlansList[
                                        now.millisecondsSinceEpoch],
                                  ));
                            } else {
                              var currRoute = Get.currentRoute;
                              Get.to(() => DayPlanReviewPage(
                                    returnRoute: currRoute,
                                    planDate: now,
                                  ));
                            }
                          },
                          splashColor: Colors.green,
                          child: Container(
                            width: double.infinity,
                            height: 40.0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 7.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Review Plans for $currDayStr',
                                    style: AppStyles.defaultFont
                                        .copyWith(fontSize: AppFontSizes.body),
                                  ),
                                ),
                                !thisDayHas
                                    ? const FittedBox(
                                        child:
                                            Icon(Icons.check_box_outline_blank))
                                    : const FittedBox(
                                        child: Icon(Icons.check_box_outlined)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              _checklist(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checklist() {
    return GetBuilder(
        init: _routineController,
        builder: (controller) {
          var routines = controller.routineList.where((routine) {
            if (routine.seq == 0) {
              return true;
            }

            if (routine.endDate != null) {
              DateTime now = DateTime.now();
              DateTime date =
                  DateTime.fromMillisecondsSinceEpoch(routine.endDate!);

              switch (routine.seq) {
                case 1:
                  return (now.dateOnly().difference(date.dateOnly()).inDays %
                          7) ==
                      0;
                case 2:
                  return now.day == date.day;
                case 3:
                  return now.day == date.day && now.month == date.month;
                default:
                  return false;
              }
            }
            return false;
          });

          return ListView.builder(
              shrinkWrap: true,
              itemCount: routines.length,
              itemBuilder: (context, index) {
                return _routineItem(routines.elementAt(index),
                    isCheckList: true);
              });
        });
  }

  Widget _createRoutineButton(context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Center(
        child: Material(
          color: StateContainer.of(context)!.currTheme.darkButton,
          child: InkWell(
            onTap: () async {
              if (await _notificationsController.requestPermission() < 3) {
                //TODO: Show dialog asking to allow permissions to continue
                return;
              } else {
                Get.to(() => AddRoutinePage());
              }
            },
            splashColor: Colors.green,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
              ),
              color: Colors.transparent,
              child: Text(
                'Create Routine',
                style: AppStyles.defaultFont.copyWith(
                    fontSize: AppFontSizes.body,
                    color: StateContainer.of(context)!.currTheme.lightText),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _routineItem(Routine routine, {bool isCheckList = false}) {
    Iterable<ChecklistItem> items = _routineController.checkList
        .where((cl) => (cl.routineUid) == (routine.uid ?? -1));
    return Material(
      child: InkWell(
        onDoubleTap: () async {
          if (isCheckList) {
            await _routineController.checkItem(
              routine.uid!,
              isChecked: items.isNotEmpty,
              checkListId: items.isNotEmpty ? items.first.uid : null,
            );
          }
        },
        onTap: () {
          if (!isCheckList) {
            Get.to(LoadingPageWidget(
              asyncFunc: () async {
                try {
                  await _routineController.deleteRoutine(
                      _notificationsController, _goalsController, routine);
                } on Exception catch (e) {
                  //TODO: show fail
                }
                return;
              },
              onComplete: (_) {
                Get.until((route) => route.isFirst);
              },
            ));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 7.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.defaultFont.copyWith(
                        fontSize: AppFontSizes.body,
                      ),
                    ),
                    Text(
                      (routine.desc ?? ""),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.defaultFont.copyWith(
                        fontSize: AppFontSizes.paragraph,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                routine.endDate != null
                    ? DateTimeHelpers.getFormattedDate(
                        DateTime.fromMillisecondsSinceEpoch(routine.endDate!),
                        dateFormat: "HH:mm")
                    : "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.defaultFont.copyWith(
                  fontSize: AppFontSizes.paragraph,
                ),
              ),
              const SizedBox(
                width: 10.0,
              ),
              !isCheckList
                  ? Container()
                  : items.isNotEmpty
                      ? const FittedBox(
                          child: Icon(Icons.check_box_outlined),
                        )
                      : const FittedBox(
                          child: Icon(Icons.check_box_outline_blank)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routineGroup(Iterable<Routine> routines, String title) {
    if (routines.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        Text(title),
        ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              return _routineItem(routines.elementAt(index));
            }),
      ],
    );
  }

  Widget _routinesList() {
    return GetBuilder(
        init: _routineController,
        builder: (controller) {
          Iterable<Routine> daily = controller.routineList.where((routine) =>
              (routine.seq ?? -1) == 0 || (routine.seq ?? -1) == 5);
          Iterable<Routine> weekly = controller.routineList.where((routine) =>
              (routine.seq ?? -1) == 1 || (routine.seq ?? -1) == 6);
          Iterable<Routine> monthly = controller.routineList.where((routine) =>
              (routine.seq ?? -1) == 2 || (routine.seq ?? -1) == 7);
          Iterable<Routine> yearly = controller.routineList.where((routine) =>
              (routine.seq ?? -1) == 3 || (routine.seq ?? -1) == 8);
          Iterable<Routine> alarm = controller.routineList
              .where((routine) => (routine.seq ?? -1) == 4);
          /*
          .map((routine) {
              return _routineItem(routine);
            }).toList(),
          */
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _routineGroup(daily, "Daily"),
                _routineGroup(weekly, "Weekly"),
                _routineGroup(monthly, "Monthly"),
                _routineGroup(yearly, "Yearly"),
              ]);
        });
  }
}
