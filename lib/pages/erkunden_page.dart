import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../database.dart';
import '../custom_widgets.dart';
import '../pages/setting_page/locationsService.dart';


class ErkundenPage extends StatefulWidget{
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  var originalProfils = [];
  var filteredProfils = [];
  var profilCountries = [];
  var profilsBetween = [];
  var profilsCities = [];
  var aktiveProfils = [];
  double mapZoom = 3.0;


  void initState (){
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_){
      _asyncMethod();
    });

  }

  _asyncMethod() async{
    var getProfils = await dbGetAllProfils();
    setState(() {
      originalProfils = getProfils;
      filteredProfils = getProfils;
    });
  }


  Widget build(BuildContext context){
    List<Marker> allMarker = [];
    var searchMultiForm = CustomMultiTextForm(allSelected: true,auswahlList: []);

    createProfilBetween(){
      var newProfils = [];

      profilsCities.forEach((originalProfil) {
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
      return newProfils;
    }

    createProfilCities(){
      var newProfils = [];

      filteredProfils.forEach((originalProfil) {
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

    createProfilCountries() async {
      var newProfil = [];

      for (var j= 0; j<filteredProfils.length; j++){
        var checkNewCountry = true;

        for (var i = 0; i<newProfil.length; i++){
          if(newProfil[i]["countryname"] == filteredProfils[j]["land"]){
            checkNewCountry = false;
            newProfil[i]["name"] =(int.parse(newProfil[i]["name"]) + 1).toString();
          }
        }

        if(checkNewCountry){
          var country = filteredProfils[j]["land"];
          var position = await LocationService().getCountryLocation(country);
          newProfil.add({
            "name": "1",
            "countryname": country,
            "longt": position["longt"],
            "latt": position["latt"]
          });
        }

      }

      return newProfil;
    }

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
      } else if(zoom! > 4.0){
        choosenProfils = profilsBetween;
      } else{
        choosenProfils = profilCountries;
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
          center: LatLng(42.5, 1.5),
          zoom: 3.0,
          onPositionChanged: (position, changed){
            if(changed){
              changeProfil(position.zoom);
              mapZoom = position.zoom!;
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

    createAndSetZoomProfils() async {
      var pufferProfil = await createProfilCountries();

      setState(() {
        profilsCities = createProfilCities();
        profilsBetween = createProfilBetween();
        profilCountries = pufferProfil;
        changeProfil(mapZoom);
      });

    }

    changeMapFilter(select){
      var newProfil = [];


      originalProfils.forEach((profil) {
        var profilInteressen = profil["interessen"];
        var interessenMatch = false;

        select.forEach((selectInteresse){
          profilInteressen.forEach((profilInteresse){
            if(selectInteresse == profilInteresse){
              interessenMatch = true;
            }
          });
        });

        if(interessenMatch){
          newProfil.add(profil);
        }

      });

      setState(() {
        filteredProfils = newProfil;
        createAndSetZoomProfils();
      });

      print(newProfil.length);

    }




    createAndSetZoomProfils();

    searchMultiForm.confirmFunction = (select){
      changeMapFilter(select);
    };

    return Scaffold(
        body: Stack(children: [
          ownFlutterMap(),
          searchMultiForm
        ])
    );
  }
}