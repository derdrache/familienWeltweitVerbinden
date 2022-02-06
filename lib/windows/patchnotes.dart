import 'package:familien_suche/global/custom_widgets.dart';
import 'package:flutter/material.dart';

class PatchnotesWindow{
  var context;

  PatchnotesWindow({this.context});


  openWindow(){
    return showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            content: Scaffold(
              body: SizedBox(
                height: 400,
                width: double.maxFinite,
                child: ListView(
                  children: [
                    WindowTopbar(title: "Patchnotes"),
                    Text("1.0.0")
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}