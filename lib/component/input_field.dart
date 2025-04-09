import 'package:calendar_app/component/theme/theme.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class InputField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController? controller;
  final Widget? widget;

  InputField({
    Key? key,
    required this.title,
    required this.hint,
    this.controller,
    this.widget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TitleStyle),
              Container(
                  margin: EdgeInsets.only(top: 8.0),
                  padding: EdgeInsets.only(left: 14),
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                            readOnly: widget == null ? false : true,
                            autofocus: false,
                            controller: controller,
                            cursorColor: Get.isDarkMode
                                ? Colors.grey[100]
                                : Colors.grey[700],
                            style: SubTitleStyle,
                            decoration: InputDecoration(
                                hintText: hint,
                                hintStyle: SubTitleStyle,
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        context.theme.scaffoldBackgroundColor,
                                    width: 0,
                                  ),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        context.theme.scaffoldBackgroundColor,
                                    width: 0,
                                  ),
                                ))),
                      ),
                      widget == null
                          ? Container()
                          : Container(
                              child: widget,
                            )
                    ],
                  )),
            ],
          ),
        ));
  }
}
