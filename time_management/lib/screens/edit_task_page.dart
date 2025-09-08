import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/notifications_controller.dart';
import 'package:time_management/controllers/routine_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/auto_complete_goals_input.dart';
import 'package:time_management/widgets/contact_document_widget.dart';
import 'package:time_management/widgets/custom_bottom_sheet.dart';
import 'package:time_management/widgets/document_widget.dart';
import 'package:time_management/widgets/input_text_field.dart';
import 'package:time_management/widgets/link_document_task.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/text_document_widget.dart';
import 'package:time_management/widgets/video_document_widget.dart';

class EditTaskPage extends StatelessWidget {
  EditTaskPage(
      {super.key,
      this.returnRoute,
      required this.task,
      this.onCreateComplete}) {
    _taskInput.value = task.task ?? '';
    _startDateInput.value = task.actionDate == null
        ? ''
        : DateTimeHelpers.getDateStr(task.actionDate);
    selectedGoal.value = task.goal;
    _docUid.value = task.documents.map<int>((e) => e.uid ?? -1).toList();
    _selectedTime.value = task.alertTime == null
        ? null
        : TimeOfDay.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(task.alertTime!));
    _timeStr.value = _selectedTime.value?.timeFormat() ?? "";
  }
  final Task task;
  final GoalsController _goalsController = Get.find<GoalsController>();
  final RoutineController _routineController = Get.find<RoutineController>();
  final NotificationsController _notificationsController =
      Get.find<NotificationsController>();
  final String? returnRoute;
  final Rxn<Goal> selectedGoal = Rxn<Goal>();
  final FocusNode _taskNode = FocusNode();
  final FocusNode _startDateNode = FocusNode();
  final RxString _taskInput = RxString('');
  final RxString _startDateInput = RxString('');
  final RxList<int> _docUid = RxList<int>();
  final RxList<Document> newDocuments = RxList<Document>();
  final Function(int?)? onCreateComplete;
  final RxBool _showLinkDocuments = false.obs;
  final RxBool _hideAdded = false.obs;
  final RxBool _hideExisting = false.obs;
  final _dateTextController = TextEditingController();
  final Rxn<TimeOfDay> _selectedTime = Rxn<TimeOfDay>();
  final RxString _timeStr = RxString("");

  Future<void> onTapUpdateTask() async {
    Get.off(() => LoadingPageWidget(
          asyncFunc: () async {
            var result = await _goalsController.editTask(
              task,
              taskStr: _taskInput.value,
              goalId: selectedGoal.value!.uid!,
              actionDate: DateTimeHelpers.tryParse(_startDateInput.value)
                      ?.millisecondsSinceEpoch ??
                  0,
              docList: _docUid,
              addDocs: newDocuments,
              alertTime: _selectedTime.value,
            );
            Goal selGoal = _goalsController.goalList.firstWhere(
              (element) {
                return element.uid == (selectedGoal.value!.uid);
              },
            );
            if (selGoal != task.goal) {
              _goalsController.updateGoal(task.goal!);
              _goalsController.updateGoal(selGoal);
            }

            await _goalsController.updateTask(task, selGoal);
            _notificationsController.refreshNotifications(
                _routineController, _goalsController);
            return result;
          },
          onComplete: (taskUid) async {
            Get.until((route) {
              return returnRoute != null
                  ? route.settings.name == returnRoute
                  : route.isFirst;
            });
            onCreateComplete?.call(taskUid as int?);
          },
        ));
  }

  Future<void> onTapAddDocument() async {
    _showLinkDocuments.value = true;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (pop) {
        if (!pop) {
          if (_showLinkDocuments.value) {
            _showLinkDocuments.value = false;
          } else {
            showDialog(
                context: context,
                builder: (_) =>
                    DialogConstants.exitDialog(returnRoute: returnRoute));
          }
        }
      },
      child: Scaffold(
        appBar: PageHeaderWidget(
          title: 'Update Task',
          exitDialog: DialogConstants.exitDialog(returnRoute: returnRoute),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Obx(
                        () => AutoCompleteGoalsInput(
                          title: 'Goal',
                          hintText: 'Is it linked to one of your goals?',
                          nextFocus: _taskNode,
                          initialValue: selectedGoal.value,
                          inputType: TextInputType.text,
                          padding: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 16.0, bottom: 10.0),
                          onSelected: (Goal selection) {
                            selectedGoal.value = selection;
                          },
                        ),
                      ),
                      InputTextField(
                        title: 'Task',
                        hintText: 'What needs to be done?',
                        maxLines: 5,
                        initialValue: task.task,
                        inputType: TextInputType.multiline,
                        focusNode: _taskNode,
                        textInputAction: TextInputAction.newline,
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20.0, bottom: 10.0),
                        onChanged: (input) {
                          _taskInput.value = input;
                        },
                      ),
                      SizedBox(
                        height: 84.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: InputTextField(
                                title: 'Start Date (Optional)',
                                hintText: 'When should you be informed?',
                                initialValue: task.actionDate != null
                                    ? DateTimeHelpers.getDateStr(
                                        task.actionDate!)
                                    : "",
                                focusNode: _startDateNode,
                                textController: _dateTextController,
                                inputType: TextInputType.datetime,
                                padding: const EdgeInsets.only(
                                    left: 20.0, bottom: 10.0),
                                onChanged: (input) {
                                  _startDateInput.value = input;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Obx(() => _timeSelection(context)),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Material(
                          color: Colors.red,
                          child: InkWell(
                            onTap: onTapAddDocument,
                            child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 10.0),
                                child: Text('Add Document')),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Obx(() {
                        return newDocuments.isEmpty
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: Text(
                                          "Added ${newDocuments.length} Documents",
                                          style: AppStyles.inputTitle(context),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _hideAdded.value = !_hideAdded.value,
                                      child: Icon(
                                        !_hideAdded.value
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 35.0,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                      }),
                      Obx(
                        () => _hideAdded.value
                            ? Container()
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: newDocuments.length,
                                itemBuilder: (context, index) {
                                  return _docItem(newDocuments[index], context,
                                      isNew: true);
                                },
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            bottom: task.documents.isNotEmpty ? 0.0 : 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Obx(
                                () => Text(
                                  "Exisiting ${task.documents.length} Documents (Remove ${(task.documents.length - _docUid.length)})",
                                  style: AppStyles.inputTitle(context),
                                ),
                              ),
                            ),
                            task.documents.isEmpty
                                ? Container()
                                : Obx(
                                    () => GestureDetector(
                                      onTap: () => _hideExisting.value =
                                          !_hideExisting.value,
                                      child: Icon(
                                        !_hideExisting.value
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 35.0,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      Obx(
                        () => _hideExisting.value
                            ? Container()
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: task.documents.length,
                                itemBuilder: (context, index) {
                                  return Obx(() {
                                    bool isRemoved = !_docUid.contains(
                                        task.documents[index].uid ?? -1);
                                    return _docItem(
                                        task.documents[index], context,
                                        isRemoved: isRemoved);
                                  });
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(
                      color: StateContainer.of(context)?.currTheme.background,
                      boxShadow: [EffectConstants.shadowEffectUp(context)]),
                  child: Material(
                    color: StateContainer.of(context)?.currTheme.darkButton,
                    borderRadius: BorderRadius.circular(8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.0),
                      onTap: onTapUpdateTask,
                      splashColor:
                          StateContainer.of(context)?.currTheme.splashEffect,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        color: Colors.transparent,
                        child: Center(
                          child: Text(
                            "Update Task",
                            style: AppStyles.actionButtonText(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _linkDocumentSheet(context),
          ],
        ),
      ),
    );
  }

  Widget _timeSelection(BuildContext context) {
    TimeOfDay now = TimeOfDay.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Time of Notification (Optional)",
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
                initialValue: (_selectedTime.value?.timeFormat()),
                onChanged: (time) {
                  _timeStr.value = time;
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
                  _selectedTime.value = timeSelected;
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

  Widget _linkDocumentSheet(context) {
    return CustomBottomSheet(
      showBottomSheet: _showLinkDocuments,
      child: GetBuilder(
        init: _goalsController,
        builder: (controller) {
          var tasks = List<Document>.from(task.goal?.documents ?? []);
          tasks.removeWhere((e) => _docUid.contains(e.uid));
          return LinkDocumentToTask(
            goalDocs: tasks,
            selectedDocs: newDocuments,
          );
        },
      ),
    );
  }

  Widget _docItem(Document doc, BuildContext context,
      {bool isNew = false, bool isRemoved = false}) {
    Widget widget = Container();
    switch (doc.type ?? -1) {
      case 0:
        //Contact

        widget = ContactDocumentWidget(doc: doc);

        break;
      case 1:
        //Video
        widget = VideoDocumentWidget(doc: doc);
        break;
      case 2:
        //Text
        widget = TextDocumentWidget(doc: doc);
        break;
      case 3:
        //Document
        widget = DocumentWidget(doc: doc);
        break;
      default:
        //Empty
        return Container(
          color: StateContainer.of(context)?.currTheme.hintText,
          child: Text(
            "ERROR LOADING",
            style:
                AppStyles.defaultFont.copyWith(fontSize: AppFontSizes.header3),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Row(
        children: [
          Expanded(child: widget),
          GestureDetector(
            onTap: () {
              if (isNew) {
                newDocuments.removeWhere((e) => e.uid == doc.uid);
              } else {
                if (_docUid.contains(doc.uid)) {
                  _docUid.remove(doc.uid);
                } else {
                  _docUid.add(doc.uid ?? -1);
                }
              }
            },
            child: Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: isRemoved
                      ? StateContainer.of(context)?.currTheme.background
                      : StateContainer.of(context)?.currTheme.removeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRemoved ? Icons.add : Icons.remove,
                  size: 30.0,
                )),
          )
        ],
      ),
    );
  }
}
