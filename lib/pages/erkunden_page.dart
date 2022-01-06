import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../database.dart';


class ErkundenPage extends StatefulWidget{
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  var originalProfils = [];
  var profilsZoom1 = []; // Landebene?
  var profilsZoom2 = []; //mehrere Städe verbinden
  var profilsZoom3 = []; //Stadtebene
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
      aktiveProfils = getProfils;
      createAndSetZoomProfils();
    });
  }

  createAndSetZoomProfils(){
    setState(() {
      // 1
      // 2
      profilsZoom3 = createZoomProfil3();
    });

  }

  createZoomProfil3(){
    var newProfils = [];

    originalProfils.forEach((originalProfil) {
      var newCity = false;

      for(var i = 0; i< newProfils.length; i++){
        if(originalProfil["ort"] == newProfils[i]["ort"]){
          newCity = true;
          newProfils[i]["count"] += 1;
        }
      };

      if(!newCity){
        newProfils.add({
          "ort": originalProfil["ort"],
          "count": 1
        });
      }
    });

    return newProfils;
  }


  Widget build(BuildContext context){
    List<Marker> allMarker = [];
    double? zoom = 0.0;


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

    changeProfil( zoom){
      var choosenProfils = [];
      if(zoom! > 5){
        choosenProfils = profilsZoom1;
      } else if(zoom! > 4){
        choosenProfils = profilsZoom2;
      } else if(zoom! > 3){
        choosenProfils = profilsZoom3;
      }

      setState(() {
        aktiveProfils = choosenProfils;
      });
    }

    createMarker() async{
      List<Marker> markerList = [];
      aktiveProfils.forEach((profil){
        var position = LatLng(double.parse(profil["latt"]), double.parse(profil["longt"]));
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
          center: LatLng(51.5, -0.09),
          zoom: 0.7,
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