import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../database.dart';


class ErkundenPage extends StatefulWidget{
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  var originalProfils = [];
  var profilCountries = []; // Landebene?
  var profilsBetween = []; //mehrere Städe verbinden
  var profilsCities = []; //Stadtebene
  var aktiveProfils = [];

  void initState () {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_){
      _asyncMethod();
    });

  }
  _asyncMethod() async{
    var getProfils = await dbGetAllProfils();
    setState(() {
      originalProfils = getProfils;
      createAndSetZoomProfils();
      aktiveProfils = profilsCities;

    });
  }

  createAndSetZoomProfils(){
    setState(() {
      profilsCities = createProfilCities();
      profilsBetween = createProfilBetween(); // wirft noch zu viele zusammen
      // Länder

    });

  }

  createProfilBetween(){
    var newProfils = [];

    profilsCities.forEach((originalProfil) {
      print(originalProfil);
      var newPoint = false;
      var abstand = 1.5;

      for(var i = 0; i< newProfils.length; i++){
        double originalLatt = originalProfil["latt"];
        double newLatt = newProfils[i]["latt"];
        double originalLongth = originalProfil["longt"];
        double newLongth = newProfils[i]["longt"];
        bool check = (newLatt + abstand >= originalLatt && newLatt - abstand <= originalLatt) &&
                     (newLongth + abstand >= originalLongth && newLongth - abstand<= originalLongth);

        if(check){
          newPoint = true;
          newProfils[i]["name"] = (int.parse(newProfils[i]["name"]) + int.parse(originalProfil["name"])).toString();
        }
      };

      if(!newPoint){
        newProfils.add({
          "ort": originalProfil["ort"],
          "name": originalProfil["name"],
          "latt": originalProfil["latt"],
          "longt": originalProfil["longt"]
        });
      }
    });
    print(newProfils);
    return newProfils;
  }

  createProfilCities(){
    var newProfils = [];

    originalProfils.forEach((originalProfil) {
      var newCity = false;

      for(var i = 0; i< newProfils.length; i++){
        if(originalProfil["ort"] == newProfils[i]["ort"]){
          newCity = true;
          newProfils[i]["name"] = (int.parse(newProfils[i]["name"]) + 1).toString();
        }
      };

      if(!newCity){
        newProfils.add({
          "ort": originalProfil["ort"],
          "name": "1",
          "latt": originalProfil["latt"],
          "longt": originalProfil["longt"]
        });
      }
    });

    return newProfils;
  }


  Widget build(BuildContext context){
    List<Marker> allMarker = [];

    Marker ownMarker(text, position,  buttonFunction){
      return Marker(
        width: 30.0,
        height: 30.0,
        point: position,
        builder: (ctx) => FloatingActionButton.small(
          child: Text(text),
          onPressed: buttonFunction,
        ),
      );
    }

    changeProfil(zoom){
      var choosenProfils = [];
      if(zoom! > 6.5){
        choosenProfils = profilsCities;
      } else if(zoom! > 4.5){
        choosenProfils = profilsBetween;
      } else{
        //choosenProfils = profilsZoom1;
      }

      setState(() {
        aktiveProfils = choosenProfils;
      });
    }

    createMarker() async{
      List<Marker> markerList = [];
      aktiveProfils.forEach((profil){
        var position = LatLng(profil["latt"], profil["longt"]);
        markerList.add(ownMarker(profil["name"], position, null));
      });

      setState(() {
        allMarker = markerList;
      });

    }

    Widget ownFlutterMap(){
      createMarker();


      return FlutterMap(
        options: MapOptions(
          center: LatLng(20.96472, -89.62173),
          zoom: 8.0,
          onPositionChanged: (position, changed){
            if(changed){
              changeProfil(position.zoom);
            }
          }
        ),
        layers: [
          TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']
          ),
          MarkerLayerOptions(
            markers: allMarker,
          ),
        ],
      );
    }

    Widget mapTextField(){
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Card(
            child: TextField(
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: "Interessen suche",
              ),
            ),
        ),
      );
    }



    return Scaffold(
        body: Stack(children: [
          ownFlutterMap(),
          mapTextField()
        ])
    );
  }
}