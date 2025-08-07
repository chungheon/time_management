import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/app_state_container.dart';
import 'package:time_management/models/document_model.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/input_text_field.dart';

class ContactInputTextField extends StatefulWidget {
  const ContactInputTextField({
    super.key,
    required this.doc,
    required this.onRemoveTap,
    required this.onToggleHide, required this.initialHide,
  });
  final Document doc;
  final Function() onRemoveTap;
  final Function(bool isHidden) onToggleHide;
  final bool initialHide;

  @override
  State<ContactInputTextField> createState() => _ContactInputTextFieldState();
}

class _ContactInputTextFieldState extends State<ContactInputTextField> {
  bool isHidden = false;

  RxString name = "".obs;

  String phone = "";

  String email = "";
  @override
  void initState() {
    List<String> contactData = widget.doc.desc?.split("|") ?? ["", "", ""];
    name.value = contactData[0 % contactData.length];
    phone = contactData[1 % contactData.length];
    email = contactData[2 % contactData.length];
    isHidden = widget.initialHide;
    super.initState();
  }

  void updateContactDesc() {
    widget.doc.desc = "${name.value}|$phone|$email";
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
                        "Contact",
                        style: AppStyles.defaultFont.copyWith(
                            fontSize: AppFontSizes.header3,
                            fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: Obx(
                              () {
                                if (name.isEmpty) {
                                  return Text(
                                    "Name",
                                    style: AppStyles.defaultFont.copyWith(
                                        fontSize: AppFontSizes.meta,
                                        color: StateContainer.of(context)
                                            ?.currTheme
                                            .hintText),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                                return Text(
                                  name.value,
                                  style: AppStyles.defaultFont
                                      .copyWith(fontSize: AppFontSizes.meta),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                        ],
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
                hintText: "Contact Name",
                initialValue: name.value,
                onChanged: (name) {
                  this.name.value = name;
                  updateContactDesc();
                },
              ),
              const SizedBox(
                height: 7.0,
              ),
              InputTextField(
                hintText: "Contact Phone",
                initialValue: phone,
                inputType: TextInputType.phone,
                onChanged: (phone) {
                  this.phone = phone;
                  updateContactDesc();
                },
              ),
              const SizedBox(
                height: 7.0,
              ),
              InputTextField(
                hintText: "Contact Email",
                initialValue: email,
                inputType: TextInputType.emailAddress,
                onChanged: (email) {
                  this.email = email;
                  updateContactDesc();
                  // widget.onTextChanged(name.value, phone, this.email);
                },
              )
            ],
          ),
        ),
      ],
    );
  }
}
