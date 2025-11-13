import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/dialog_constants.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/models/goal_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/auto_complete_goals_input.dart';
import 'package:time_management/widgets/contact_input_text_field.dart';
import 'package:time_management/widgets/document_input_text_field.dart';
import 'package:time_management/widgets/loading_page_widget.dart';
import 'package:time_management/widgets/page_header_widget.dart';
import 'package:time_management/widgets/text_document_input_field.dart';
import 'package:time_management/widgets/video_input_text_field.dart';

class AddDocumentPage extends StatelessWidget {
  AddDocumentPage({
    super.key,
    Goal? goal,
    required this.onComplete,
    this.returnRoute,
  }) {
    if (goal != null) {
      selectedGoal.value = goal;
      canEditGoal.value = false;
    }
  }

  final GoalsController _goalsController = Get.find<GoalsController>();
  final Function(List<Document> selectedDocs) onComplete;
  final String? returnRoute;
  final Rxn<Goal> selectedGoal = Rxn<Goal>();
  final RxList<Document> documentList = RxList<Document>();
  final RxList<bool> _hiddenList = RxList<bool>();
  final ScrollController scrollController = ScrollController();
  final RxBool showAdd = false.obs;
  final RxBool canEditGoal = true.obs;

  void onTapDocument(int docType) {
    Document doc = Document(
        uid: -1, goalUid: selectedGoal.value?.uid ?? -1, type: docType);
    _hiddenList.add(false);
    documentList.add(doc);
    return;
  }

  void addDocument(String docPath) {
    Document doc = Document(
      uid: -1,
      goalUid: selectedGoal.value?.uid ?? -1,
      type: DocumentType.Doc.index,
      path: docPath,
    );
    _hiddenList.add(false);
    documentList.add(doc);
  }

  Future<void> onTapAddDocument() async {
    FilePickerResult? pickerResults =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    for (int i = 0; i < (pickerResults?.files.length ?? 0); i++) {
      addDocument(pickerResults!.files[i].path ?? "Error Path");
    }
  }

  void updateSelectedGoalUid() {
    var docListIterator = documentList.iterator;
    while (docListIterator.moveNext()) {
      docListIterator.current.goalUid = selectedGoal.value?.uid ?? -1;
    }
  }

  void onKeyboardFocus(context) {
    var diff = (FocusManager.instance.primaryFocus?.rect.bottom ?? -1) -
        (MediaQuery.of(context).viewInsets.bottom);
    if (diff > 10) {
      scrollController.animateTo(scrollController.position.pixels + diff,
          duration: const Duration(milliseconds: 100), curve: Curves.linear);
    }
  }

  void onScrollListener() {
    double limit = 135.0;
    if (!canEditGoal.value) {
      limit = 75.0;
    }
    if (scrollController.position.pixels >= limit &&
        Get.mediaQuery.viewInsets.bottom <= 0) {
      showAdd.value = true;
    } else {
      showAdd.value = false;
    }
  }

  Future<List<Document>> fetchCreatedDocuments(List<int> docIds) async {
    List<Document> docs = [];
    for (int id in docIds) {
      Document? doc = await _goalsController.fetchDocById(id);
      if (doc != null) docs.add(doc);
    }
    return docs;
  }

  Future<List<Document>> createDocuments() async {
    List<int> docIds = [];
    for (int i = 0; i < documentList.length; i++) {
      int? docId = await _goalsController.createDocument(
          documentList[i], selectedGoal.value?.uid ?? -1);

      if (docId != null) docIds.add(docId);
    }

    return await fetchCreatedDocuments(docIds);
  }

  Future<void> onTapLinkDocuments() async {
    Get.off(() => LoadingPageWidget(
          asyncFunc: () async {
            var docs = await createDocuments();
            await onComplete(docs);
          },
          onComplete: (docs) async {
            Get.until((route) => returnRoute != null
                ? route.settings.name == returnRoute!
                : route.isFirst);
          },
        ));
  }

  void onToggleHide(int index, bool isHidden) {
    _hiddenList[index] = isHidden;
  }

