import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:familien_suche/windows/about_project.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/variablen.dart' as global_var;
import '../services/database.dart';
import '../services/locationsService.dart';

class BoardPage extends StatefulWidget{
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage>{
/*
  createTestAccount() async {
    var name = "test15";
    var city ="Bacalar";

    var randomInteressen = global_var.interessenListe..shuffle();
    Random random = new Random();
    int randomNumberChildrens = random.nextInt(5) + 1;
    var kinderListe = [];

    for(var i = 0; i<randomNumberChildrens; i++){
      kinderListe.add(
          DateTime.now().subtract(Duration(days: 365*random.nextInt(18))).toString()
      );
    }

    var ortMapData = await LocationService().getLocationMapDataGoogle2(city);

    var data = {
      "email": name+"@web.de",
      "emailAnzeigen": false,
      "name": name,
      "ort": ortMapData[0]["city"],
      "interessen": [randomInteressen[0], randomInteressen[1], randomInteressen[2]],
      "kinder": kinderListe,
      "land": ortMapData[0]["countryname"],
      "longt": ortMapData[0]["longt"],
      "latt":  ortMapData[0]["latt"],
      "reiseart": (global_var.reisearten..shuffle()).first,
      "aboutme": "",
      "sprachen": global_var.sprachenListe,
      "friendlist": {"empty": true},
      "token": "fNWNg6tkTJeqlqKHnwgD-5:APA91bFUQ7MT-4fBOOwDCOFt8057nadZqFUzN6OwHGWVUWY3w7ylhid8dClqQuuT9Qg3cpoudAvMtMs0I_m8QadXjyGf0koBvnGrJyRbrPA_1Wogdv0NSu5G4kDiYezatujlrHjy9a9e"
    };

    ProfilDatabase().addNewProfil(name, data);

  }


 */
  getMethod() async {
    var url = Uri.parse("https://familiesworldwide.000webhostapp.com/database/getAllProfils.php");
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var responseBody = json.decode(res.body);

    return responseBody;
  }


  Widget build(BuildContext context){
    return Scaffold(
      body: FloatingActionButton(
        onPressed: () async {

        },
      )
    );



      /*
      getAllProfils Beispiel

      FutureBuilder(
        future: getMethod(),
        builder: (context, snapshot){
          List snap = snapshot.data;
          if(snapshot.connectionState == ConnectionState.waiting){
            return CircularProgressIndicator();
          }
          if(snapshot.hasError){
            return Text("Error fetching Data");
          }
          return ListView.builder(
            itemCount: snap.length,
            itemBuilder: (context, index){
              return ListTile(
                title: Text(snap[index]["name"]),
                subtitle: Text(snap[index]["email"]),
              );
            }
          );
        },
      )

      );

       */
  }
}
