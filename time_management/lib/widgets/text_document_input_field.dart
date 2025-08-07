import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/input_text_field.dart';

class TextDocumentInputField extends StatefulWidget {
  const TextDocumentInputField(
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
  State<TextDocumentInputField> createState() => _TextDocumentInputFieldState();
}

class _TextDocumentInputFieldState extends State<TextDocumentInputField> {
  final RxString text = "".obs;
  final RxString desc = "".obs;
  bool isHidden = false;

  void updateTextValues() {
    widget.doc.desc = desc.value;
    widget.doc.path = text.value;
  }

  @override
  void initState() {
    text.value = widget.doc.path ?? "";
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
                        "Text",
                        style: AppStyles.defaultFont.copyWith(
                            fontSize: AppFontSizes.header3,
                            fontWeight: FontWeight.bold),
                      ),
                      Obx(
                        () {
                          if (text.isEmpty) {
                            return Text(
                              "Text To Note",
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
                            text.value,
                            style: AppStyles.defaultFont
                                .copyWith(fontSize: AppFontSizes.meta),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
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
          constraints: BoxConstraints(maxHeight: isHidden ? 0 : 140.0),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              InputTextField(
                hintText: "Short Name for Text",
                initialValue: text.value,
                onChanged: (text) {
                  this.text.value = text;
                  updateTextValues();
                },
              ),
              const SizedBox(
                height: 7.0,
              ),
              InputTextField(
                hintText: "Text To Note",
                initialValue: desc.value,
                maxLines: 3,
                inputType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (desc) {
                  this.desc.value = desc;
                  updateTextValues();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
