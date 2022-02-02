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
      hintText: "Suche",
      auswahlList: globalVar.reisearten + globalVar.interessenListe +
                   globalVar.sprachenListe,
      onConfirm: changeMapFilter(),
    );

  }

  _asyncMethod() async{
    var getProfils = await ProfilDatabaseKontroller().getAllProfils();
    ownUserProfil = getOwnProfil(getProfils);
    getProfils.remove(ownUserProfil);

    setState(() {
      originalProfils = getProfils;
      filteredProfils = getProfils;
    });

    createAndSetZoomProfils();
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
          "latt": double.parse(profil["latt"]),
          "longt": double.parse(profil["longt"]),
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
          "latt": double.parse(profil["latt"]),
          "longt": double.parse(profil["longt"]),
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

  checkMatchFilter(List selected, List profil, globalList){
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
      var newProfil = [];


      originalProfils.forEach((profil) {
        var profilInteressen = profil["interessen"];
        var profilReiseart = profil["reiseart"];
        var profilSprachen = profil["sprachen"];
        var spracheMatch = checkMatchFilter(select, profilSprachen, globalVar.sprachenListe);
        var reiseartMatch = checkMatchFilter(select, [profilReiseart], globalVar.reisearten);
        var interesseMatch = checkMatchFilter(select, profilInteressen, globalVar.interessenListe);

        if(spracheMatch && reiseartMatch && interesseMatch){
          newProfil.add(profil);
        }

      });

      setState(() {
        filteredProfils = newProfil;
        createAndSetZoomProfils();
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

  addFriendButton(profil){
    var onFriendlist = ownUserProfil["friendlist"]?.contains(profil["name"])?? false;

    return TextButton(
      style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              )
          )
      ),
      child: onFriendlist?Icon(Icons.person_remove) : Icon(Icons.person_add),
      onPressed: (){
        var friendlist = new List<String>.from(ownUserProfil["friendlist"]);

        if(onFriendlist){
          friendlist.remove(profil["name"]);
          if(friendlist.isEmpty) friendlist = ["empty"];
        } else {
          if(friendlist[0] == "empty") friendlist = [];
          friendlist.add(profil["name"]);
        }

        ProfilDatabaseKontroller().updateProfil(
            ownUserProfil["id"], {"friendlist": friendlist}
        );


        Navigator.pop(context);
        ownUserProfil["friendlist"] = friendlist;
        profilPopupWindow(context,ownUserProfil["name"], profil,
            addFriendButton: addFriendButton(profil));

      }
    );
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

        childrenAgeStringToStringAge(childrenAgeList){
          List yearChildrenAgeList = [];

          childrenAgeList.forEach((child){
            var childYears = globalFunctions.timeStampToAllDict(child)["years"];
            yearChildrenAgeList.add(childYears);
          });

          return yearChildrenAgeList.join(" , ");
        }
        List<Widget> profilsList = [];

        profils["profils"].forEach((profil){
          profilsList.add(
            GestureDetector(
              onTap: () => profilPopupWindow(context, ownUserProfil["name"],
                  profil, addFriendButton: addFriendButton(profil)
                ),
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

      createpopupContent();

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
        body: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Stack(children: [
            ownFlutterMap(),
            searchMultiForm
          ]),
        )
    );
  }
}