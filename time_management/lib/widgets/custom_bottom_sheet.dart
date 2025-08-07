import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_icons.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/effect_constants.dart';

class CustomBottomSheet extends StatelessWidget {
  CustomBottomSheet({super.key, required this.child, required this.showBottomSheet});
  final Widget child;
  final RxDouble _scrollStart = 0.0.obs;
  final RxDouble _scrollDownList = 0.0.obs;
  final RxBool _hasAnimationEnd = true.obs;
  final RxBool showBottomSheet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var maxHeight = constraints.maxHeight;
      return Obx(
        () {
          return Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (dragDetails) {
                _scrollStart.value = dragDetails.localPosition.dy;
              },
              onVerticalDragUpdate: (dragDetails) {
                if (_hasAnimationEnd.value) {
                  _scrollDownList.value = dragDetails.localPosition.dy;

                  if (showBottomSheet.value &&
                          _scrollDownList.value - _scrollStart.value >=
                              (maxHeight / 3) ||
                      _scrollDownList.value > maxHeight - 40.0) {
                    _hasAnimationEnd.value = false;
                    showBottomSheet.value = false;
                    _scrollDownList.value = 0;
                    _scrollStart.value = 0;
                  }
                }
              },
              onVerticalDragCancel: () {
                _scrollDownList.value = 0;
                _scrollStart.value = 0;
              },
              onVerticalDragEnd: (dragDetails) {
                if (_scrollStart.value - _scrollDownList.value <=
                    (constraints.maxHeight / 2)) {
                  _scrollDownList.value = 0;
                }
                _hasAnimationEnd.value = true;
                _scrollStart.value = 0;
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 300,
                ),
                onEnd: () {
                  _hasAnimationEnd.value = true;
                },
                height: showBottomSheet.value
                    ? maxHeight - _scrollDownList.value - 15.0
                    : _scrollDownList.value < 0
                        ? 0.0 - _scrollDownList.value
                        : 0.0,
                decoration: BoxDecoration(
                    color: StateContainer.of(context)?.currTheme.background,
                    boxShadow: [EffectConstants.shadowEffectUp(context)],
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15.0))),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_hasAnimationEnd.value) {
                          _hasAnimationEnd.value = false;
                          showBottomSheet.value = !showBottomSheet.value;
                          _scrollDownList.value = 0;
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        constraints: BoxConstraints(
                            maxHeight: showBottomSheet.value ? 40.0 : 0.0),
                        alignment: Alignment.center,
                        child: FittedBox(
                          child: Icon(
                            showBottomSheet.value
                                ? AppIcons.direction_down
                                : AppIcons.direction_up,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
