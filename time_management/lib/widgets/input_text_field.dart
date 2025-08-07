import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/helpers/date_time_helpers.dart';
import 'package:time_management/styles.dart';

class InputTextField extends StatelessWidget {
  InputTextField(
      {this.title,
      this.hintText,
      this.nextFocus,
      this.padding,
      this.maxLines,
      this.focusNode,
      this.focusNext,
      this.onChanged,
      this.inputType,
      this.textInputAction,
      this.startDateRange,
      this.endDateRange,
      this.initialDate,
      TextEditingController? textController,
      String? initialValue,
      super.key}) {
    if (textController != null) {
      _textController.value = textController;
    }
    if (initialValue != null) {
      _textController.value.text = initialValue;
    }
  }
  final String? title;
  final String? hintText;
  final FocusNode? nextFocus;
  final EdgeInsets? padding;
  final int? maxLines;
  final FocusNode? focusNode;
  final Function()? focusNext;
  final Function(String text)? onChanged;
  final TextInputAction? textInputAction;
  final TextInputType? inputType;
  final Rx<TextEditingController> _textController = TextEditingController().obs;
  final RxBool hasText = false.obs;
  final DateTime? endDateRange;
  final DateTime? startDateRange;
  final DateTime? initialDate;

  Future<void> onTapCalendar(context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    DateTime? selDate = await showDatePicker(
        context: context,
        initialDate: initialDate ?? DateTime.now(),
        firstDate: startDateRange ?? DateTime.now(),
        lastDate:
            endDateRange ?? DateTime.now().add(const Duration(days: 365)));
    if (selDate != null) {
      _textController.value.text =
          DateTimeHelpers.getDateStr(selDate.millisecondsSinceEpoch);
      onChanged?.call(_textController.value.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title == null
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    title!,
                    style: AppStyles.inputTitle(context),
                  ),
                ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(focusNode);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: StateContainer.of(context)
                            ?.currTheme
                            .textBackground,
                        borderRadius: BorderRadius.circular(5.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController.value,
                            textInputAction: textInputAction ??
                                (nextFocus != null
                                    ? TextInputAction.next
                                    : TextInputAction.done),
                            style: AppStyles.inputText(context),
                            focusNode: focusNode,
                            maxLines: maxLines ?? 1,
                            keyboardType: inputType,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: hintText ?? '',
                              hintStyle: AppStyles.inputHint(context),
                              border: InputBorder.none,
                            ),
                            onChanged: (String input) {
                              onChanged?.call(input);
                              hasText.value = input.isNotEmpty;
                            },
                            onEditingComplete: () {
                              if (nextFocus != null) {
                                FocusScope.of(context).requestFocus(nextFocus);
                              } else if (focusNext != null) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                focusNext?.call();
                              } else {
                                FocusManager.instance.primaryFocus?.unfocus();
                              }
                            },
                          ),
                        ),
                        Obx(() {
                          if (!hasText.value &&
                              (_textController.value.text.isEmpty)) {
                            return Container();
                          } else {
                            return Container(
                              width: 25.0,
                              height: 25.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: GestureDetector(
                                  onTap: () {
                                    _textController.value.clear();
                                    onChanged?.call("");
                                    hasText.value = false;
                                  },
                                  child: const Icon(Icons.cancel_outlined)),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              inputType == TextInputType.datetime
                  ? Container(
                      width: 50.0,
                      alignment: Alignment.center,
                      child: GestureDetector(
                          onTap: () async {
                            onTapCalendar(context);
                          },
                          child: const Icon(Icons.date_range, size: 35.0)),
                    )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }
}
