import 'package:flutter/material.dart';

class SettingAppBar extends StatelessWidget with PreferredSizeWidget {
  @override
  final Size preferredSize = Size.fromHeight(50.0);
  final String title;

  SettingAppBar(this.title);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        title: Center(
          child: Container(
            padding: EdgeInsets.only(right:40),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.black
              )
            )
          )
        ),
    backgroundColor: Colors.grey,
    elevation: 0.0
    );
  }
}