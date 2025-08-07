import 'package:flutter/material.dart';
class TagItem extends StatelessWidget {
  const TagItem(
      {super.key,
      this.onTap,
      this.deleteFunc,
      this.title,
      this.color,
      this.maxWidth});

  final Function()? deleteFunc;
  final Function()? onTap;
  final String? title;
  final Color? color;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth ?? 160.0),
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          deleteFunc != null
              ? GestureDetector(
                onTap: (){
                  deleteFunc?.call();
                },
                child: Container(
                    height: 20.0,
                    width: 20.0,
                    margin: const EdgeInsets.only(right: 5.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const FittedBox(child: Icon(Icons.cancel)),
                  ),
              )
              : Container(),
          Flexible(
            fit: FlexFit.loose,
            child: Text(title ?? "", maxLines: 1, overflow: TextOverflow.ellipsis,)),
        ],
      ),
    );
  }
}
