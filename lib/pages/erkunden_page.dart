import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/pages/events/eventCard.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/database.dart';
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
  List profilsBackup = [], profils = [], aktiveProfils = [];
  List profilBetweenCountries, profilCountries, profilsBetween, profilsCities;
  List eventsBetweenCountries, eventsCountries, eventsBetween, eventsCities;
  List eventsBackup = [], events = [], aktiveEvents = [];
  double minMapZoom = kIsWeb ? 2.0:  1.6;
  double maxZoom = 9;
  double mapZoom = 1.6;
  double cityZoom = 6.5;
  dynamic searchAutocomplete = const SizedBox.shrink();
  var mapPosition;
  bool buildLoaded = false;
  bool popupActive = false;
  List<Widget> popupItems = [];
  var lastEventPopup;


  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod() );

    super.initState();
  }

  _asyncMethod() async{
    await getAndSetProfils();
    setSearchAutocomplete();
    getAndSetEvents();

    buildLoaded = true;
  }

  getAndSetProfils()async{
    profils = await ProfilDatabase().getAllProfils();

    for(var profil in profils){
      if(getOwnProfil(profil) != null){
        ownProfil = getOwnProfil(profil);
      } else {
        allUserName.add(profil["name"]);
      }
    }

    profils.remove(ownProfil);

    profilsBackup = profils;
    createAndSetZoomProfils();
  }

  setSearchAutocomplete() async {
    countriesList = await LocationService().getAllCountries();
    var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
    var countryDropDownList = spracheIstDeutsch ? countriesList["ger"] : countriesList["eng"];

    searchAutocomplete =  SearchAutocomplete(
      searchableItems: global_var.reisearten + global_var.interessenListe +
          global_var.sprachenListe + allUserName + countryDropDownList,
      onConfirm: () => changeMapFilter(),
      onDelete:() => changeMapFilter() ,
    );
  }

  getAndSetEvents()async{
    events = await EventDatabase().getEvents("art != 'privat' AND art != 'private'");
    eventsBackup = events;
    createAndSetZoomEvents();
  }


  getOwnProfil(profil){
    var userEmail = FirebaseAuth.instance.currentUser.email;

    if(profil["email"] == userEmail) {
      return profil;
    }

  }

  createBetween(list, profil, abstand){
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

  createCities(list, profil){
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

  createCountries(list, profil) async {
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

  createBetweenCountries(list, profil) async {
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
      pufferProfilCountries = await createCountries(pufferProfilCountries,
                                                          profils[i]);
      pufferProfilBetweenCountries = await createBetweenCountries(
        pufferProfilBetweenCountries, profils[i]);

      pufferProfilBetween = createBetween(pufferProfilBetween, profils[i], 1);

      pufferProfilCities = createCities(pufferProfilCities,
                                                     profils[i]);

    }

      profilsCities = pufferProfilCities;
      profilsBetween = pufferProfilBetween;
      profilCountries = pufferProfilCountries;
      profilBetweenCountries = pufferProfilBetweenCountries;

      changeProfil(mapZoom);
  }

  createAndSetZoomEvents() async {
    var pufferEventsCities = [];
    var pufferEventsBetween = [];
    var pufferEventsCountries = [];
    var pufferEventsBetweenCountries =[];

    for(var i= 0; i<events.length; i++){
      pufferEventsCountries = await createCountries(pufferEventsCountries,
          events[i]);
      pufferEventsBetweenCountries = await createBetweenCountries(
          pufferEventsBetweenCountries, events[i]);

      pufferEventsBetween = createBetween(pufferEventsBetween, events[i], 1);

      pufferEventsCities = createCities(pufferEventsCities,
          events[i]);

    }

    eventsCities = pufferEventsCities;
    eventsBetween = pufferEventsBetween;
    eventsCountries = pufferEventsCountries;
    eventsBetweenCountries = pufferEventsBetweenCountries;

    changeProfil(mapZoom);
  }

  changeProfil(zoom){
    var choosenProfils = [];
    var selectedEventList = [];

    if(zoom > cityZoom){
      choosenProfils = profilsCities;
      selectedEventList = eventsCities;
    } else if(zoom > 4.0){
      choosenProfils = profilsBetween;
      selectedEventList = eventsBetween;
    } else if (zoom > 2.5){
      choosenProfils = profilCountries;
      selectedEventList = eventsCountries;
    } else {
      choosenProfils = profilBetweenCountries;
      selectedEventList = eventsBetweenCountries;
    }


    setState(() {
      aktiveProfils = choosenProfils ?? [];
      aktiveEvents = selectedEventList ?? [];
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

    for(var profil in profilsBackup){
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

    changeProfil(mapZoom);
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

    createPopupWindowTitle(list, filter){
      var titleList = [];

      for(var item in list){
        if(!titleList.contains(item[filter])) titleList.add(item[filter]);
      }

      return titleList.join(" / ");
    }

    createPopupProfils(profil){
      popupItems = [];

      childrenAgeStringToStringAge(childrenAgeList){
        List yearChildrenAgeList = [];
        childrenAgeList.forEach((child){
          var childYears = global_functions.ChangeTimeStamp(child).intoYears();
          yearChildrenAgeList.add(childYears.toString() + "J");
        });

        return yearChildrenAgeList.join(" , ");
      }

      popupItems.add(
          Container(
            padding: EdgeInsets.only(top: 5, bottom: 5),
            alignment: Alignment.center,
            child: Text(
                mapZoom > cityZoom ? createPopupWindowTitle(profil["profils"], "ort") :
                createPopupWindowTitle(profil["profils"], "land"),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            )
          )
      );



      profil["profils"].forEach((profil){
        popupItems.add(
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
                      border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profil["name"], style: const TextStyle(fontWeight: FontWeight.bold),),
                        Text(AppLocalizations.of(context).kinder +" :" + childrenAgeStringToStringAge(profil["kinder"]))
                      ]
                  )
              ),
            )
        );
      });
    }

    createPopupEvents(event){
      popupItems = [];


      popupItems.add(
          Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(top: 5, bottom: 5),
              child: Text(
                  mapZoom > cityZoom ? createPopupWindowTitle(event["profils"], "stadt") :
                  createPopupWindowTitle(event["profils"], "land"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              )
          )
      );


      for(var event in event["profils"]){
        popupItems.add(
            EventCard(
              margin: EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
              event: event,
              withInteresse: true,
              afterPageVisit: () async {
                events = await EventDatabase().getEvents("art != 'privat' AND art != 'private'");
                var refreshEvents = [];

                for(var oldEvent in lastEventPopup["profils"]){
                  for(var newEvents in events){
                    if(oldEvent["id"] == newEvents["id"]){
                      refreshEvents.add(newEvents);
                    }
                  }
                }

                lastEventPopup["profils"] = refreshEvents;
                createPopupEvents(lastEventPopup);
                setState(() {

                });

              }
            )
        );
      }

      popupItems = [Wrap(spacing: 10, alignment: WrapAlignment.center, children: popupItems)];
      // kann geändert werden wenn Profils auch Karten sind
    }

    Marker profilMarker(numberText, position,  buttonFunction){
      return Marker(
        width: 30.0,
        height: 30.0,
        point: position,
        builder: (ctx) => FloatingActionButton(
          heroTag: "MapMarker" + position.toString(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          mini: true,
          child: Text(numberText),
          onPressed: buttonFunction,
        ),
      );
    }

    Marker eventMarker(numberText, position,  buttonFunction){

      return Marker(
        width: 32.0,
        height: 32.0,
        point: position,
        builder: (ctx) => IconButton(
          padding: EdgeInsets.zero,
          icon: Stack(
            children: [
              Icon(Icons.calendar_today, size: 32, color: Theme.of(context).colorScheme.primary),
              Positioned(
                top:9.5,
                left:5.5,
                child: Container(
                  padding: const EdgeInsets.only( left:2, top: 1),
                  width: 21.5,
                  height: 18,
                  color: Colors.white,
                    child: Center(child: Text(numberText, style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14, color: Colors.black)))
                )
              )
            ],
          ),
          onPressed: buttonFunction,
        ),
      );
    }

    markerPopupContainer(){
      return Positioned.fill(
          child: DraggableScrollableSheet(
            snap: true,
            initialChildSize: 0.4,
            minChildSize: 0.25,
            maxChildSize: 0.6,
              builder: (context, controller){
                return Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top:60),
                      child: ClipRRect(
                       borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                       child: Container(
                           color: Colors.white,
                           child: ScrollConfiguration(
                             behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                               PointerDeviceKind.touch,
                               PointerDeviceKind.mouse,
                             }),
                             child: ListView(
                               padding: const EdgeInsets.only(top:5),
                               controller: controller,
                               children: popupItems
                             ),
                           ),
                       ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 55,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red,),
                        onPressed: (){
                          setState(() {
                            popupActive = false;
                          });
                        },
                      ),
                    ),
                    if(mapZoom > minMapZoom) Positioned(
                      top: 0,
                      right: 0,
                      child: FloatingActionButton(
                          heroTag: "zoom out",
                          child: const Icon(Icons.zoom_out_map),
                          onPressed: () => zoomOut()
                      ),
                    ),
                  ],
                );
              }
          )
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
                heroTag: "ownMarker",
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
            profilMarker(
                profil["name"],
                position,
                () {
                  popupActive = true;
                  createPopupProfils(profil);
                  zoomAtPoint(position);
                  setState(() {

                  });
                }
            )

        );
      }

      //if(mapZoom > cityZoom){
        for(var event in aktiveEvents){
          var basisVerschiebung;
          var anpassungsVerschiebung;
          var geteiltDurch;

          if(mapZoom > cityZoom){
            basisVerschiebung = 0.35;
            anpassungsVerschiebung = mapZoom - cityZoom;
            geteiltDurch = 9.5;
          } else if(mapZoom > 4.0){
            basisVerschiebung = 1.5;
            anpassungsVerschiebung = mapZoom - 4.0;
            geteiltDurch = 2;
          } else{
            basisVerschiebung = 20;
            anpassungsVerschiebung = mapZoom;
            geteiltDurch = 0.23;
          }

          var position = LatLng(event["latt"], event["longt"] + basisVerschiebung - (anpassungsVerschiebung/geteiltDurch));

          markerList.add(
              eventMarker(event["name"], position, (){
                lastEventPopup = event;
                popupActive = true;
                createPopupEvents(event);
                zoomAtPoint(position);
              })
          );
        //}
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
        if(popupActive) markerPopupContainer(),
        if(mapZoom > minMapZoom && !popupActive) Positioned(
          bottom: 10,
          right: 10,
          child: FloatingActionButton(
              heroTag: "zoom out 1",
              child: const Icon(Icons.zoom_out_map),
              onPressed: () => zoomOut()
          ),
        ),
      ]),

    );

  }
}