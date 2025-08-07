import 'package:flutter/material.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactCardWidget extends StatelessWidget {
  const ContactCardWidget({super.key, this.name, this.phoneNum, this.email});
  final String? name;
  final String? phoneNum;
  final String? email;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: StateContainer.of(context)?.currTheme.background,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name:${name ?? ""}",
                  maxLines: 2,
                  style: AppStyles.defaultFont.copyWith(
                      color: StateContainer.of(context)?.currTheme.text,
                      fontSize: AppFontSizes.body),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Phone:${phoneNum ?? ""}",
                  maxLines: 1,
                  style: AppStyles.defaultFont.copyWith(
                      color: StateContainer.of(context)?.currTheme.text,
                      fontSize: AppFontSizes.body),
                ),
                Text(
                  "Email: ${email ?? ""}",
                  maxLines: 2,
                  style: AppStyles.defaultFont.copyWith(
                      color: StateContainer.of(context)?.currTheme.text,
                      fontSize: AppFontSizes.body),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: (){
                  launchUrl(Uri(scheme:"tel", path:phoneNum));
                },
                child: Container(
                  width: 45.0,
                  height: 45.0,
                  padding: const EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    color: StateContainer.of(context)?.currTheme.darkButton,
                    shape: BoxShape.circle,
                  ),
                  child: FittedBox(
                      child: Icon(
                    Icons.phone,
                    color: StateContainer.of(context)?.currTheme.lightText,
                  )),
                ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              GestureDetector(
                onTap: (){
                  launchUrl(Uri(scheme:"mailto", path:email));
                },
                child: Container(
                  width: 45.0,
                  height: 45.0,
                  padding: const EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    color: StateContainer.of(context)?.currTheme.darkButton,
                    shape: BoxShape.circle,
                  ),
                  child: FittedBox(
                      child: Icon(
                    Icons.email,
                    color: StateContainer.of(context)?.currTheme.lightText,
                  )),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
