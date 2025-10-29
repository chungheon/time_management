import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
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

class AddTaskPage extends StatelessWidget {
  AddTaskPage(
      {super.key, this.returnRoute, Goal? goal, this.onCreateComplete}) {
    if (goal != null) {
      selectedGoal.value = goal;
    } else {
      selectedGoal.value = _goalsController.goalList.first;
    }
    _startDateInput.value = DateTimeHelpers.getDateStr(
        DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch);
  }
  final GoalsController _goalsController = Get.find<GoalsController>();
  final String? returnRoute;
  final Rxn<Goal> selectedGoal = Rxn<Goal>();
  final FocusNode _taskNode = FocusNode();
  final FocusNode _startDateNode = FocusNode();
  final RxString _taskInput = RxString('');
  final RxString _startDateInput = RxString('');
  final TextEditingController _dateTextController = TextEditingController();
  final Function(int?)? onCreateComplete;
  final RxBool _showLinkDocuments = false.obs;
  final RxList<Document> newDocuments = RxList<Document>();
  final RxBool _hideAdded = false.obs;
  final TextEditingController _taskInputController = TextEditingController();

  Future<void> onTapAddTask() async {
    Get.off(() => LoadingPageWidget(
          asyncFunc: () async {
            var result = await _goalsController.createTask(
              _taskInput.value,
              selectedGoal.value!.uid!,
              DateTimeHelpers.tryParse(_startDateInput.value)
                  ?.millisecondsSinceEpoch,
              newDocuments.toList(),
            );
            Goal selGoal = _goalsController.goalList.firstWhere(
              (element) {
                return element.uid == (selectedGoal.value!.uid);
              },
            );

            _goalsController.updateGoal(selGoal);
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

  Function() onTapTemplate(Task task) {
    return () {
      _taskInputController.text = task.task ?? '';
      _taskInput.value = _taskInputController.text;
      for (var doc in task.documents) {
        if (!newDocuments.contains(doc)) {
          newDocuments.add(doc);
        }
      }
      Get.back();
    };
  }

  Future<void> onTapViewTemplates(context) async {
    List<Task> uniqueList = [];
    List<String> uniqueTasks = [];
    selectedGoal.value?.tasks.forEach((element) {
      if (element.task != null && !uniqueTasks.contains(element.task)) {
        uniqueList.add(element);
        uniqueTasks.add(element.task!);
      }
    });
    showDialog(
        context: context,
        builder: (diagContext) {
          return Dialog(
            child: Container(
              height: 300.0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("List of Templates:"),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: uniqueList.length,
                      itemBuilder: (context, index) {
                        return _templateItem(uniqueList.elementAt(index),
                            onTapTemplate(uniqueList.elementAt(index)));
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (pop, _) {
        if (!pop) {
          showDialog(
              context: context,
              builder: (_) =>
                  DialogConstants.exitDialog(returnRoute: returnRoute));
        }
      },
      child: Scaffold(
        appBar: PageHeaderWidget(
          title: 'Add Task',
          exitDialog: DialogConstants.exitDialog(returnRoute: returnRoute),
          additionalAction: [
            InkWell(
              child: const Material(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(Icons.copy)),
              ),
              onTap: () => onTapViewTemplates(context),
            ),
          ],
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
                          hintText: 'Which goal is it linked to?',
                          nextFocus: _taskNode,
                          initialValue: selectedGoal.value,
                          padding: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 16.0, bottom: 10.0),
                          onSelected: (Goal selection) {
                            selectedGoal.value = selection;
                          },
                        ),
                      ),
                      InputTextField(
                        textController: _taskInputController,
                        title: 'Task',
                        hintText: 'What needs to be done?',
                        maxLines: 5,
                        focusNode: _taskNode,
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20.0, bottom: 10.0),
                        onChanged: (input) {
                          _taskInput.value = input;
                        },
                      ),
                      InputTextField(
                        title: 'Start Date (optional)',
                        hintText: 'When should you be informed?',
                        initialValue: _startDateInput.value,
                        focusNode: _startDateNode,
                        inputType: TextInputType.datetime,
                        textController: _dateTextController,
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20.0, bottom: 10.0),
                        onChanged: (input) {
                          _startDateInput.value = input;
                        },
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Material(
                          borderRadius: BorderRadius.circular(10.0),
                          color:
                              StateContainer.of(context)!.currTheme.darkButton,
                          child: InkWell(
                            onTap: onTapAddDocument,
                            borderRadius: BorderRadius.circular(10.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: Text(
                                'Add Document',
                                style: AppStyles.defaultFont.copyWith(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: StateContainer.of(context)!
                                      .currTheme
                                      .lightText,
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                  return _docItem(
                                    newDocuments[index],
                                    context,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(
                        height: 20.0,
                      )
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
                      onTap: onTapAddTask,
                      splashColor:
                          StateContainer.of(context)?.currTheme.splashEffect,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        color: Colors.transparent,
                        child: Center(
                          child: Text(
                            "Create New Task",
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

  Widget _templateItem(Task? task, Function() onTap) {
    if (task == null) {
      return Container();
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [EffectConstants.shadowEffectDown(Get.context)]),
        child: Center(
          child: Text(
            task?.task ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _docItem(
    Document doc,
    BuildContext context,
  ) {
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
              newDocuments.removeWhere((e) => e.uid == doc.uid);
            },
            child: Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: StateContainer.of(context)?.currTheme.removeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove,
                  size: 30.0,
                )),
          )
        ],
      ),
    );
  }

  Widget _linkDocumentSheet(context) {
    return CustomBottomSheet(
      showBottomSheet: _showLinkDocuments,
      child: GetBuilder(
        init: _goalsController,
        builder: (controller) {
          var tasks = List<Document>.from(selectedGoal.value?.documents ?? []);
          return LinkDocumentToTask(
            goalDocs: tasks,
            selectedDocs: newDocuments,
          );
        },
      ),
    );
  }
}
