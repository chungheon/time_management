import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/controllers/sql_controller.dart';
import 'package:time_management/widgets/input_text_field.dart';
import 'package:time_management/widgets/page_header_widget.dart';

class SqlPage extends StatelessWidget {
  SqlPage({super.key});
  final SQLController _sqlController = Get.find();
  final RxString _queryText = RxString("");
  final RxString _response = RxString("");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeaderWidget(title: "Test"),
      body: Column(
        children: [
          InputTextField(
            initialValue: _queryText.value,
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            maxLines: 5,
            onChanged: (text) {
              _queryText.value = text;
            },
          ),
          Obx(
            () => Text(
              _response.value,
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                var res = await _sqlController.rawQuery(_queryText.value);
                _response.value = res.toString();
              } on Exception catch (e) {
                _response.value = e.toString();
              }
            },
            child: Container(
              height: 50.0,
              width: double.infinity,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
