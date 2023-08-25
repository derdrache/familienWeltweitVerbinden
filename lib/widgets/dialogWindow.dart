import 'dart:ui';

import 'package:flutter/material.dart';
import 'Window_topbar.dart';
import '../global/style.dart' as Style;

class CustomAlertDialog extends StatefulWidget {
  String title;
  List<Widget> children;
  List<Widget>? actions;
  double? height;
  var backgroundColor;
  var windowPadding;

  CustomAlertDialog(
      {Key? key,
      this.title = "",
      required this.children,
      this.actions,
      this.height,
      //this.backgroundColor = Colors.white,
      this.windowPadding = const EdgeInsets.all(10)
      }) : super(key: key);

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Style.roundedCorners))),
      contentPadding: EdgeInsets.zero,
      insetPadding: widget.windowPadding,
      actions: widget.actions,
      content: SizedBox(
        height: widget.height,
        width: 600,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              }),
              child: Container(
                margin: const EdgeInsets.all(10),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (widget.title.isNotEmpty)
                      Center(
                          child: WindowTopbar(
                        title: widget.title,
                      )),
                    if(widget.title.isNotEmpty) const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    ...widget.children
                  ],
                ),
              ),
            ),
            Positioned(
              height: 30,
              right: -13,
              top: -7,
              child: InkResponse(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    child: Icon(
                      Icons.close,
                      size: 16,
                    ),
                    backgroundColor: Colors.red,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
