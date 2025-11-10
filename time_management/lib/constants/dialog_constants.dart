import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/confirmation_dialog.dart';

class DialogConstants {
  static Widget exitDialog(
      {String? returnRoute,
      String? msg,
      Future<void> Function()? onConfirm,
      Future<void> Function()? onCancelled}) {
    return ConfirmationDialog(
      message: msg ?? "Discard all and return?",
      onConfirm: () async {
        await onConfirm?.call();
        if (returnRoute != null) {
          Get.until((route) => route.settings.name == returnRoute);
        } else {
          Get.until((route) => route.isFirst);
        }
      },
      onCancelled: () async {
        await onCancelled?.call();
      },
    );
  }

  static Widget errorDialog({String? msg, Function()? onTap}) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 80.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
          7.0,
        )),
        child: Column(
          children: [
            Text(
              msg ?? " Error",
              style: AppStyles.defaultFont.copyWith(
                fontSize: AppFontSizes.body,
                color: Colors.red,
              ),
            ),
            GestureDetector(
              onTap: () {
                onTap?.call() ?? Get.back();
              },
              child: Container(height: 30, width: 100, child: Text("OK")),
            )
          ],
        ),
      ),
    );
  }
}
