import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/styles.dart';

class ScrollingOptionsWidget extends StatelessWidget {
  ScrollingOptionsWidget(
      {super.key, required this.options, this.onChanged, this.initialValue});
  final List<String> options;
  final Function(int)? onChanged;
  final int? initialValue;
  final PageController pageController = PageController();
  final RxInt currOption = 0.obs;
  static const itemHeight = 50.0;

  void onPageChange() {
    if (pageController.page != null &&
        pageController.page!.round() != currOption.value) {
      currOption.value = pageController.page!.round();
      onChanged?.call(currOption.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (initialValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.jumpToPage(initialValue!);
      });
      pageController.addListener(onPageChange);
    }
    return SizedBox(
      height: itemHeight,
      child: PageView.builder(
        controller: pageController,
        itemCount: options.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          return Container(
            height: itemHeight,
            decoration: BoxDecoration(
              border: index == 0
                  ? const Border(
                      bottom: BorderSide(width: 5.0),
                      left: BorderSide(),
                      right: BorderSide(),
                      top: BorderSide())
                  : (index == options.length - 1)
                      ? const Border(
                          top: BorderSide(width: 5.0),
                          left: BorderSide(),
                          right: BorderSide(),
                          bottom: BorderSide(),
                        )
                      : const Border(
                          top: BorderSide(width: 5.0),
                          left: BorderSide(),
                          right: BorderSide(),
                          bottom: BorderSide(width: 5.0),
                        ),
            ),
            alignment: Alignment.center,
            child: Text(
              options[index],
              style: AppStyles.defaultFont.copyWith(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}