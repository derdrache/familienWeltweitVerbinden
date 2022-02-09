import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/database.dart';
import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as globalFunctions;
import '../global/variablen.dart' as globalVar;
import '../windows/profil_popup_window.dart';
import '../services/locationsService.dart';


class ErkundenPage extends StatefulWidget{
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  var ownUserProfil;
  var filterList = [];
  var profils = [];
  var profilCountries = [];
  var profilsBetween = [];
  var profilsCities = [];
  var aktiveProfils = [];
  double mapZoom = 3.0;
  var searchMultiForm;
  var buildIsLoaded = false;


  void initState (){
    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback((_){
      buildIsLoaded = true;
    });



    searchMultiForm = CustomMultiTextForm(
      hintText: "Suche",
      auswahlList: globalVar.reisearten + globalVar.interessenListe +
                   globalVar.sprachenListe,
      onConfirm: changeMapFilter(),
    );

  }

  getOwnProfil(profils){
    var userEmail = FirebaseAuth.instance.currentUser!.email;

    for(var profil in profils){
      if(profil["email"] == userEmail){
        return profil;
      }
    }

    return null;

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

    for(var i= 0; i<profils.length; i++){
      pufferProfilCountries = await createProfilCountries(pufferProfilCountries,
                                                          profils[i]);
      pufferProfilBetween = await createProfilBetween(pufferProfilBetween,
                                                       profils[i]);

      pufferProfilCities = await createProfilCities(pufferProfilCities,
                                                     profils[i]);

    }

      profilsCities = pufferProfilCities;
      profilsBetween = pufferProfilBetween;
      profilCountries = pufferProfilCountries;
      changeProfil(mapZoom);

      if(buildIsLoaded){
        buildIsLoaded = false;
        setState(() {});
      }

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

    aktiveProfils = choosenProfils;
  }

  checkFilter(profil){
    var profilInteressen = profil["interessen"];
    var profilReiseart = profil["reiseart"];
    var profilSprachen = profil["sprachen"];

    var spracheMatch = checkMatch(filterList, profilSprachen, globalVar.sprachenListe);
    var reiseartMatch = checkMatch(filterList, [profilReiseart], globalVar.reisearten);
    var interesseMatch = checkMatch(filterList, profilInteressen, globalVar.interessenListe);

    if(spracheMatch && reiseartMatch && interesseMatch){
      return true;
    }

    return false;
  }

  checkMatch(List selected, List profil, globalList){
    bool globalMatch = false;
    bool match = false;


    for (var select in selected) {
      if(globalList.contains(select)){
        globalMatch = true;
      }

      if(profil.contains(select)){
        match = true;
      }

    }

    if(!globalMatch){
      return true;
    } else {
      if(match){
        return true;
      } else{
        return false;
      }
    }

  }



  changeMapFilter(){
    return (select){
      setState(() {
        filterList = select;
      });
    };

  }

  checkOnFriendlist(friendlist, email){
    for(var friend in friendlist){
      if (friend["email"] == email){
        return true;
      }
    }
    return false;
  }


  Widget build(BuildContext context){
    List<Marker> allMarker = [];

    markerPopupWindow(profils){

      createPopupTitle(){
        return Center(
            child: Text(
              profils["profils"][0]["land"],
              style: TextStyle(fontSize: 20),
            )
        );
      }

      List<Widget> createPopupProfils(){
        List<Widget> profilsList = [];

        childrenAgeStringToStringAge(childrenAgeList){
          List yearChildrenAgeList = [];

          childrenAgeList.forEach((child){
            var childYears = globalFunctions.ChangeTimeStamp(child).intoYears();
            yearChildrenAgeList.add(childYears.toString() + "J");
          });


          return yearChildrenAgeList.join(" , ");
        }



        profils["profils"].forEach((profil){
          profilsList.add(
            GestureDetector(
              onTap: () => ProfilPopupWindow(
                    context: context,
                    userName: ownUserProfil["name"],
                    profil: profil,
                    userFriendlist: ownUserProfil["friendlist"],
                ).profilPopupWindow(),
              child: Container(
                width: 50,
                margin: EdgeInsets.all(10),
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

      createpopupContent(){
        List<Widget> popupItems = [];

        popupItems.add(Row(
            children: [
              TextButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          )
                      )
                  ),
                  child: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop()
              ),
              SizedBox(width: 50),
              createPopupTitle()
            ]
        ));
        popupItems.add(SizedBox(height: 20));
        popupItems = popupItems + createPopupProfils();

        return popupItems;
      }

      return showDialog(
            context: context,
            builder: (BuildContext context){
              return AlertDialog(
                contentPadding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                content: Container(
                  height: 400,
                  width: double.maxFinite,
                  child: Scrollbar(
                    isAlwaysShown: true,
                    child: ListView(
                      children: createpopupContent()
                    ),
                  ),
                ),
              );
            }
        );
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

      allMarker = markerList;

    }

    ownFlutterMap(){
      createAllMarker();


      return FlutterMap(
        options: MapOptions(
          center: LatLng(0, 0),
          zoom: 1.5,
          onPositionChanged: (position, changed){
            if(changed){
                setState(() {
                  changeProfil(position.zoom);
                  mapZoom = position.zoom!;
                });
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
      body: Padding(
        padding: const EdgeInsets.only(top: 25),
        child:StreamBuilder(
          stream: ProfilDatabase().getAllProfilsStream(),
          builder: (
              BuildContext context,
              AsyncSnapshot snapshot,
          ) {
            if (snapshot.hasData ) {
              var allProfils = [];
              var allProfilsMap = Map<String, dynamic>.from(snapshot.data.snapshot.value);

              allProfilsMap.forEach((key, value) {
                if(checkFilter(value)){
                  allProfils.add(value);
                }
              });

              ownUserProfil = getOwnProfil(allProfils);
              allProfils.remove(ownUserProfil);

              profils = allProfils;

              createAndSetZoomProfils();

              return Stack(children: [
                ownFlutterMap(),
                searchMultiForm
              ]);
            }
            return Container();
          }
        )
      )
    );

  }
}