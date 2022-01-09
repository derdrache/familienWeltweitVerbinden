import 'package:flutter/material.dart';


import 'setting_page/locationsService.dart';
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

    return Scaffold(
      body: FloatingActionButton(
      onPressed: ()async {
        print(await LocationService().getCountryLocation("Mexiko"));
      },
      )
    );
  }
}
