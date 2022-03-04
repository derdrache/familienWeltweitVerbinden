import 'dart:convert';

import 'package:familien_suche/pages/show_profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/database.dart';
import '../global/custom_widgets.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_var;
import '../global/search_autocomplete.dart';
import '../services/locationsService.dart';


class ErkundenPage extends StatefulWidget{
  @override
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  MapController mapController = MapController();
  var ownProfil;
  List<String> allUserName = [];
  var filterList = [];
  var profils = [];
  var profilCountries = [];
  var profilsBetween = [];
  var profilsCities = [];
  var aktiveProfils = [];
  double minMapZoom = 1.6;
  double mapZoom = 1.6;
  double cityZoom = 6.5;
  dynamic searchAutocomplete = SizedBox.shrink();


  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod() );

    super.initState();
  }

  _asyncMethod() async{
    profils = await ProfilDatabase().getAllProfils();

    allUserName = [];

    for(var profil in profils){

      if(getOwnProfil(profil) != null){
        ownProfil = getOwnProfil(profil);
        //allUserName.remove(ownProfil);
      } else {
        allUserName.add(profil["name"]);
      }
    }

    searchAutocomplete =  SearchAutocomplete(
      searchableItems: global_var.reisearten + global_var.interessenListe +
          global_var.sprachenListe + allUserName,
      onConfirm: () => changeMapFilter(),
      onDelete:() => changeMapFilter() ,
    );

    createAndSetZoomProfils();
  }


  getOwnProfil(profil){
    var userEmail = FirebaseAuth.instance.currentUser.email;

    if(profil["email"] == userEmail) {
      return profil;
    }

  }

  createProfilBetween(list, profil){
      var newPoint = false;
      var abstand = 1.5;

      for(var i = 0; i< list.length; i++){
        double originalLatt =  profil["latt"];
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
        if(profil["longt"] == list[i]["longt"] && profil["latt"] == list[i]["latt"]){
          newCity = true;
          list[i]["name"] = (int.parse(list[i]["name"]) + 1).toString();
          list[i]["profils"].add(profil);
        }
      }

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
        var listCountryLocation = await LocationService().getCountryLocation(list[i]["countryname"]);
        var profilCountryLocation = await LocationService().getCountryLocation(profil["land"]);

        if(listCountryLocation["latt"] == profilCountryLocation["latt"] &&
            listCountryLocation["longt"] == profilCountryLocation["longt"] ){
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
          "longt": position["longt"]?? 0,
          "latt": position["latt"] ?? 0,
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


  }

  changeProfil(zoom){
    var choosenProfils = [];

    if(zoom > cityZoom){
      choosenProfils = profilsCities;
    } else if(zoom > 4.0){
      choosenProfils = profilsBetween;
    } else{
      choosenProfils = profilCountries;
    }


    setState(() {
      aktiveProfils = choosenProfils;
    });
  }

  checkFilter(profil){
    var profilInteressen = profil["interessen"];
    var profilReiseart = profil["reiseart"];
    var profilSprachen = profil["sprachen"];
    var profilName = profil["name"];

    if(filterList.isEmpty) return true;

    var spracheMatch = checkMatch(filterList, profilSprachen, global_var.sprachenListe);
    var reiseartMatch = checkMatch(filterList, [profilReiseart], global_var.reisearten);
    var interesseMatch = checkMatch(filterList, profilInteressen, global_var.interessenListe);
    var userMatch = checkMatch(filterList, [profilName], allUserName);
    if(spracheMatch && reiseartMatch && interesseMatch && userMatch) return true;

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
    var filterProfils = [];
    for(var profil in profils){
      if(checkFilter(profil)) filterProfils.add(profil);
    }

    setState(() {
      filterList = searchAutocomplete.getSelected();
      profils = filterProfils;
    });
  }

  zoomAtPoint(position){
    if(mapZoom< 4){
      mapZoom = 4.1;
    } else if (mapZoom < 6.5){
      mapZoom = 6.6;
    }

    mapController.move(position, mapZoom);
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context){
    List<Marker> allMarker = [];

    markerPopupWindow(profils){

      List<Widget> createPopupProfils(){
        List<Widget> profilsList = [SizedBox(height: 10)];
        var friendlist = ownProfil["friendlist"] ?? [];

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
              onTap: () {
                global_functions.changePage(context, ShowProfilPage(
                  userName: ownProfil["name"],
                  profil: profil,
                  userFriendlist: friendlist,
                ));
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(width: 1, color: global_var.borderColorGrey))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profil["name"], style: TextStyle(fontWeight: FontWeight.bold),),
                    Text(AppLocalizations.of(context).kinder +" :" + childrenAgeStringToStringAge(profil["kinder"]))
                  ]
                )
              ),
            )
          );
        });
        return profilsList;
      }

      createWindowTitle(list, filter){
        var titleList = [];

        for(var item in list){
          if(!titleList.contains(item[filter])) titleList.add(item[filter]);
        }

        return titleList.join(" / ");

      }


      return CustomWindow(
          context: context,
          title: mapZoom > cityZoom ? createWindowTitle(profils["profils"], "ort") :
              createWindowTitle(profils["profils"], "land"),
          children: createPopupProfils());

    }

    Marker ownMarker(text, position,  buttonFunction){
      return Marker(
        width: 30.0,
        height: 30.0,
        point: position,
        builder: (ctx) => FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          mini: true,
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
            ownMarker(
                profil["name"],
                position,
                () {
                  markerPopupWindow(profil);
                  zoomAtPoint(position);
                }
            )

        );
      }

      allMarker = markerList;

    }

    ownFlutterMap(){
      createAllMarker();

      return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: LatLng(0, 0),
          zoom: minMapZoom,
          minZoom: minMapZoom,
          maxZoom: 9,
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          onPositionChanged: (position, changed){
            if(changed){
                setState(() {
                  changeProfil(position.zoom);
                  mapZoom = position.zoom;
                  FocusScope.of(context).unfocus();
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


    return Padding(
                padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
                child: Stack(children: [
                  ownFlutterMap(),
                  searchAutocomplete,
                  if(mapZoom > minMapZoom) Positioned(
                    bottom: 10,
                    right: 10,
                    child: FloatingActionButton(
                      child: Icon(Icons.zoom_out_map),
                      onPressed: () {
                        mapController.move(LatLng(0, 0), minMapZoom);
                        setState(() {
                          changeProfil(minMapZoom);
                          mapZoom = minMapZoom;
                          FocusScope.of(context).unfocus();
                        });

                      }
                    ),
                  )
                ]),
              );

  }
}