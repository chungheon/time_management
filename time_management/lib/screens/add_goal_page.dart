import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/models/tag_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/input_text_field.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';

class AddGoalPage extends StatelessWidget {
  AddGoalPage({super.key, this.returnRoute});
  final GoalsController _goalsController = Get.find<GoalsController>();
  final String? returnRoute;
  final FocusNode _goalInput = FocusNode();
  final FocusNode _purposeInput = FocusNode();
  final FocusNode _complDateInput = FocusNode();
  // final FocusNode _tagsInput = FocusNode();
  final RxList<Tag> _tagsList = RxList<Tag>();
  final RxString _goalTextInput = RxString("");
  final RxString _purposeTextInput = RxString("");
  final RxString _completionDate = RxString("");

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (pop, _) {
        if (!pop) {
          showDialog(
            context: context,
            builder: (_) =>
                DialogConstants.exitDialog(returnRoute: returnRoute),
          );
        }
      },
      child: Scaffold(
        backgroundColor: StateContainer.of(context)?.currTheme.background,
        appBar: PageHeaderWidget(
          title: 'Create Goal',
          exitDialog: DialogConstants.exitDialog(returnRoute: returnRoute),
        ),
        body: Column(children: [
          Expanded(
              child: ListView(
            children: [
              InputTextField(
                title: "Goal",
                hintText: "What is your goal?",
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
                maxLines: 1,
                onChanged: (input) {
                  _completionDate.value = input;
                },
                inputType: TextInputType.datetime,
                focusNode: _complDateInput,
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 0.0, bottom: 10.0),
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
            decoration: BoxDecoration(
                color: StateContainer.of(context)?.currTheme.background,
                boxShadow: [EffectConstants.shadowEffectUp(context)]),
            child: Material(
              color: StateContainer.of(context)?.currTheme.darkButton,
              borderRadius: BorderRadius.circular(8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () {
                  Get.off(() => LoadingPageWidget(
                        asyncFunc: () async {
                          int? response = await _goalsController.createGoal(
                              _goalTextInput.value,
                              _purposeTextInput.value,
                              _completionDate.value,
                              _tagsList);
                          try {
                            Goal goal =
                                (await _goalsController.fetchGoal(response!))!;
                            _goalsController.goalList.add(goal);
                            _goalsController.update();
                          } on Exception {
                            //TODO:Catch on add goal fails
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
                      "Create New Goal",
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
}
