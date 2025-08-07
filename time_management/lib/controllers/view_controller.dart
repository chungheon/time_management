import 'package:get/get.dart';
import 'package:time_management/helpers/date_time_helpers.dart';

class ViewController extends GetxController {
  final Rxn<DateTime> currDate = Rxn<DateTime>();

  @override
  void onInit() {
    currDate.value = DateTime.now().dateOnly();
    super.onInit();
  }

  bool updateDate() {
    bool changed = false;
    DateTime now = DateTime.now().dateOnly();
    if ((currDate.value?.millisecondsSinceEpoch ?? 0) !=
        now.millisecondsSinceEpoch) {
      changed = true;
      currDate.value = now;
    }
    update();
    return changed;
  }
}
