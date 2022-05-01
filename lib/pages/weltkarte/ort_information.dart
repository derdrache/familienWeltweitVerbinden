import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';


class OrtInformationPage extends StatefulWidget {
  var ort; //{Names, latt, longt}

  OrtInformationPage({this.ort, Key key}) : super(key: key);

  @override
  _OrtInformationPageState createState() => _OrtInformationPageState();
}

class _OrtInformationPageState extends State<OrtInformationPage> {

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
