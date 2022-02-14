import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/database.dart';
import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_var;
import '../windows/profil_popup_window.dart';
import '../services/locationsService.dart';


class ErkundenPage extends StatefulWidget{
  @override
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  var userProfil;
  var filterList = [];
  var profils = [];
  var profilCountries = [];
  var profilsBetween = [];
  var profilsCities = [];
  var aktiveProfils = [];
  double mapZoom = 3.0;
  double cityZoom = 6.5;
  var searchMultiForm;
  var buildIsLoaded = false;

  @override
  void initState (){
    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback((_){
      buildIsLoaded = true;
    });



    searchMultiForm = CustomMultiTextForm(
      hintText: "Suche",
      auswahlList: global_var.reisearten + global_var.interessenListe +
          global_var.sprachenListe,
      onConfirm: changeMapFilter(),
    );

  }

  getOwnProfil(profils){
    var userEmail = FirebaseAuth.instance.currentUser!.email;

    for(var profil in profils){
      if(profil["email"] == userEmail) return profil;
    }

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
      }

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
        if(profil["ort"] == list[i]["ort"] &&
            profil["longt"] == list[i]["longt"] &&
            profil["latt"] == list[i]["latt"]){
          newCity = true;
          list[i]["name"] = (int.parse(list[i]["name"]) + 1).toString();
          list[i]["profils"].add(profil);
        }
      }

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
          list[i]["name"] = (int.parse(list[i]["name"]) + 1).toString();
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

    if(zoom! > cityZoom){
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

    var spracheMatch = checkMatch(filterList, profilSprachen, global_var.sprachenListe);
    var reiseartMatch = checkMatch(filterList, [profilReiseart], global_var.reisearten);
    var interesseMatch = checkMatch(filterList, profilInteressen, global_var.interessenListe);

    if(spracheMatch && reiseartMatch && interesseMatch) return true;

    return false;
  }

  checkMatch(List selected, List checkList, globalList){
    bool globalMatch = false;
    bool match = false;

    for (var select in selected) {
      if(globalList.contains(select)) globalMatch = true;

      if(checkList.contains(select)) match = true;
    }


    if(!globalMatch) return true;
    if(match) return true;

    return false;
  }

  changeMapFilter(){
    return (select){
      setState(() {
        filterList = select;
      });
    };

  }

  @override
  Widget build(BuildContext context){
    List<Marker> allMarker = [];

    markerPopupWindow(profils){

      List<Widget> createPopupProfils(){
        List<Widget> profilsList = [];

        childrenAgeStringToStringAge(childrenAgeList){
          List yearChildrenAgeList = [];

          childrenAgeList.forEach((child){
            var childYears = global_functions.ChangeTimeStamp(child).intoYears();
            yearChildrenAgeList.add(childYears.toString() + "J");
          });

          return yearChildrenAgeList.join(" , ");
        }


        profils["profils"].forEach((profil){
          profilsList.add(
            GestureDetector(
              onTap: () => ProfilPopupWindow(
                    context: context,
                    userName: userProfil["name"],
                    profil: profil,
                    userFriendlist: userProfil["friendlist"],
                ).profilPopupWindow(),
              child: Container(
                width: 50,
                margin: const EdgeInsets.only(top: 10, bottom: 10, right: 25, left: 25),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(width: 1),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                ),
                child: Text(
                    profil["name"] + " - Kinder: " +
                        childrenAgeStringToStringAge(profil["kinder"]),
                    style: const TextStyle(fontSize: 16),
                )
              ),
            )
          );
        });
        return profilsList;
      }


      return CustomWindow(
          context: context,
          title: mapZoom > cityZoom ? profils["profils"][0]["ort"] :
                 profils["profils"][0]["land"],
          children: createPopupProfils());

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
      for (var profil in aktiveProfils) {
        var position = LatLng(profil["latt"], profil["longt"]);
        markerList.add(
            ownMarker(profil["name"], position, () => markerPopupWindow(profil))
        );
      }

      allMarker = markerList;

    }

    ownFlutterMap(){
      createAllMarker();

      return FlutterMap(
        options: MapOptions(
          center: LatLng(0, 0),
          zoom: 1.6,
          minZoom: 1.6,
          maxZoom: 9,
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

              userProfil = getOwnProfil(allProfils);
              allProfils.remove(userProfil);

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