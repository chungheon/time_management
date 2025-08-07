import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/input_text_field.dart';

class VideoInputTextField extends StatefulWidget {
  const VideoInputTextField(
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
  State<VideoInputTextField> createState() => _VideoInputTextFieldState();
}

class _VideoInputTextFieldState extends State<VideoInputTextField> {
  final RxString videoUrl = "".obs;
  final RxString desc = "".obs;
  bool isHidden = false;

  void updateVideoDetails() {
    widget.doc.desc = desc.value;
    widget.doc.path = videoUrl.value;
  }

  @override
  void initState() {
    videoUrl.value = widget.doc.path ?? "";
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
                        "Video Link (Youtube)",
                        style: AppStyles.defaultFont.copyWith(
                            fontSize: AppFontSizes.header3,
                            fontWeight: FontWeight.bold),
                      ),
                      Obx(
                        () {
                          if (desc.isEmpty) {
                            return Text(
                              "Description of the purpose of video\n",
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
              InputTextField(
                hintText: "Video Url",
                initialValue: videoUrl.value,
                onChanged: (videoUrl) {
                  this.videoUrl.value = videoUrl;
                  updateVideoDetails();
                },
              ),
              const SizedBox(
                height: 7.0,
              ),
              InputTextField(
                hintText: "Video Description",
                initialValue: desc.value,
                onChanged: (desc) {
                  this.desc.value = desc;
                  updateVideoDetails();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}