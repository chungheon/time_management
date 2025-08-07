import 'package:flutter/material.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/styles.dart';

class SearchTextField extends StatelessWidget {
  SearchTextField({super.key, this.hintText, this.onChanged, this.searchFunc});
  final String? hintText;
  final TextEditingController _inputController = TextEditingController();
  final Function(String)? onChanged;
  final Function(String)? searchFunc;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // FocusScope.of(context).requestFocus(focusNode);
      },
      child: Container(
        decoration: BoxDecoration(
            color: StateContainer.of(context)?.currTheme.textBackground,
            borderRadius: BorderRadius.circular(5.0)),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: _inputController,
          textInputAction: TextInputAction.done,
          style: AppStyles.inputText(context),
          maxLines: 1,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText ?? '',
            hintStyle: AppStyles.inputHint(context),
            border: InputBorder.none,
          ),
          onChanged: (String input) {
            onChanged?.call(input);
          },
          onEditingComplete: () {
            FocusManager.instance.primaryFocus?.unfocus();
            searchFunc?.call(_inputController.text);
          },
        ),
      ),
    );
  }
}
