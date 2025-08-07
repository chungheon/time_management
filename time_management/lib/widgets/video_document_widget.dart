import 'package:flutter/material.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/constants/effect_constants.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/styles.dart';

class VideoDocumentWidget extends StatelessWidget {
  const VideoDocumentWidget({
    super.key,
    required this.doc,
    this.isSelected = false,
    this.showOptions = false,
  });

  final Document doc;
  final bool isSelected;
  final bool showOptions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      margin: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context)?.currTheme.background,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [EffectConstants.shadowEffectDown(context)],
        border: isSelected
            ? Border.all(
                width: 1.0,
                color:
                    StateContainer.of(context)?.currTheme.text ?? Colors.black)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${doc.desc}",
                  style: AppStyles.inputTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${doc.path}",
                  style: AppStyles.defaultFont.copyWith(
                    fontSize: AppFontSizes.body,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          !showOptions
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 1.0),
                        ),
                        child: const Icon(
                          Icons.open_in_browser,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
