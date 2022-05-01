import 'package:flutter/material.dart';

import '../../global/custom_widgets.dart';

class CreateOrtInformationPage extends StatefulWidget {
  const CreateOrtInformationPage({Key key}) : super(key: key);

  @override
  _CreateOrtInformationPageState createState() => _CreateOrtInformationPageState();
}

class _CreateOrtInformationPageState extends State<CreateOrtInformationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
          title: "Ort Information erstellen"
      ),
      body: Container(),
    );
  }
}