  @override
  Widget build(BuildContext context) {
    scrollController.removeListener(onScrollListener);
    scrollController.addListener(onScrollListener);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (pop, _) {
        if (!pop) {
          showDialog(
              context: context,
              builder: (_) =>
                  DialogConstants.exitDialog(returnRoute: returnRoute));
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: StateContainer.of(context)?.currTheme.background,
        appBar: PageHeaderWidget(
          title: "Add Documents",
          returnRoute: returnRoute,
          // exitDialog: DialogConstants.exitDialog(returnRoute: returnRoute),
        ),
        body: Column(
          children: [
            Obx(() {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                constraints:
                    BoxConstraints(maxHeight: showAdd.value ? 200.0 : 0.0),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    height: 90.0,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                        color: StateContainer.of(context)?.currTheme.background,
                        boxShadow: !showAdd.value
                            ? []
                            : [
                                EffectConstants.shadowEffectDown(context),
                              ]),
                    child: _typeSelectionWidget(context),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10.0),
            Expanded(
              child: Obx(
                () {
                  if (MediaQuery.of(context).viewInsets.bottom != 0) {
                    onKeyboardFocus(context);
                  }
                  return ListView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    controller: scrollController,
                    children: [
                      const SizedBox(
                        height: 10.0,
                      ),
                      canEditGoal.value
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Obx(
                                () => AutoCompleteGoalsInput(
                                  title: "Goal",
                                  hintText: "Which goal is it linked to?",
                                  initialValue: selectedGoal.value,
                                  onSelected: (Goal selectedGoal) {
                                    this.selectedGoal.value = selectedGoal;
                                  },
                                ),
                              ),
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _typeSelectionWidget(context),
                      ),
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        reverse: true,
                        children: _documentListDisplay(context),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              height: 65.0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              decoration: BoxDecoration(
                  color: StateContainer.of(context)?.currTheme.background,
                  boxShadow: [EffectConstants.shadowEffectUp(context)]),
              child: SizedBox.expand(
                child: Material(
                  color: StateContainer.of(context)?.currTheme.button,
                  borderRadius: BorderRadius.circular(7.0),
                  elevation: 4.0,
                  child: InkWell(
                    onTap: onTapLinkDocuments,
                    child: Center(
                        child: Text(
                      "Link Documents",
                      style: AppStyles.defaultFont.copyWith(
                          fontSize: AppFontSizes.header3,
                          fontWeight: FontWeight.bold,
                          color: StateContainer.of(context)?.currTheme.text),
                    )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeSelectionWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Obx(() {
              return Text(
                "Documents List: ${documentList.length} items",
                style: AppStyles.defaultFont.copyWith(
                  fontSize: AppFontSizes.body,
                ),
              );
            }),
          ),
          const SizedBox(
            height: 5.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: StateContainer.of(context)?.currTheme.darkButton,
                borderRadius: BorderRadius.circular(20.0),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    onTapDocument(DocumentType.Contact.index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7.0, vertical: 7.0),
                    child: Text(
                      "Contact +",
                      style: AppStyles.defaultFont.copyWith(
                          fontSize: AppFontSizes.body,
                          color:
                              StateContainer.of(context)?.currTheme.lightText),
                    ),
                  ),
                ),
              ),
              Material(
                color: StateContainer.of(context)?.currTheme.darkButton,
                borderRadius: BorderRadius.circular(20.0),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    onTapDocument(DocumentType.Video.index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7.0, vertical: 7.0),
                    child: Text(
                      "Video +",
                      style: AppStyles.defaultFont.copyWith(
                          fontSize: AppFontSizes.body,
                          color:
                              StateContainer.of(context)?.currTheme.lightText),
                    ),
                  ),
                ),
              ),
              Material(
                color: StateContainer.of(context)?.currTheme.darkButton,
                borderRadius: BorderRadius.circular(20.0),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    onTapDocument(DocumentType.String.index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7.0, vertical: 7.0),
                    child: Text(
                      "Text +",
                      style: AppStyles.defaultFont.copyWith(
                          fontSize: AppFontSizes.body,
                          color:
                              StateContainer.of(context)?.currTheme.lightText),
                    ),
                  ),
                ),
              ),
              Material(
                color: StateContainer.of(context)?.currTheme.darkButton,
                borderRadius: BorderRadius.circular(20.0),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: onTapAddDocument,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7.0, vertical: 7.0),
                    child: Text(
                      "Document +",
                      style: AppStyles.defaultFont.copyWith(
                          fontSize: AppFontSizes.body,
                          color:
                              StateContainer.of(context)?.currTheme.lightText),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5.0,
          ),
        ],
      ),
    );
  }

  List<Widget> _documentListDisplay(BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < documentList.length; i++) {
      Widget widget = Container();
      switch (documentList[i].type ?? -1) {
        case 0:
          //Contact

          widget = _contactLayout(i);

          break;
        case 1:
          //Video
          widget = _videoLayout(i);
          break;
        case 2:
          //Text
          widget = _textLayout(i);
          break;
        case 3:
          //Document
          widget = _documentLayout(i);
          break;
        default:
          //Empty
          widget = Container(
            color: StateContainer.of(context)?.currTheme.hintText,
            child: Text(
              "ERROR LOADING",
              style: AppStyles.defaultFont
                  .copyWith(fontSize: AppFontSizes.header3),
            ),
          );
          break;
      }
      widget = Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(bottom: 5.0, left: 20.0, right: 20.0),
            child: widget,
          ),
          Container(
            height: 2.0,
            width: double.infinity,
            color: StateContainer.of(context)?.currTheme.darkButton,
          ),
        ],
      );
      widgets.add(widget);
    }
    return widgets;
  }

  Widget _contactLayout(int index) {
    return ContactInputTextField(
      doc: documentList[index],
      onRemoveTap: () {
        documentList.removeAt(index);
        _hiddenList.removeAt(index);
      },
      onToggleHide: (isHidden) {
        onToggleHide(index, isHidden);
      },
      initialHide: _hiddenList[index],
    );
  }

  Widget _videoLayout(int index) {
    return VideoInputTextField(
      doc: documentList[index],
      onRemoveTap: () {
        documentList.removeAt(index);
        _hiddenList.removeAt(index);
      },
      onToggleHide: (isHidden) {
        onToggleHide(index, isHidden);
      },
      initialHide: _hiddenList[index],
    );
  }

  Widget _textLayout(int index) {
    return TextDocumentInputField(
      doc: documentList[index],
      onRemoveTap: () {
        documentList.removeAt(index);
        _hiddenList.removeAt(index);
      },
      onToggleHide: (isHidden) {
        onToggleHide(index, isHidden);
      },
      initialHide: _hiddenList[index],
    );
  }

  Widget _documentLayout(int index) {
    return DocumentInputTextField(
      doc: documentList[index],
      onRemoveTap: () {
        documentList.removeAt(index);
        _hiddenList.removeAt(index);
      },
      onToggleHide: (isHidden) {
        onToggleHide(index, isHidden);
      },
      initialHide: _hiddenList[index],
    );
  }
}
