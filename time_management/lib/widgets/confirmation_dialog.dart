import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/styles.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.message,
    this.confirmTitle,
    this.cancelTitle,
    this.onConfirm,
    this.onCancelled,
  });
  final String? message;
  final String? confirmTitle;
  final String? cancelTitle;
  final Future<void> Function()? onConfirm;
  final Future<void> Function()? onCancelled;

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
              Text(
                message ?? "Confirmation dialog",
                style: AppStyles.defaultFont.copyWith(
                    color: StateContainer.of(context)?.currTheme.text,
                    fontSize: AppFontSizes.body),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 15.0,
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        onCancelled?.call();
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7.0),
                        decoration: BoxDecoration(
                          color: StateContainer.of(context)?.currTheme.button,
                          border: Border.all(
                              color:
                                  StateContainer.of(context)?.currTheme.text ??
                                      Colors.black,
                              width: 1.0),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cancelTitle ?? "Cancel",
                          style: AppStyles.defaultFont.copyWith(
                              color: StateContainer.of(context)?.currTheme.text,
                              fontSize: AppFontSizes.body),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 50.0,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (onConfirm == null) {
                          Get.back();
                        } else {
                          onConfirm!.call();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color:
                              StateContainer.of(context)?.currTheme.darkButton,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          confirmTitle ?? "Confirm",
                          style: AppStyles.defaultFont.copyWith(
                              color: StateContainer.of(context)
                                  ?.currTheme
                                  .lightText,
                              fontSize: AppFontSizes.body),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
