import 'dart:io';
import 'dart:ui';

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
  var countriesList = {};
  var filterList = [];
  var databaseProfils = [];
  var profils = [];
  var profilBetweenCountries = [];
  var profilCountries = [];
  var profilsBetween = [];
  var profilsCities = [];
  var aktiveProfils = [];
  double minMapZoom = kIsWeb ? 2.0:  1.6;
  double maxZoom = 9;
  double mapZoom = 1.6;
  double cityZoom = 6.5;
  dynamic searchAutocomplete = SizedBox.shrink();
  var mapPosition;
  bool buildLoaded = false;


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
      } else {
        allUserName.add(profil["name"]);
      }
    }

    profils.remove(ownProfil);

    countriesList = await LocationService().getAllCountries();
    var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
    var countryDropDownList = spracheIstDeutsch ? countriesList["ger"] : countriesList["eng"];

    searchAutocomplete =  SearchAutocomplete(
      searchableItems: global_var.reisearten + global_var.interessenListe +
          global_var.sprachenListe + allUserName + countryDropDownList,
      onConfirm: () => changeMapFilter(),
      onDelete:() => changeMapFilter() ,
    );

    databaseProfils = profils;
    createAndSetZoomProfils();

    buildLoaded = true;
  }


  getOwnProfil(profil){
    var userEmail = FirebaseAuth.instance.currentUser.email;

    if(profil["email"] == userEmail) {
      return profil;
    }

  }

  createProfilBetween(list, profil, abstand){
      var newPoint = false;

      for(var i = 0; i< list.length; i++){
        double originalLatt = double.parse(profil["latt"]);
        double newLatt = list[i]["latt"];
        double originalLongth = double.parse(profil["longt"]);
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
        double profilLongt = double.parse(profil["longt"]);
        double profilLatt = double.parse(profil["latt"]);

        if(profilLongt == list[i]["longt"] && profilLatt == list[i]["latt"]){
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

  createProfilBetweenCountries(list, profil) async {
    var newPoint = true;
    var abstand = 8;
    double originalLatt;
    double originalLongth;
    var landGedataProfil = await LocationService().getCountryLocation(profil["land"]);

    for(var i = 0; i< list.length; i++){
      var landGeodataList = await LocationService().getCountryLocation(list[i]["countryname"]);

      originalLatt = landGedataProfil["latt"];
      double newLatt = landGeodataList["latt"];
      originalLongth = landGedataProfil["longt"];
      double newLongth = landGeodataList["longt"];
      bool check = (newLatt + abstand/2 >= originalLatt && newLatt - abstand/2 <= originalLatt) &&
          (newLongth + abstand >= originalLongth && newLongth - abstand<= originalLongth);

      if(check || list[i]["countryname"] == profil["land"]){
        newPoint = false;
        list[i]["name"] = (int.parse(list[i]["name"]) + 1).toString();
        list[i]["profils"].add(profil);
      }
    }
    if(newPoint){
      list.add({
        "countryname": profil["land"],
        "name": "1",
        "latt": landGedataProfil["latt"],
        "longt":landGedataProfil["longt"],
        "profils": [profil]
      });
    }

    return list;
  }

  createAndSetZoomProfils() async {
    var pufferProfilCities = [];
    var pufferProfilBetween = [];
    var pufferProfilCountries = [];
    var pufferProfilBetweenCountries =[];

    for(var i= 0; i<profils.length; i++){
      pufferProfilCountries = await createProfilCountries(pufferProfilCountries,
                                                          profils[i]);
      pufferProfilBetweenCountries = await createProfilBetweenCountries(
        pufferProfilBetweenCountries, profils[i]);

      pufferProfilBetween = createProfilBetween(pufferProfilBetween, profils[i], 1);

      pufferProfilCities = createProfilCities(pufferProfilCities,
                                                     profils[i]);

    }

      profilsCities = pufferProfilCities;
      profilsBetween = pufferProfilBetween;
      profilCountries = pufferProfilCountries;
      profilBetweenCountries = pufferProfilBetweenCountries;

      changeProfil(mapZoom);


  }

  changeProfil(zoom){
    var choosenProfils = [];

    if(zoom > cityZoom){
      choosenProfils = profilsCities;
    } else if(zoom > 4.0){
      choosenProfils = profilsBetween;
    } else if (zoom > 2.5){
      choosenProfils = profilCountries;
    } else {
      choosenProfils = profilBetweenCountries;
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
    var profilLand = profil["land"];

    if(filterList.isEmpty) return true;

    var spracheMatch = checkMatch(filterList, profilSprachen,
        global_var.sprachenListe + global_var.sprachenListeEnglisch);
    var reiseartMatch = checkMatch(filterList, [profilReiseart],
        global_var.reisearten + global_var.reiseartenEnglisch);
    var interesseMatch = checkMatch(filterList, profilInteressen,
        global_var.interessenListe +global_var.interessenListeEnglisch);
    var userMatch = checkMatch(filterList, [profilName], allUserName, userSearch: true);
    var countryMatch = checkMatch(filterList, [profilLand], countriesList["ger"] + countriesList["eng"]);

    if(spracheMatch && reiseartMatch && interesseMatch && userMatch && countryMatch) return true;

    return false;
  }

  checkMatch(List selected, List checkList, globalList, {userSearch = false}){
    bool globalMatch = false;
    bool match = false;

    for (var select in selected) {
      if(globalList.contains(select)) globalMatch = true;

      if(checkList.contains(select)) match = true;

      if(userSearch) continue;

      if(globalMatch && !match){
        int halfListNumber = (globalList.length /2).toInt();
        var positionGlobal = globalList.indexOf(select);
        var calculatePosition = positionGlobal < halfListNumber ?
          positionGlobal + halfListNumber : positionGlobal - halfListNumber;
        var otherLanguage = globalList[calculatePosition];

        if(checkList.contains(otherLanguage)) match = true;
      }
    }


    if(!globalMatch) return true;
    if(match) return true;

    return false;
  }

  changeMapFilter(){
    var filterProfils = [];
    filterList = searchAutocomplete.getSelected();

    for(var profil in databaseProfils){
      if(checkFilter(profil)) filterProfils.add(profil);
    }

    setState(() {
      profils = filterProfils;
      createAndSetZoomProfils();
    });
  }

  zoomAtPoint(position){
    if(mapZoom< 4){
      mapZoom = 4.1;
    } else if (mapZoom < 6.5){
      mapZoom = 6.6;
    }

    mapPosition = position;
    mapController.move(position, mapZoom);
    setState(() {
      changeProfil(mapZoom);
    });
  }

  zoomOut(){
    var newZoom;
    if(mapZoom > 6.6){
      newZoom = 6.6;
    } else if (mapZoom > 4.1){
      newZoom = 4.1;
    } else{
      newZoom = minMapZoom;
    }


    mapController.move(mapPosition, newZoom);
    mapZoom = newZoom;
    FocusScope.of(context).unfocus();
    changeProfil(mapZoom);
  }

  @override
  Widget build(BuildContext context){
    List<Marker> allMarker = [];

    markerPopupWindow(profils){

      List<Widget> createPopupProfils(){
        List<Widget> profilsList = [SizedBox(height: 10)];

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

      if(ownProfil != null) {
        markerList.add(
            Marker(
              width: 30.0,
              height: 30.0,
              point: LatLng(double.parse(ownProfil["latt"])+0.07, double.parse(ownProfil["longt"])+0.02),
              builder: (ctx) => FloatingActionButton(
                backgroundColor: Colors.transparent,
                mini: true,
                child: Icon(Icons.flag ,color: Colors.green[900], size: 30,),
                onPressed: null,
              ),
            )
        );
      }

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
          center: LatLng(25, 0),
          zoom: minMapZoom,
          minZoom: minMapZoom,
          maxZoom: maxZoom,
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          onPositionChanged: (position, changed){
            if(buildLoaded){
              mapPosition = position.center;
              mapZoom = position.zoom;
              FocusScope.of(context).unfocus();
              changeProfil(mapZoom);
            }

          },
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
              onPressed: () => zoomOut()
          ),
        )
      ]),
    );

  }
}