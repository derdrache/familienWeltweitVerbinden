import 'dart:ui';

import 'package:flutter/material.dart';
import 'Window_topbar.dart';



class CustomAlertDialog extends StatefulWidget {
  var title = "";
  List<Widget> children = [];
  double height = double.maxFinite;

  CustomAlertDialog({
    Key key,
    this.title,
    this.children,
    this.height
  }) : super(key: key);

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {

  _closeWindow(){
    Navigator.pop(context);
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))
      ),
      contentPadding: EdgeInsets.zero,
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
                margin: const EdgeInsets.only(left: 10, right: 10),
                child: ListView(
                  children: [
                    WindowTopbar(title: widget.title),
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
                  onTap: () => _closeWindow(),
                  child: const CircleAvatar(
                    child: Icon(Icons.close, size: 16,),
                    backgroundColor: Colors.red,
                  )
              ),
            ),
          ] ,
        ),
      ),

    );
  }
}
