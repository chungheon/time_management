import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/controllers/document_viewer_controller.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/styles.dart';

class DocumentList extends StatefulWidget {
  const DocumentList({super.key});

  @override
  State<DocumentList> createState() => _DocumentListState();
}

class _DocumentListState extends State<DocumentList> {
  final DocumentViewerController _documentViewerController =
      Get.find<DocumentViewerController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: _documentViewerController,
        builder: (controller) {
          return AnimatedContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            margin: controller.openedDocs.isNotEmpty
                ? const EdgeInsets.only(bottom: 10.0)
                : null,
            duration: const Duration(milliseconds: 300),
            constraints: BoxConstraints(
                maxHeight: controller.openedDocs.isEmpty ? 0 : 50.0),
            child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                children: controller.openedDocs
                    .toList()
                    .map<Widget>((e) => openDocIcon(
                        e, () => controller.openDocumentView(e, context)))
                    .toList()),
          );
        });
  }

  String getContactName(String? desc) {
    final List<String> contact = [];
    contact.addAll(desc?.split("|") ?? ["", "", ""]);
    if (contact[0].isEmpty) {
      return "Contact";
    } else {
      return contact[0];
    }
  }

  Widget openDocIcon(Document doc, Function() onTap) {
    String desc = doc.desc ?? "";
    if (doc.type == DocumentType.Contact.index) {
      desc = getContactName(doc.desc);
    }
    return Padding(
      padding: const EdgeInsets.only(right: 7.0),
      child: Stack(
        children: [
          Material(
            shape: const CircleBorder(),
            elevation: 4.0,
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () {
                onTap();
              },
              child: Container(
                width: 55.0,
                height: 55.0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(width: 1.0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    desc.padRight(2),
                    maxLines: 1,
                    style: AppStyles.defaultFont
                        .copyWith(fontSize: 12.0, height: 0.9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () {
                _documentViewerController.closeDoc(doc);
                if (_documentViewerController.openedDocs.isEmpty) {
                  _documentViewerController.homePageView.value = true;
                }
              },
              child: Container(
                height: 22.0,
                width: 22.0,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
