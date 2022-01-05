import 'package:flutter/material.dart';

import 'setting_page/locationsService.dart';
import '../database.dart';


class BoardPage extends StatefulWidget{
  _BoardPageState createState() => _BoardPageState();
}



class _BoardPageState extends State<BoardPage>{


  testDatatoDB() async {
    var stadt = "Puerto Vallarta";
    var locationData = await LocationService().getLocationMapData(stadt);

    var data = {
      "email": "test45@test.com",
      "name": "test45",
      "ort": locationData["city"],
      "interessen": ["Weltreise"],
      "kinder": [12],
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt":  locationData["latt"]
    };
    dbAddNewProfil(data);

  }

  Widget build(BuildContext context){
    var textController = TextEditingController();

    return Scaffold(
      body: FloatingActionButton(
      onPressed: (){
        testDatatoDB();
      },
      )
    );
  }
}
