import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/widgets/contact_card_widget.dart';
import 'package:time_management/widgets/string_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerController extends GetxController {
  RxList<Document> openedDocs = RxList<Document>.empty();
  RxBool homePageView = true.obs;

  Future<void> openDoc(Document doc, context) async {
    bool canOpen = await openDocumentView(doc, context);
    if (canOpen && !isOpened(doc.uid ?? -1)) {
      openedDocs.add(doc);
      update();
    }
  }

  Future<void> closeDoc(Document doc) async {
    if (isOpened(doc.uid ?? -1)) {
      openedDocs.removeWhere((element) => element.uid == doc.uid);
      update();
      return;
    }
  }

  Future<bool> openDocumentView(Document doc, BuildContext context) async {
    switch (doc.type ?? -1) {
      //Contact
      case 0:
        return openContactDialog(doc, context);
      //Video
      case 1:
        return openVideoUrl(doc, context);
      //String
      case 2:
        openStringDialog(doc, context);
        break;
      //Doc
      case 3:
        return openDocumentDoc(doc.path ?? "");

      default:
        break;
    }
    return false;
  }

  Future<bool> openVideoUrl(Document doc, BuildContext context) async {
    try{
      await launchUrl(Uri.parse(doc.path ?? ""));
    }catch(e){
      rethrow;
    }
    return true;
  }

  Future<bool> openContactDialog(Document contact, BuildContext context) async {
    List<String> details = contact.desc?.split("|") ?? [];
    if (details.length != 3) {
      return false;
    }
    showDialog(
        context: context,
        builder: (dContext) {
          return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ContactCardWidget(
                name: details[0],
                phoneNum: details[1],
                email: details[2],
              ));
        }).onError((error, stackTrace) {
      return false;
    });
    return true;
  }

  Future<bool> openStringDialog(Document strDoc, BuildContext context) async {
    showDialog(
        context: context,
        builder: (dContext) {
          return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: StringDialog(
                shortName: strDoc.path,
                text: strDoc.desc,
              ));
        }).onError((error, stackTrace) {
      return false;
    });
    return true;
  }

  Future<bool> openDocumentDoc(String docPath) async {
    OpenResult result = await OpenFile.open(docPath);
    return result.type == ResultType.done;
  }

  bool isOpened(int docUid) {
    for (int i = 0; i < openedDocs.length; i++) {
      if (openedDocs[i].uid == docUid) {
        return true;
      }
    }
    return false;
  }
}
