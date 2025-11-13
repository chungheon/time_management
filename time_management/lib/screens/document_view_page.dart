import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/controllers/document_viewer_controller.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/helpers/color_helpers.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/models/task_model.dart';
import 'package:time_management/screens/add_document_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/document_widget.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/text_document_widget.dart';
import 'package:time_management/widgets/video_document_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewPage extends StatelessWidget {
  DocumentViewPage({super.key, required Task task}) {
    this.task.value = task;
  }
  final Rxn<Task> task = Rxn<Task>();
  final DocumentViewerController _documentViewerController =
      Get.find<DocumentViewerController>();
  final GoalsController _goalsController = Get.find();
  Future<void> onLinkDocs(docs) async {
    await _goalsController.editTask(task.value!,
        docList: task.value!.documents.map<int>((d) => d.uid ?? -1).toList(),
        addDocs: docs);
    var updatedGoal =
        await _goalsController.fetchGoal(task.value!.goal?.uid ?? -1);
    var currGoal = _goalsController.goalList
        .firstWhereOrNull((g) => g.uid == updatedGoal?.uid);
    await _goalsController.updateTask(task.value!, task.value!.goal!);
    if (updatedGoal != null && currGoal != null) {
      await _goalsController.updateGoal(currGoal);
    }
    task.update((task) async {
      task = await _goalsController.fetchTaskById(task!.uid ?? -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeaderWidget(title: "Documents"),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Obx(() => _documentList(task.value!.documents)))),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Material(
                elevation: 4.0,
                color: StateContainer.of(context)?.currTheme.button,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    var curr = Get.currentRoute;
                    if (task.value?.goal == null) {
                      return;
                    }
                    Get.to(() => AddDocumentPage(
                        goal: task.value!.goal,
                        returnRoute: curr,
                        onComplete: (docs) => onLinkDocs(docs)));
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    height: 50.0,
                    width: 50.0,
                    padding: const EdgeInsets.all(6.0),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: FittedBox(
                        child: Text(
                      "+DOC",
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: AppStyles.defaultFont
                          .copyWith(fontWeight: FontWeight.bold),
                    )),
                  ),
                ),
              ),
            ),
          ),
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
                            color: StateContainer.of(Get.context!)
                                ?.currTheme
                                .lightText,
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
                            color: StateContainer.of(Get.context!)
                                ?.currTheme
                                .lightText,
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
