import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';


class StadtinformationsPage extends StatefulWidget {
  var ort;

  StadtinformationsPage({this.ort, Key key}) : super(key: key);

  @override
  _StadtinformationsPageState createState() => _StadtinformationsPageState();
}

class _StadtinformationsPageState extends State<StadtinformationsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        title: widget.ort["names"].join(" / ")
      ),
      body: Container(),
    );
  }
}
