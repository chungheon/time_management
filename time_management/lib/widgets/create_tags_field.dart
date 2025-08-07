import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/models/tag_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/tag_item.dart';

class CreateTagsField extends StatelessWidget {
  CreateTagsField({this.focusNode, this.padding, required this.tags, super.key});
  final FocusNode? focusNode;
  final EdgeInsets? padding;
  final RxList<Tag> tags;
  final TextEditingController tagInputController = TextEditingController();
  final ScrollController tagsScrollController = ScrollController();
  final RxBool added = false.obs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Obx(
              () => Text(
                'Tags ${tags.isNotEmpty ? "${tags.length.toString()} tags" : ""}',
                style: AppStyles.inputTitle(context),
              ),
            ),
          ),
          Container(
            height: 100.0,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8.0),
            child: SingleChildScrollView(
              controller: tagsScrollController,
              child: Obx(() {
                WidgetsBinding.instance.addPostFrameCallback((time) {
                  if (added.value) {
                    tagsScrollController.animateTo(
                        tagsScrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.linear);
                    added.value = false;
                  }
                });
                return Wrap(
                  runSpacing: 5.0,
                  spacing: 10.0,
                  children: tags.asMap().entries.map<Widget>((entry) {
                    return TagItem(
                      deleteFunc: () {
                        tags.removeAt(entry.key);
                      },
                      title: entry.value.name,
                      color:
                          StateContainer.of(context)?.currTheme.textBackground,
                    );
                  }).toList(),
                );
              }),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(focusNode);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: StateContainer.of(context)
                            ?.currTheme
                            .textBackground,
                        borderRadius: BorderRadius.circular(5.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: tagInputController,
                      textInputAction: TextInputAction.done,
                      style: AppStyles.inputText(context),
                      focusNode: focusNode,
                      maxLines: 1,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Create Tags for goals',
                        hintStyle: AppStyles.inputHint(context),
                        border: InputBorder.none,
                      ),
                      onEditingComplete: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  tags.add(Tag(
                    uid: -1,
                    goalUid: -1,
                    name: tagInputController.text,
                  ));
                  tagInputController.clear();
                  added.value = true;
                },
                child: Container(
                  height: 40.0,
                  width: 40.0,
                  margin: const EdgeInsets.only(left: 8.0),
                  padding: const EdgeInsets.all(1.0),
                  decoration: BoxDecoration(
                      color: StateContainer.of(context)?.currTheme.textBackground,
                      shape: BoxShape.circle),
                  child: FittedBox(
                    child: Icon(
                      Icons.add_rounded,
                      color: StateContainer.of(context)?.currTheme.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
