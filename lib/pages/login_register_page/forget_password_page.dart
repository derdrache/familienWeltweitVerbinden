import 'package:flutter/material.dart';

import '../../custom_widgets.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar("Passwort vergessen", ForgetPasswordPage()),
      body: Text("Passwort vergessen")
    );
  }
}
