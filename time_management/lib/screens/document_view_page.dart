import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/controllers/document_viewer_controller.dart';
import 'package:time_management/helpers/color_helpers.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/document_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/text_document_widget.dart';
import 'package:time_management/widgets/video_document_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewPage extends StatelessWidget {
  DocumentViewPage({super.key, required this.task});
  final Task task;
  final DocumentViewerController _documentViewerController =
      Get.find<DocumentViewerController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeaderWidget(title: "Documents"),
      body: Column(
        children: [
          Expanded(child: _documentList(task.documents)),
        ],
      ),
    );
  }

  Widget _documentList(List<Document> documents) {
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      itemCount: documents.length + 1,
      itemBuilder: (context, index) {
        if (index == documents.length) {
          return Container(
            margin: const EdgeInsets.only(top: 10.0),
            height: 20.0,
            alignment: Alignment.bottomCenter,
            color: StateContainer.of(context)?.currTheme.textBackground,
            child: const Text(
              'End of List',
              style: AppStyles.defaultFont,
            ),
          );
        }
        Document doc = documents[index];
        Color bgColor = ColorHelpers.generateColor();
        while (ColorHelpers.checkDarkColor(bgColor)) {
          bgColor = ColorHelpers.generateColor();
        }
        return _documentListItem(context, doc);
      },
    );
  }

  Widget _documentListItem(context, Document doc) {
    Widget item = Container();
    switch (doc.type ?? -1) {
      case 0:
        item = _contactListItem(
          doc,
        );
        break;
      case 1:
        //Video
        item = GestureDetector(
          onTap: () {
            _documentViewerController.openDoc(doc, context);
          },
          child: VideoDocumentWidget(
            doc: doc,
          ),
        );
        break;
      case 2:
        //Text
        item = GestureDetector(
            onTap: () {
              _documentViewerController.openDoc(doc, context);
            },
            child: TextDocumentWidget(
              doc: doc,
              showOptions: true,
            ));
        break;
      case 3:
        //Document
        item = GestureDetector(
            onTap: () {
              _documentViewerController.openDoc(doc, context);
            },
            child: DocumentWidget(
              doc: doc,
            ));
        break;
    }
    return item;
  }

  Widget _errorListItem() {
    return Container();
  }

  Widget _contactListItem(Document contact) {
    List<String> details = contact.desc?.split("|") ?? [];
    if (details.length != 3) {
      return _errorListItem();
    }
    bool hasEmail = details[2] != "";
    bool hasPhone = details[1] != "";
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 20.0, right: 20.0),
      child: Material(
        color: Colors.white,
        elevation: 4.0,
        borderRadius: BorderRadius.circular(7.0),
        child: InkWell(
          onTap: () {
            _documentViewerController.openDoc(contact, Get.context);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "Contact",
                          style: AppStyles.defaultFont.copyWith(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          details[0],
                          style: AppStyles.defaultFont.copyWith(fontSize: 16.0),
                        ),
                      )
                    ],
                  ),
                ),
                hasPhone
                    ? GestureDetector(
                        onTap: () {
                          launchUrl(Uri(scheme: "tel", path: details[1]));
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          padding: const EdgeInsets.all(7.0),
                          margin: const EdgeInsets.only(left: 10.0),
                          decoration: BoxDecoration(
                            color: StateContainer.of(Get.context!)
                                ?.currTheme
                                .darkButton,
                            shape: BoxShape.circle,
                          ),
                          child: FittedBox(
                              child: Icon(
                            Icons.phone,
                            color:
                                StateContainer.of(Get.context!)?.currTheme.lightText,
                          )),
                        ),
                      )
                    : Container(),
                hasEmail
                    ? GestureDetector(
                        onTap: () {
                          launchUrl(Uri(scheme: "mailto", path: details[2]));
                        },
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          padding: const EdgeInsets.all(7.0),
                          margin: const EdgeInsets.only(left: 10.0),
                          decoration: BoxDecoration(
                            color: StateContainer.of(Get.context!)
                                ?.currTheme
                                .darkButton,
                            shape: BoxShape.circle,
                          ),
                          child: FittedBox(
                              child: Icon(
                            Icons.email,
                            color:
                                StateContainer.of(Get.context!)?.currTheme.lightText,
                          )),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
