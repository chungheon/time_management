import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/auto_complete_goals_input.dart';

class GoalMoveDialog extends StatefulWidget {
  const GoalMoveDialog(
      {super.key,
      this.returnRoute,
      required this.onConfirm,
      required this.sourceGoal});
  final String? returnRoute;
  final Function(int goalUid) onConfirm;
  final String sourceGoal;

  @override
  State<GoalMoveDialog> createState() => _GoalMoveDialogState();
}

class _GoalMoveDialogState extends State<GoalMoveDialog> {
  final Rxn<Goal> selectedGoal = Rxn<Goal>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: StateContainer.of(context)?.currTheme.background,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(
                () => AutoCompleteGoalsInput(
                  title: "Move tasks",
                  hintText: "Move to this",
                  initialValue: selectedGoal.value,
                  onSelected: (selectedGoal) {
                    this.selectedGoal.value = selectedGoal;
                  },
                  removeOnCompletion: false,
                  optionsMaxHeight: 100.0,
                ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Obx(
                () => Material(
                  color: selectedGoal.value?.uid == null
                      ? StateContainer.of(context)?.currTheme.hintText
                      : StateContainer.of(context)?.currTheme.darkButton,
                  borderRadius: BorderRadius.circular(8.0),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () {
                      if (selectedGoal.value?.uid == null) {
                        return;
                      }
                      widget.onConfirm(selectedGoal.value!.uid!);
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        child: Text(
                          "Move from ${widget.sourceGoal}",
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.defaultFont.copyWith(
                              fontSize: AppFontSizes.body,
                              color: StateContainer.of(context)
                                  ?.currTheme
                                  .lightText),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
