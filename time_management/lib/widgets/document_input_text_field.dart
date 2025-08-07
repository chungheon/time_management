import 'package:extended_text/extended_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/input_text_field.dart';

class DocumentInputTextField extends StatefulWidget {
  const DocumentInputTextField(
      {super.key,
      required this.doc,
      required this.onRemoveTap,
      required this.onToggleHide,
      required this.initialHide});
  final Document doc;
  final Function() onRemoveTap;
  final Function(bool isHidden) onToggleHide;
  final bool initialHide;
  @override
  State<DocumentInputTextField> createState() => _DocumentInputTextFieldState();
}

class _DocumentInputTextFieldState extends State<DocumentInputTextField> {
  final RxString docPath = "".obs;
  final RxString desc = "".obs;
  bool isHidden = false;
  
  void updateDocDetails() {
    widget.doc.desc = desc.value;
    widget.doc.path = docPath.value;
  }

  Future<void> onTapChangeDoc() async {
    FilePickerResult? pickerResults =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    if (pickerResults?.files.isNotEmpty ?? false) {
      docPath.value = pickerResults!.files.first.path ?? "";
      updateDocDetails();
    }
  }

  @override
  void initState() {
    docPath.value = widget.doc.path ?? "";
    desc.value = widget.doc.desc ?? "";
    isHidden = widget.initialHide;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          child: InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {
                isHidden = !isHidden;
                widget.onToggleHide(isHidden);
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Document",
                        style: AppStyles.defaultFont.copyWith(
                            fontSize: AppFontSizes.header3,
                            fontWeight: FontWeight.bold),
                      ),
                      Obx(
                        () {
                          
                          if (desc.isEmpty) {
                            return Text(
                              "Description of the purpose of document\n",
                              style: AppStyles.defaultFont.copyWith(
                                  fontSize: AppFontSizes.meta,
                                  color: StateContainer.of(context)
                                      ?.currTheme
                                      .hintText),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            );
                          }
                          return Text(
                            desc.value,
                            style: AppStyles.defaultFont
                                .copyWith(fontSize: AppFontSizes.meta),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 5.0,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 40.0,
                    width: 40.0,
                    child: Material(
                      shape: const CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      color: StateContainer.of(context)?.currTheme.removeColor,
                      child: InkWell(
                        onTap: widget.onRemoveTap,
                        child: const Padding(
                          padding: EdgeInsets.only(
                              top: 7.0, bottom: 6.0, left: 7.0, right: 7.0),
                          child: FittedBox(
                            child: Icon(
                              Icons.remove,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 7.0,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: BoxConstraints(maxHeight: isHidden ? 0 : 90.0),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => ExtendedText(
                        docPath.value,
                        style: AppStyles.defaultFont
                            .copyWith(fontSize: AppFontSizes.meta),
                        maxLines: 1,
                        overflowWidget: TextOverflowWidget(
                          position: TextOverflowPosition.start,
                          child: Text(
                            "...",
                            style: AppStyles.defaultFont
                                .copyWith(fontSize: AppFontSizes.meta),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Material(
                      shape: const CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      color: StateContainer.of(context)?.currTheme.hintText,
                      child: InkWell(
                        onTap: onTapChangeDoc,
                        child: Container(
                          height: 40.0,
                          width: 40.0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 6.0),
                          child: const FittedBox(
                            child: Icon(Icons.edit),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 7.0,
              ),
              InputTextField(
                hintText: "Document Description",
                initialValue: desc.value,
                onChanged: (desc) {
                  this.desc.value = desc;
                  updateDocDetails();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}