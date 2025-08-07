import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/contact_document_widget.dart';
import 'package:time_management/widgets/document_widget.dart';
import 'package:time_management/widgets/text_document_widget.dart';
import 'package:time_management/widgets/video_document_widget.dart';

class LinkDocumentToTask extends StatelessWidget {
  const LinkDocumentToTask({
    super.key,
    required this.goalDocs,
    required this.selectedDocs,
  });
  final List<Document> goalDocs;
  final RxList<Document> selectedDocs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 20.0, right: 20.0,bottom: 8.0),
            child: Obx(
              () {
                String docStr = "Documents ${goalDocs.length}";
                String newDocStr = " (Added ${selectedDocs.length})";
                if (selectedDocs.isNotEmpty) {
                  docStr += newDocStr;
                }
                return Text(
                  docStr,
                  style: AppStyles.inputTitle(context),
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 12,
          child: Obx(() {
            List<int> selectedUid =
                selectedDocs.map<int>((e) => e.uid ?? -1).toList();
            return ListView.builder(
              shrinkWrap: true,
              itemCount: goalDocs.length,
              itemBuilder: (context, index) {
                return _docItem(goalDocs[index], context, selectedUid);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _docItem(Document doc, BuildContext context, List<int> selectedUid) {
    Widget widget = Container();
    bool isSelected = selectedUid.contains(doc.uid ?? -1);
    switch (doc.type ?? -1) {
      case 0:
        //Contact

        widget = ContactDocumentWidget(
          doc: doc,
          isSelected: isSelected,
        );

        break;
      case 1:
        //Video
        widget = VideoDocumentWidget(
          doc: doc,
          isSelected: isSelected,
        );
        break;
      case 2:
        //Text
        widget = TextDocumentWidget(
          doc: doc,
          isSelected: isSelected,
        );
        break;
      case 3:
        //Document
        widget = DocumentWidget(
          doc: doc,
          isSelected: isSelected,
        );
        break;
      default:
        //Empty
        return Container(
          color: StateContainer.of(context)?.currTheme.hintText,
          child: Text(
            "ERROR LOADING",
            style:
                AppStyles.defaultFont.copyWith(fontSize: AppFontSizes.header3),
          ),
        );
    }
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          selectedDocs.remove(doc);
        } else {
          selectedDocs.add(doc);
        }
      },
      child: widget,
    );
  }
}
