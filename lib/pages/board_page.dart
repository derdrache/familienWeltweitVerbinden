import 'package:flutter/material.dart';


import '../services/locationsService.dart';
import '../services/database.dart';
import '../windows/change_profil_window.dart';

class BoardPage extends StatefulWidget{
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage>{


  testDatatoDB() async {
    var stadt = "Puerto Morelos";
    var locationData = await LocationService().getLocationMapDataGoogle(stadt);
    var testProfil = {
      "email": "test3@web.de",
      "name": "test3",
      "ort": locationData["city"],
      "interessen": [],
      "kinder": [],
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt":  locationData["latt"],
      "reiseart": "Weltreise",
      "aboutme": "",
      "sprachen": ["Deutsch", "Englisch"],
      "friendlist": []
    };

    dbAddNewProfil(testProfil["email"], testProfil);

  }



  Widget build(BuildContext context){
    var textController = TextEditingController();


    return Scaffold(
      body: Container(
        child: FloatingActionButton(
            onPressed: (){
              testDatatoDB();
            }
        )
      )
    );
  }
}
