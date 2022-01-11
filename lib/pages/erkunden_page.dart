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
  var searchMultiForm;


  void initState (){
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_){
      _asyncMethod();
    });

    searchMultiForm = CustomMultiTextForm(
      allSelected: true,
      auswahlList: [],
      confirmFunction: changeMapFilter(),
    );

  }

  _asyncMethod() async{
    var getProfils = await dbGetAllProfils();
    setState(() {
      originalProfils = getProfils;
      filteredProfils = getProfils;
    });

    createAndSetZoomProfils();
  }

  createProfilBetween(){
    var newProfils = [];

    filteredProfils.forEach((originalProfil) {
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
          newProfils[i]["name"] = (int.parse(newProfils[i]["name"]) + 1).toString();
          newProfils[i]["profils"].add(originalProfil);
        }
      };

      if(!newPoint){
        newProfils.add({
          "ort": originalProfil["ort"],
          "name": "1",
          "latt": originalProfil["latt"],
          "longt": originalProfil["longt"],
          "profils": [originalProfil]
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
          newProfils[i]["profils"].add(originalProfil);
        }
      };

      if(!newCity){
        newProfils.add({
          "ort": originalProfil["ort"],
          "name": "1",
          "latt": originalProfil["latt"],
          "longt": originalProfil["longt"],
          "profils": [originalProfil]
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
          newProfil[i]["profils"].add(filteredProfils[j]);
        }
      }

      if(checkNewCountry){
        var country = filteredProfils[j]["land"];
        var position = await LocationService().getCountryLocation(country);
        newProfil.add({
          "name": "1",
          "countryname": country,
          "longt": position["longt"],
          "latt": position["latt"],
          "profils": [filteredProfils[j]]
        });
      }

    }

    return newProfil;
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

  changeMapFilter(){
    return (select){
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
    };
    /*


       */

  }


  Widget build(BuildContext context){
    List<Marker> allMarker = [];

    markerPopupWindow(profils){
      List<Widget> popupItems = [];

      createPopupTitle(){
        return Center(
            child: Text(
              profils["profils"][0]["land"],
              style: TextStyle(fontSize: 20),
            )
        );
      }

      List<Widget> createPopupProfils(){

        childrenAgeStringToStringAge(childrenAgeList){
          String stringAge = "";
          List yearChildrenAgeList = [];

          childrenAgeList.forEach((child){
            var childTimeStampToDateTime = DateTime.parse(child.toDate().toString());
            var childYears = DateTime.now().difference(childTimeStampToDateTime).inDays ~/ 365;

            yearChildrenAgeList.add(childYears);

          });


          return yearChildrenAgeList.join(" , ");
        }
        List<Widget> profilsList = [];

        profils["profils"].forEach((profil){
          profilsList.add(
            GestureDetector(
              onTap: () => print("Show Profil"),
              child: Container(
                width: 50,
                margin: EdgeInsets.only(top: 10, bottom: 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(20))
                ),
                child: Text(
                    profil["name"] + " - Kinder: " +
                        childrenAgeStringToStringAge(profil["kinder"]),
                    style: TextStyle(fontSize: 16),
                )
              ),
            )
          );
        });
        return profilsList;
      }


      popupItems.add(createPopupTitle());
      popupItems.add(SizedBox(height: 20));
      popupItems = popupItems + createPopupProfils();

      return showDialog(
            context: context,
            builder: (BuildContext context){
              return AlertDialog(
                content: Container(
                  height: 400,
                  width: double.maxFinite,
                  child: Scrollbar(
                    isAlwaysShown: true,
                    child: ListView(
                      children: popupItems
                    ),
                  ),
                ),
              );
            }
        );
        //jede Familie aufgelistet => möglichkeit das Profil zu sehen => pagechange

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

    createAllMarker() async{
      List<Marker> markerList = [];
      aktiveProfils.forEach((profil){
        var position = LatLng(profil["latt"], profil["longt"]);
        markerList.add(
            ownMarker(profil["name"], position, () => markerPopupWindow(profil))
        );
      });

      setState(() {
        allMarker = markerList;
      });

    }

    Widget ownFlutterMap(){
      createAllMarker();


      return FlutterMap(
        options: MapOptions(
          center: LatLng(21.1454686, -88.1496087),
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

    return Scaffold(
        body: Stack(children: [
          ownFlutterMap(),
          searchMultiForm
        ])
    );
  }
}