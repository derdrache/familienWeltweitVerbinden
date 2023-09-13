import 'dart:ui';

import 'package:flutter/material.dart';
import '../widgets/Window_topbar.dart';
import '../global/style.dart' as style;

class CustomAlertDialog extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final double? height;
  final EdgeInsets windowPadding;

  const CustomAlertDialog(
      {Key? key,
      this.title = "",
      required this.children,
      this.actions,
      this.height,
      this.windowPadding = const EdgeInsets.all(10)
      }) : super(key: key);

  @override
  State<CustomAlertDialog> createState() => _CustomAlertDialogState();

}

class _CustomAlertDialogState extends State<CustomAlertDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(style.roundedCorners))),
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
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
