import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/styles.dart';

class LoadingPageWidget extends StatelessWidget {
  const LoadingPageWidget({
    super.key,
    this.asyncFunc,
    this.onComplete,
    this.msg,
    this.onFail,
  });

  final Future<Object?> Function()? asyncFunc;
  final Function(Object?)? onComplete;
  final Function(Exception)? onFail;
  final String? msg;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((time) async {
      try {
        asyncFunc?.call().then((value) async {
          onComplete?.call(value);
        });
      } on Exception catch (e) {
        onFail?.call(e) ?? Get.back();
      }
    });
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: StateContainer.of(context)?.currTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                  height: 60.0,
                  width: 60.0,
                  child: FittedBox(child: CircularProgressIndicator())),
              Text(
                msg ?? 'Loading',
                style: AppStyles.loadingText(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
