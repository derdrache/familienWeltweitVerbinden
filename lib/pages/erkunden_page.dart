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

  createProfilBetween(list, profil){
      var newPoint = false;
      var abstand = 1.5;

      for(var i = 0; i< list.length; i++){
        double originalLatt = profil["latt"];
        double newLatt = list[i]["latt"];
        double originalLongth = profil["longt"];
        double newLongth = list[i]["longt"];
        bool check = (newLatt + abstand >= originalLatt && newLatt - abstand <= originalLatt) &&
            (newLongth + abstand >= originalLongth && newLongth - abstand<= originalLongth);

        if(check){
          newPoint = true;
          list[i]["name"] = (int.parse(list[i]["name"]) + 1).toString();
          list[i]["profils"].add(profil);
        }
      };

      if(!newPoint){
        list.add({
          "ort": profil["ort"],
          "name": "1",
          "latt": profil["latt"],
          "longt": profil["longt"],
          "profils": [profil]
        });
      }

    return list;
  }

  createProfilCities(list, profil){
      var newCity = false;

      for(var i = 0; i< list.length; i++){
        if(profil["ort"] == list[i]["ort"]){
          newCity = true;
          list[i]["name"] = (int.parse(list[i]["name"]) + 1).toString();
          list[i]["profils"].add(profil);
        }
      };

      if(!newCity){
        list.add({
          "ort": profil["ort"],
          "name": "1",
          "latt": profil["latt"],
          "longt": profil["longt"],
          "profils": [profil]
        });
      }

    return list;
  }

  createProfilCountries(list, profil) async {
      var checkNewCountry = true;

      for (var i = 0; i<list.length; i++){
        if(list[i]["countryname"] == profil["land"]){
          checkNewCountry = false;
          list[i]["name"] =(int.parse(list[i]["name"]) + 1).toString();
          list[i]["profils"].add(profil);
        }
      }

      if(checkNewCountry){
        var country = profil["land"];
        var position = await LocationService().getCountryLocation(country);
        list.add({
          "name": "1",
          "countryname": country,
          "longt": position["longt"],
          "latt": position["latt"],
          "profils": [profil]
        });
      }

    return list;
  }

  createAndSetZoomProfils() async {
    var pufferProfilCities = [];
    var pufferProfilBetween = [];
    var pufferProfilCountries = [];

    for(var i= 0; i<filteredProfils.length; i++){
      pufferProfilCountries = await createProfilCountries(pufferProfilCountries,
                                                          filteredProfils[i]);
      pufferProfilBetween = await createProfilBetween(pufferProfilBetween,
                                                       filteredProfils[i]);

      pufferProfilCities = await createProfilCities(pufferProfilCities,
                                                     filteredProfils[i]);

    }

    setState(() {
      profilsCities = pufferProfilCities;
      profilsBetween = pufferProfilBetween;
      profilCountries = pufferProfilCountries;
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