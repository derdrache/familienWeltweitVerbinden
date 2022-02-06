import 'package:flutter/material.dart';

class UpcomingUpdatesWindow{
  var context;

  UpcomingUpdatesWindow({this.context});


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
                    Text("Test")
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}