import 'package:familien_suche/widgets/flexible_date_picker.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlexibleDatePicker(

          ),
        )
      )
    );

  }
}