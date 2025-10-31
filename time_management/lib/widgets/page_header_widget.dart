import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_icons.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/styles.dart';

class PageHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  const PageHeaderWidget(
      {required this.title,
      super.key,
      this.exitDialog,
      this.additionalAction,
      this.returnRoute});
  final String title;
  final Widget? exitDialog;
  final List<Widget>? additionalAction;
  final String? returnRoute;
  static const double actionWidth = 50.0;
  @override
  Size get preferredSize => const Size.fromHeight(50.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: StateContainer.of(context)?.currTheme.background,
          boxShadow: [
            EffectConstants.shadowEffectDown(context),
          ]),
      child: Row(
        children: [
          Material(
            child: InkWell(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                if (exitDialog == null) {
                  if (returnRoute != null) {
                    Get.until(
                      (route) => route.settings.name == returnRoute,
                    );
                  } else {
                    Get.back();
                  }
                } else {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return exitDialog!;
                    },
                  );
                }
              },
              splashColor: StateContainer.of(context)?.currTheme.splashEffect,
              child: Container(
                width: actionWidth,
                height: actionWidth,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22.0,
                  height: 22.0,
                  child: FittedBox(
                    child: Icon(
                      AppIcons.direction_left,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ..._balanceSpaces(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              alignment: Alignment.center,
              child: Text(
                title,
                style: AppStyles.pageHeader(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(
            width: actionWidth,
          ),
          ..._additionalActions(),
        ],
      ),
    );
  }

  List<Widget> _additionalActions() {
    List<Widget> actions = [];
    for (int i = 0; i < (additionalAction?.length ?? 0); i++) {
      actions.add(
        SizedBox(
          width: actionWidth,
          height: preferredSize.height,
          child: FittedBox(
            child: additionalAction!.elementAt(i),
          ),
        ),
      );
    }
    return actions;
  }

  List<Widget> _balanceSpaces() {
    List<Widget> sizedBoxes = [];
    for (int i = 0; i < (additionalAction?.length ?? 0); i++) {
      sizedBoxes.add(
        const SizedBox(
          width: actionWidth,
        ),
      );
    }
    return sizedBoxes;
  }
}
