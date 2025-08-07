import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/styles.dart';

class AutoCompleteGoalsInput extends StatelessWidget {
  AutoCompleteGoalsInput({
    super.key,
    this.title,
    this.hintText,
    this.nextFocus,
    this.padding,
    this.onSelected,
    this.initialValue,
    this.inputType,
    this.removeOnCompletion = true,
    this.optionsMaxHeight,
  });

  static String _displayStringForOption(Goal option) => option.name ?? 'Err';
  final GoalsController _goalsController = Get.find<GoalsController>();
  final String? title;
  final String? hintText;
  final FocusNode? nextFocus;
  final EdgeInsets? padding;
  final Goal? initialValue;
  final Function(Goal)? onSelected;
  final TextInputType? inputType;
  final Rxn<TextEditingController> _textEditingController =
      Rxn<TextEditingController>();
  final bool removeOnCompletion;
  final double? optionsMaxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._titleWidget(context),
          Autocomplete<Goal>(
            displayStringForOption: _displayStringForOption,
            optionsMaxHeight: optionsMaxHeight ?? 200.0,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<Goal>.empty();
              }
              return _goalsController.goalList.where((Goal option) {
                return option.name
                        ?.toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()) ??
                    false;
              });
            },
            fieldViewBuilder: (
              context,
              textController,
              focusNode,
              _,
            ) {
              _textEditingController.value = textController;

              return Container(
                decoration: BoxDecoration(
                    color: StateContainer.of(context)?.currTheme.textBackground,
                    borderRadius: BorderRadius.circular(5.0)),
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: textController,
                  textInputAction: nextFocus == null
                      ? TextInputAction.done
                      : TextInputAction.next,
                  style: AppStyles.inputText(context),
                  focusNode: focusNode,
                  maxLines: 1,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText ?? '',
                    hintStyle: AppStyles.inputHint(context),
                    border: InputBorder.none,
                  ),
                  onEditingComplete: () {
                    if (nextFocus != null) {
                      FocusScope.of(context).requestFocus(nextFocus);
                    } else {
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                  },
                ),
              );
            },
            onSelected: (Goal selection) {
              onSelected?.call(selection);
              if (removeOnCompletion) {
                _textEditingController.value?.clear();
              }
            },
          )
        ],
      ),
    );
  }

  List<Widget> _titleWidget(context) {
    List<Widget> titleText = [
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                title ?? '',
                style: AppStyles.inputTitle(context),
              ),
            ),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Goal Selected:',
                    style: AppStyles.inputHint(context),
                  ),
                  TextSpan(
                    text: initialValue?.name ?? '',
                    style: AppStyles.defaultFont.copyWith(
                        color: StateContainer.of(context)?.currTheme.text,
                        fontSize: AppFontSizes.paragraph,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    ];
    if (title == null) {
      titleText = [Container()];
    }
    return titleText;
  }
}
