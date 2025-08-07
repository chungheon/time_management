import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/confirmation_dialog.dart';

class DialogConstants {
  static Widget exitDialog({String? returnRoute, String? msg}) {
    return ConfirmationDialog(
      message: msg ?? "Discard all and return?",
      onConfirm: () async {
        if (returnRoute != null) {
          Get.until((route) => route.settings.name == returnRoute);
        } else {
          Get.until((route) => route.isFirst);
        }
      },
    );
  }

  static Widget errorDialog({String? msg}) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 80.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
        7.0,
      )),
      child: Text(
        msg ?? " Error",
        style: AppStyles.defaultFont.copyWith(
          fontSize: AppFontSizes.body,
          color: Colors.red,
        ),
      ),
    );
  }
}
