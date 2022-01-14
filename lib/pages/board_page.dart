import 'package:flutter/material.dart';


import '../locationsService.dart';
import '../database.dart';

class BoardPage extends StatefulWidget{
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage>{


  testDatatoDB() async {
    var stadt = "United Arab Emirates";
    var locationData = await LocationService().getLocationMapDataGoogle(stadt);
    var data = {
      "email": "test010@test.com",
      "name": "test010",
      "ort": locationData["city"],
      "interessen": [ "Freilerner"],
      "kinder": [7,9, 11, 13],
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt":  locationData["latt"]
    };
    print(data);
    //dbAddNewProfil(data);

  }



  Widget build(BuildContext context){
    var textController = TextEditingController();
    var testProfil = {
      "interessen": ["Weltreise", "Freilerner"],
      "ort": "Tizimín",
      //"kinder": [Timestamp(seconds=1451106000, nanoseconds=0), Timestamp(seconds=1213938000, nanoseconds=0)],
      "latt": 21.1454686,
      "name": "test007",
      "land": "Mexiko",
      "email": "test007@test.com",
      "longt": -88.1496087
    };

    return Scaffold(
      body: Container(
        child: FloatingActionButton(
            onPressed: () => print("test")
        )
      )
    );
  }
}
