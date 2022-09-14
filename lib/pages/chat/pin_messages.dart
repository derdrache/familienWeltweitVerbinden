import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

class pinMessagesPage extends StatelessWidget {
  var pinMessages;

  pinMessagesPage({this.pinMessages, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Angeheftete Nachrichten",
      ),
      body: Column(children: [

      ],),
    );
  }
}
