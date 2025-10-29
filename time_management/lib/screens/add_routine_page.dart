import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/constants/string_constants.dart';
import 'package:time_management/controllers/notifications_controller.dart';
import 'package:time_management/controllers/routine_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/input_text_field.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';

class AddRoutinePage extends StatelessWidget {
  AddRoutinePage({super.key, this.returnRoute});
  final RoutineController _routineController = Get.find<RoutineController>();
  final NotificationsController _notificationsController =
      Get.find<NotificationsController>();
  final String? returnRoute;
  final RxInt sequence = 0.obs;
  final RxString name = "".obs;
  final RxString desc = "".obs;
  final FocusNode nameNode = FocusNode();
  final FocusNode descNode = FocusNode();
  final Rxn<DateTime> date = Rxn<DateTime>();
  final Rxn<DateTime> reminderDate = Rxn<DateTime>();
  final Rxn<TimeOfDay> selectedTime = Rxn<TimeOfDay>();
  final RxString timeStr = "".obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeaderWidget(
        title: "Add Routine",
        exitDialog: DialogConstants.exitDialog(
          returnRoute: returnRoute,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                InputTextField(
                  title: 'Routine Name',
                  hintText: 'Give a name',
                  initialValue: name.value,
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
                  focusNode: nameNode,
                  nextFocus: descNode,
                  onChanged: (String nameStr) {
                    name.value = nameStr;
                  },
                ),
                InputTextField(
                  title: 'Routine Description',
                  hintText: "Describe the routine",
                  initialValue: desc.value,
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
                  maxLines: 5,
                  focusNode: descNode,
                  onChanged: (String descStr) {
                    desc.value = descStr;
                  },
                ),
                _sequenceSelection(context),
                const SizedBox(
                  height: 10.0,
                ),
                _settings(context),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            decoration: BoxDecoration(
                color: StateContainer.of(context)?.currTheme.background,
                boxShadow: [EffectConstants.shadowEffectUp(context)]),
            child: Material(
              color: StateContainer.of(context)?.currTheme.darkButton,
              borderRadius: BorderRadius.circular(8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () async {
                  Get.off(LoadingPageWidget(
                    asyncFunc: () async {
                      if (sequence.value == 0) {
                        await _routineController.createRoutine(
                            _notificationsController,
                            sequence.value,
                            DateTime.now().dateOnly(),
                            name: name.value,
                            desc: desc.value,
                            timeOfDay: selectedTime.value);
                      } else {
                        await _routineController.createRoutine(
                          _notificationsController,
                          sequence.value,
                          date.value?.dateOnly() ?? DateTime.now().dateOnly(),
                          name: name.value,
                          desc: desc.value,
                          timeOfDay: selectedTime.value,
                          startDate:
                              sequence.value > 2 ? reminderDate.value : null,
                        );
                      }
                      await _routineController.refreshList();
                      return;
                    },
                    onComplete: (_) {
                      Get.until((route) => route.isFirst);
                    },
                  ));
                },
                splashColor: StateContainer.of(context)?.currTheme.splashEffect,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  color: Colors.transparent,
                  child: Center(
                    child: Text(
                      "Create New Routine",
                      style: AppStyles.actionButtonText(context),
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

  Widget _settings(BuildContext context) {
    return Obx(() {
      List<Widget> children = [_timeSelection(context)];
      DateTime now = DateTime.now().dateOnly();
      switch (sequence.value) {
        case 0:
          break;
        case 1:
          children.add(_dateSelection(context,
              initialDate: now,
              startDateRange: now.subtract(const Duration(days: 7)),
              endDateRange: now.add(const Duration(days: 7))));
          break;
        case 2:
          children.add(_dateSelection(context,
              initialDate: now,
              startDateRange: now.subtract(const Duration(days: 31)),
              endDateRange: now.add(const Duration(days: 31))));
          children.add(_reminderStartDateSelection(
              initialDate: now,
              startDateRange: now.subtract(const Duration(days: 31)),
              endDateRange: now.add(const Duration(days: 31))));
          break;
        case 3:
          children.add(_dateSelection(context,
              initialDate: now,
              startDateRange: now.subtract(const Duration(hours: 8760)),
              endDateRange: now.add(const Duration(hours: 8760))));
          children.add(_reminderStartDateSelection(
              initialDate: now,
              startDateRange: now.subtract(const Duration(hours: 8760)),
              endDateRange: now.add(const Duration(hours: 8760))));
          break;
        case 4:
          children.add(_dateSelection(context,
              initialDate: now,
              startDateRange: now.subtract(const Duration(hours: 8760)),
              endDateRange: now.add(const Duration(hours: 8760))));
          break;
      }
      return Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    });
  }

  Widget _timeSelection(BuildContext context) {
    TimeOfDay now = TimeOfDay.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Time of Notification (Default: 6AM)",
          style: AppStyles.defaultFont.copyWith(
              fontSize: AppFontSizes.body, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 5.0,
        ),
        Row(
          children: [
            Expanded(
              child: InputTextField(
                hintText: "HH:mm",
                initialValue: (selectedTime.value?.timeFormat()),
                onChanged: (time) {
                  timeStr.value = time;
                },
              ),
            ),
            GestureDetector(
              onTap: () async {
                TimeOfDay? timeSelected = await showTimePicker(
                  context: context,
                  initialTime: now,
                );
                if (timeSelected != null) {
                  selectedTime.value = timeSelected;
                }
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                width: 50.0,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: const FittedBox(child: Icon(Icons.punch_clock_rounded)),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10.0,
        ),
      ],
    );
  }

  Widget _reminderStartDateSelection(
      {DateTime? endDateRange,
      DateTime? startDateRange,
      DateTime? initialDate}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InputTextField(
        title: "Reminder Start Date",
        hintText: "Date to Start",
        inputType: TextInputType.datetime,
        initialValue: reminderDate.value == null
            ? ""
            : DateTimeHelpers.getFormattedDate(reminderDate.value!),
        initialDate: initialDate,
        startDateRange: startDateRange,
        endDateRange: endDateRange,
        onChanged: (String rDate) {
          reminderDate.value = DateTimeHelpers.tryParse(rDate);
        },
      ),
    );
  }

  Widget _dateSelection(context,
      {DateTime? endDateRange,
      DateTime? startDateRange,
      DateTime? initialDate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InputTextField(
          title: "Date",
          hintText: "Date of Routine",
          inputType: TextInputType.datetime,
          initialValue: date.value == null
              ? ""
              : DateTimeHelpers.getFormattedDate(date.value!),
          initialDate: initialDate,
          startDateRange: startDateRange,
          endDateRange: endDateRange,
          onChanged: (String routineDate) {
            date.value = DateTimeHelpers.tryParse(routineDate);
            print("Changed Date ${date.value}");
          },
        ),
        const SizedBox(
          height: 10.0,
        ),
      ],
    );
  }

  Widget _sequenceSelection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: GestureDetector(
            onDoubleTap: () {
              sequence.value += 1;
              sequence.value %= StringConstants.routineSequence.length;
            },
            child: Obx(
              () => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.0),
                    border: Border.all()),
                child: Text(
                  StringConstants.routineSequence[sequence.value],
                  style: AppStyles.defaultFont.copyWith(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
            onTap: () async {
              var currVal = sequence.value;
              var currentRoute = ModalRoute.of(context)!.settings.name;
              await showDialog(
                  context: Get.context!,
                  builder: (context) {
                    return Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Routine Type:",
                            style: AppStyles.defaultFont.copyWith(
                              fontSize: AppFontSizes.body,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ScrollingOptionsWidget(
                            options: StringConstants.routineSequence,
                            initialValue: sequence.value,
                            onChanged: (index) {
                              currVal = index;
                            },
                          ),
                          SizedBox(
                            height: 50.0,
                            child: GestureDetector(
                              onTap: () {
                                sequence.value = currVal;
                                Get.until((route) =>
                                    route.settings.name == currentRoute);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    left: 20.0,
                                    right: 20.0,
                                    bottom: 10.0,
                                    top: 10.0),
                                decoration: BoxDecoration(
                                    color: StateContainer.of(context)!
                                        .currTheme
                                        .darkButton),
                                alignment: Alignment.center,
                                child: Text(
                                  'Select',
                                  style: AppStyles.defaultFont.copyWith(
                                    fontSize: AppFontSizes.body,
                                    color: StateContainer.of(context)!
                                        .currTheme
                                        .lightText,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  });
            },
            child: Container(
                height: 40.0,
                width: 40.0,
                margin: const EdgeInsets.only(left: 5.0),
                child: const FittedBox(child: Icon(Icons.list_alt_outlined))))
      ]),
    );
  }

  // Widget _deleteBtn() {
  //   return Container(
  //     height: 50.0,
  //     width: 50.0,
  //     padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //     child: FittedBox(child: Icon(Icons.delete_forever_outlined)),
  //   );
  // }
}

class ScrollingOptionsWidget extends StatelessWidget {
  ScrollingOptionsWidget(
      {super.key, required this.options, this.onChanged, this.initialValue});
  final List<String> options;
  final Function(int)? onChanged;
  final int? initialValue;
  final PageController pageController = PageController();
  final RxInt currOption = 0.obs;
  static const itemHeight = 50.0;

  void onPageChange() {
    if (pageController.page != null &&
        pageController.page!.round() != currOption.value) {
      currOption.value = pageController.page!.round();
      onChanged?.call(currOption.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (initialValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.jumpToPage(initialValue!);
      });
      pageController.addListener(onPageChange);
    }
    return SizedBox(
      height: itemHeight,
      child: PageView.builder(
        controller: pageController,
        itemCount: options.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          return Container(
            height: itemHeight,
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              border: index == 0
                  ? const Border(
                      bottom: BorderSide(width: 5.0),
                      left: BorderSide(),
                      right: BorderSide(),
                      top: BorderSide())
                  : (index == options.length - 1)
                      ? const Border(
                          top: BorderSide(width: 5.0),
                          left: BorderSide(),
                          right: BorderSide(),
                          bottom: BorderSide(),
                        )
                      : const Border(
                          top: BorderSide(width: 5.0),
                          left: BorderSide(),
                          right: BorderSide(),
                          bottom: BorderSide(width: 5.0),
                        ),
            ),
            alignment: Alignment.center,
            child: Text(
              options[index],
              style: AppStyles.defaultFont.copyWith(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
