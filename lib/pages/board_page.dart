import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/database.dart';
import '../services/locationsService.dart';
import '../windows/change_profil_window.dart';

class BoardPage extends StatefulWidget{
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage>{


  testDatatoDB() async {
    var stadt = "Playa del Carmen";
    var id = "pq2lqWR3XwTrNIDAsKcaPbX3E0q1";
    var locationData;

    var testProfil = {
      "email": "test@web.de",
      "name": "test",
      "ort": locationData["city"],
      "emailAnzeigen": false,
      "interessen": ["Freilerner"],
      "kinder": [DateTime.now().toString(), DateTime.now().toString()],
      "land": locationData["countryname"],
      "longt": locationData["longt"],
      "latt":  locationData["latt"],
      "reiseart": "Weltreise",
      "aboutme": "",
      "sprachen": ["Englisch"],
      "friendlist": {"empty": true}
    };

    ProfilDatabaseKontroller().addNewProfil(id, testProfil);

  }


  Widget build(BuildContext context){
    return Scaffold(
      body:

      Container(
        margin: EdgeInsets.all(100),
        child: Text("In Arbeit", style: TextStyle(fontSize: 40),)
        )


      );
  }
}
