import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/controllers/goal_view_controller.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/tag_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/contact_document_widget.dart';
import 'package:time_management/widgets/document_widget.dart';
import 'package:time_management/widgets/input_text_field.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/text_document_widget.dart';
import 'package:time_management/widgets/video_document_widget.dart';

class EditGoalPage extends StatelessWidget {
  EditGoalPage({super.key, this.returnRoute, required this.goal}) {
    _goalTextInput.value = goal.name ?? '';
    _purposeTextInput.value = goal.purpose ?? '';
    if (goal.dueDate != null) {
      _completionDate.value = DateTimeHelpers.getFormattedDate(
          DateTime.fromMillisecondsSinceEpoch(goal.dueDate!),
          dateFormat: ('dd/MM/yy'));
    }
    _tagsList.value = List.from(goal.tags);
    _docUid.value = goal.documents.map<int>((e) => e.uid ?? -1).toList();
  }
  final GoalsController _goalsController = Get.find<GoalsController>();
  final GoalViewController _goalViewController = Get.find<GoalViewController>();
  final String? returnRoute;
  final Goal goal;
  final FocusNode _goalInput = FocusNode();
  final FocusNode _purposeInput = FocusNode();
  final FocusNode _complDateInput = FocusNode();
  // final FocusNode _tagsInput = FocusNode();
  final RxList<int> _docUid = RxList<int>();
  final RxList<Tag> _tagsList = RxList<Tag>();
  final RxString _goalTextInput = RxString("");
  final RxString _purposeTextInput = RxString("");
  final RxString _completionDate = RxString("");
  final RxBool _hideExisting = false.obs;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (pop) {
        if (!pop) {
          showDialog(
              context: context,
              builder: (_) =>
                  DialogConstants.exitDialog(returnRoute: returnRoute));
        }
      },
      child: Scaffold(
        backgroundColor: StateContainer.of(context)?.currTheme.background,
        appBar: PageHeaderWidget(
          title: 'Edit Goal',
          exitDialog: DialogConstants.exitDialog(returnRoute: returnRoute),
          additionalAction: [
            InkWell(
              onTap: () {
                Get.to(() => LoadingPageWidget(
                      asyncFunc: () async {
                        try {
                          await _goalsController.deleteGoal(goal);
                          _goalViewController.currentGoal.value -= 1;
                          _goalsController.update();
                        } on Exception {
                          rethrow;
                        }
                        return;
                      },
                      onFail: (e) async {
                        await showDialog(
                            context: Get.context!,
                            builder: (_) => Dialog(
                                child: DialogConstants.errorDialog(
                                    msg: e.toString())));
                        Get.back();
                      },
                      onComplete: (_) async {
                        Get.until((route) {
                          return returnRoute != null
                              ? route.settings.name == returnRoute
                              : route.isFirst;
                        });
                      },
                    ));
              },
              child: Container(
                height: 50.0,
                width: 50.0,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: const Icon(Icons.delete_outline),
              ),
            )
          ],
        ),
        body: Column(children: [
          Expanded(
              child: ListView(
            children: [
              InputTextField(
                title: "Goal",
                hintText: "What is your goal?",
                initialValue: _goalTextInput.value,
                onChanged: (input) {
                  _goalTextInput.value = input;
                },
                focusNode: _goalInput,
                nextFocus: _purposeInput,
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 16.0, bottom: 10.0),
              ),
              InputTextField(
                title: "Purpose",
                hintText: "Why is this goal so important?",
                initialValue: _purposeTextInput.value,
                maxLines: 5,
                onChanged: (input) {
                  _purposeTextInput.value = input;
                },
                focusNode: _purposeInput,
                inputType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 0.0, bottom: 10.0),
              ),
              InputTextField(
                title: "Completion Date (dd/mm/yy)",
                hintText: "Target date to complete goal",
                initialValue: _completionDate.value,
                maxLines: 1,
                onChanged: (input) {
                  _completionDate.value = input;
                },
                inputType: TextInputType.datetime,
                focusNode: _complDateInput,
                endDateRange: DateTime.now().add(const Duration(hours: 43830)),
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 0.0, bottom: 10.0),
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: goal.documents.isNotEmpty ? 0.0 : 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => Text(
                          "Exisiting ${goal.documents.length} Documents (Remove ${(goal.documents.length - _docUid.length)})",
                          style: AppStyles.inputTitle(context),
                        ),
                      ),
                    ),
                    goal.documents.isEmpty
                        ? Container()
                        : Obx(
                            () => GestureDetector(
                              onTap: () =>
                                  _hideExisting.value = !_hideExisting.value,
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
                        itemCount: goal.documents.length,
                        itemBuilder: (context, index) {
                          return Obx(() {
                            bool isRemoved = !_docUid
                                .contains(goal.documents[index].uid ?? -1);
                            return _docItem(
                              goal.documents[index],
                              context,
                              isRemoved: isRemoved,
                            );
                          });
                        },
                      ),
              ),
              // CreateTagsField(
              //   tags: _tagsList,
              //   focusNode: _tagsInput,
              //   padding:
              //       const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              // ),
            ],
          )),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            color: StateContainer.of(context)?.currTheme.background,
            child: Material(
              color: StateContainer.of(context)?.currTheme.darkButton,
              elevation: 4.0,
              shadowColor:
                  StateContainer.of(context)?.currTheme.shadowElevation,
              borderRadius: BorderRadius.circular(8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () {
                  Get.off(() => LoadingPageWidget(
                        asyncFunc: () async {
                          try {
                            await _goalsController.editGoal(
                              goal,
                              name: _goalTextInput.value,
                              purpose: _purposeTextInput.value,
                              date: DateTimeHelpers.tryParse(
                                  _completionDate.value),
                              tags: _tagsList,
                              docList: _docUid,
                            );

                            await _goalsController.updateGoal(goal);
                          } on Exception {
                            // TODO: catch on edit goal fails
                          }
                          return;
                        },
                        onComplete: (_) async {
                          Get.until((route) {
                            return returnRoute != null
                                ? route.settings.name == returnRoute
                                : route.isFirst;
                          });
                        },
                      ));
                },
                splashColor: StateContainer.of(context)?.currTheme.splashEffect,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  color: Colors.transparent,
                  child: Center(
                    child: Text(
                      "Edit Goal",
                      style: AppStyles.actionButtonText(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _docItem(Document doc, BuildContext context,
      {bool isRemoved = false}) {
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
              if (_docUid.contains(doc.uid)) {
                _docUid.remove(doc.uid);
              } else {
                _docUid.add(doc.uid ?? -1);
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
