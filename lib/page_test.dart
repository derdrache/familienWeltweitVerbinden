import 'package:familien_suche/widgets/flexible_date_picker.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var testWidget = FlexibleDatePicker(
      hintText: "test",
      multiDate: true,
    );

    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: testWidget,),
            FloatingActionButton(onPressed: (){
              print(testWidget.getDate());
            })
          ],
        )
      )
    );

  }
}