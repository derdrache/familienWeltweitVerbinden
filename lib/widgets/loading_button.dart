import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  var color = Colors.white;
  LoadingButton({Key key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(10),
        child: CircularProgressIndicator(
          color: color,
        ));
  }
}
