import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/styles.dart';

class ScrollingOptionsWidget extends StatelessWidget {
  ScrollingOptionsWidget(
      {super.key, required this.options, this.onChanged, this.initialValue, PageController? controller}){
        pageController.value = controller ?? PageController();
      }
  final List<String> options;
  final Function(int)? onChanged;
  final int? initialValue;
  final Rx<PageController> pageController = PageController().obs;
  final RxInt currOption = 0.obs;
  static const itemHeight = 50.0;

  void onPageChange() {
    if (pageController.value.page != null &&
        pageController.value.page!.round() != currOption.value) {
      currOption.value = pageController.value.page!.round();
      onChanged?.call(currOption.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (initialValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.value.jumpToPage(initialValue!);
      });
      pageController.value.addListener(onPageChange);
    }
    return SizedBox(
      height: itemHeight,
      child: PageView.builder(
        controller: pageController.value,
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