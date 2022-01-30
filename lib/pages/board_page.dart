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
    var locationData = await LocationService().getLocationMapDataGeocode(stadt);
    while(locationData == null){
      locationData = await LocationService().getLocationMapDataGeocode(stadt);
    }
    var testProfil = {
      "email": "test@web.de",
      "name": "test",
      "ort": locationData["city"],
      "emailAnzeigen": false,
      "interessen": [],
      "kinder": [],
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt":  locationData["latt"],
      "reiseart": "Weltreise",
      "aboutme": "",
      "sprachen": ["Englisch"],
      "friendlist": []
    };

    //dbAddNewProfil(testProfil);

  }



  Widget build(BuildContext context){
    return Scaffold(
      body: FloatingActionButton(
        onPressed: () async{
          print(await LocationService().getLocationData("Playa del Carmen"));
        },
      )
      /*
      Container(
        margin: EdgeInsets.all(100),
        child: Text("In Arbeit", style: TextStyle(fontSize: 40),)
        )

       */
      );
  }
}
