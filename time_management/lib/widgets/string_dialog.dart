import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/styles.dart';

class StringDialog extends StatelessWidget {
  const StringDialog({super.key, this.shortName, this.text});
  final String? shortName;
  final String? text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context)?.currTheme.background,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  shortName ?? "",
                  maxLines: 2,
                  style: AppStyles.defaultFont.copyWith(
                      color: StateContainer.of(context)?.currTheme.text,
                      fontSize: AppFontSizes.body),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: shortName ?? ""));
                  Fluttertoast.showToast(
                      msg: "Copied to Clipboard",
                      toastLength: Toast.LENGTH_SHORT);
                },
                child: Container(
                  width: 45.0,
                  height: 45.0,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: StateContainer.of(context)?.currTheme.darkButton,
                    shape: BoxShape.circle,
                  ),
                  child: FittedBox(
                    child: Icon(
                      Icons.copy,
                      color: StateContainer.of(context)?.currTheme.lightText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10.0,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    text ?? "",
                    style: AppStyles.defaultFont.copyWith(
                        color: StateContainer.of(context)?.currTheme.text,
                        fontSize: AppFontSizes.body),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text ?? ""));
                  Fluttertoast.showToast(
                      msg: "Copied to Clipboard",
                      toastLength: Toast.LENGTH_SHORT);
                },
                child: Container(
                  width: 45.0,
                  height: 45.0,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: StateContainer.of(context)?.currTheme.darkButton,
                    shape: BoxShape.circle,
                  ),
                  child: FittedBox(
                    child: Icon(
                      Icons.copy,
                      color: StateContainer.of(context)?.currTheme.lightText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
