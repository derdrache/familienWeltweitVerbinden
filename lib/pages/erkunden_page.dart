import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/pages/events/eventCard.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../services/database.dart';
import '../global/global_functions.dart' as global_functions;
import '../global/variablen.dart' as global_var;
import '../widgets/profil_image.dart';
import '../widgets/search_autocomplete.dart';
import '../services/locationsService.dart';


class ErkundenPage extends StatefulWidget{
  @override
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>{
  var profilBox;
  var eventBox;
  MapController mapController = MapController();
  var ownProfil;
  Set<String> allUserName = {};
  var countriesList = {};
  var filterList = [];
  List profilsBackup = [], profils = [], aktiveProfils = [];
  List profilBetweenCountries, profilCountries, profilsBetween, profilsCities;
  List eventsKontinente, eventsCountries, eventsBetween, eventsCities;
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
  var beforeZoomPosition;
  var beforeZoomZoom;
  var monthsUntilInactive = 6;


  @override
  void initState() {
    profilBox = Hive.box('profilBox');
    eventBox = Hive.box("eventBox");

    setProfils();
    setEvents();



    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod() );
    super.initState();
  }

  setProfils(){
    profils = profilBox.get("list");

    profils ??= [];

    for(var profil in profils){
      if(profil["id"] == userId){
        ownProfil = profil;
      } else {
        allUserName.add(profil["name"]);
      }
    }

    profils.remove(ownProfil);

    profilsBackup = profils;
    createAndSetZoomProfils();
  }

  setEvents(){
    events = eventBox.get("list");
    events ??= [];
    eventsBackup = events;

    createAndSetZoomEvents();
  }

  _asyncMethod() async{
    await getProfilsDB();
    await getEventsDB();

    setSearchAutocomplete();

    buildLoaded = true;

  }

  getProfilsDB() async{
    var dbProfils = await ProfilDatabase().getData("id, name, land, interessen, "
        "kinder, latt, longt, ort, reiseart, sprachen, aboutme, friendlist, "
        "emailAnzeigen, bild, bildStandardFarbe, lastLogin",
        "ORDER BY land ASC, ort ASC");
    if(dbProfils == false) dbProfils = [];
    profilBox.put("list", dbProfils);
    profils = dbProfils;
    var inactiveProfils = [];

    for(var profil in profils){
      profil["lastLogin"] = profil["lastLogin"] ?? DateTime.parse("2022-02-13");
      var timeDifference = Duration(microseconds: (DateTime.now().microsecondsSinceEpoch - DateTime.parse(profil["lastLogin"].toString()).microsecondsSinceEpoch).abs()
      );
      var monthDifference = timeDifference.inDays / 30.44;

      if(profil["id"] == userId){
        ownProfil = profil;
      } else if(monthDifference >= monthsUntilInactive){
        inactiveProfils.add(profil);
      }else {
        allUserName.add(profil["name"]);
      }
    }

    for(var profil in inactiveProfils){
      profils.remove(profil);
    }

    profils.remove(ownProfil);

    profilsBackup = profils;
    createAndSetZoomProfils();
  }

  getEventsDB() async {
    dynamic dbEvents = await EventDatabase().getData("*", "WHERE art != 'privat' AND art != 'private' ORDER BY wann ASC", returnList: true);
    if(dbEvents == false) dbEvents = [];
    eventBox.put("list", dbEvents);
    events = dbEvents;

    eventsBackup = events;
    createAndSetZoomEvents();
  }

  setSearchAutocomplete() {
    countriesList = LocationService().getAllCountries();
    var spracheIstDeutsch = kIsWeb ? window.locale.languageCode == "de" : Platform.localeName == "de_DE";
    var countryDropDownList = spracheIstDeutsch ? countriesList["ger"] : countriesList["eng"];

    searchAutocomplete =  SearchAutocomplete(
      hintText: AppLocalizations.of(context).filterErkunden,
      searchableItems: global_var.reisearten + global_var.interessenListe +
          global_var.sprachenListe + allUserName.toList() + countryDropDownList,
      onConfirm: () => changeMapFilter(),
      onDelete:() => changeMapFilter() ,
    );
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
        double originalLatt = profil["latt"];
        double newLatt = list[i]["latt"];
        double originalLongth = profil["longt"];
        double newLongth = list[i]["longt"];
        bool check = (newLatt + abstand >= originalLatt && newLatt - abstand <= originalLatt) &&
            (newLongth + abstand >= originalLongth && newLongth - abstand<= originalLongth);

        if(check){
          newPoint = true;
          var numberName = int.parse(list[i]["name"]) + 1;
          if(numberName > 99) numberName = 99;
          list[i]["name"] = numberName.toString();
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

  createCities(list, profil){
      var newCity = false;

      for(var i = 0; i< list.length; i++){
        double profilLongt = profil["longt"];
        double profilLatt = profil["latt"];

        if(profilLongt == list[i]["longt"] && profilLatt == list[i]["latt"]){
          newCity = true;
          var addNumberName = int.parse(list[i]["name"]) + 1;
          if(addNumberName > 99) addNumberName = 99;
          list[i]["name"] = addNumberName.toString();
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

  createCountries(list, profil) {
      var checkNewCountry = true;

      for (var i = 0; i<list.length; i++){
        var listCountryLocation = LocationService().getCountryLocation(list[i]["countryname"]);
        var profilCountryLocation = LocationService().getCountryLocation(profil["land"]);

        if(listCountryLocation["latt"] == profilCountryLocation["latt"] &&
            listCountryLocation["longt"] == profilCountryLocation["longt"] ){
          checkNewCountry = false;
          var addNumberName = int.parse(list[i]["name"]) + 1;
          if(addNumberName > 99) addNumberName = 99;
          list[i]["name"] = addNumberName.toString();
          list[i]["profils"].add(profil);
        }
      }

      if(checkNewCountry){
        var country = profil["land"];
        var position = LocationService().getCountryLocation(country);

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

  createContinents(list, profil) {
    var newPoint = true;

    var landGedataProfil = LocationService().getCountryLocation(profil["land"]);
    landGedataProfil["kontinentGer"] ??= landGedataProfil["nameGer"];
    landGedataProfil["kontinentEng"] ??= landGedataProfil["nameEng"];

    var kontinentGeodataProfil = LocationService().getKontinentLocation(landGedataProfil["kontinentGer"]);
    kontinentGeodataProfil ??= {"kontinentGer" : landGedataProfil["nameGer"]};
    kontinentGeodataProfil ??= {"kontinentEng" : landGedataProfil["nameEng"]};

    for(var i = 0; i< list.length; i++){
      var kontinentGeodataListitem = LocationService().getKontinentLocation(list[i]["kontinent"]);
      kontinentGeodataListitem ??= {"kontinentGer" : list[i]["kontinent"]};

      if(kontinentGeodataListitem["kontinentGer"] == kontinentGeodataProfil["kontinentGer"]){
        newPoint = false;
        var addNumberName = int.parse(list[i]["name"]) + 1;
        if(addNumberName > 99) addNumberName = 99;
        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if(newPoint){

      list.add({
        "kontinentName": landGedataProfil["kontinentGer"],
        "kontinent": landGedataProfil["kontinentGer"] ?? landGedataProfil["land"],
        "name": "1",
        "latt": kontinentGeodataProfil["latt"] ?? landGedataProfil["latt"] ,
        "longt":kontinentGeodataProfil["longt"] ?? landGedataProfil["longt"],
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
      pufferProfilBetweenCountries = await createContinents(
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
      pufferEventsBetweenCountries = await createContinents(
          pufferEventsBetweenCountries, events[i]);

      pufferEventsBetween = createBetween(pufferEventsBetween, events[i], 1);

      pufferEventsCities = createCities(pufferEventsCities,
          events[i]);

    }

    eventsCities = pufferEventsCities;
    eventsBetween = pufferEventsBetween;
    eventsCountries = pufferEventsCountries;
    eventsKontinente = pufferEventsBetweenCountries;

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
      selectedEventList = eventsKontinente;
    }


    if(mounted) {
      setState(() {
        aktiveProfils = choosenProfils ?? [];
        aktiveEvents = selectedEventList ?? [];
      });
    }
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
    var filterEvents = [];
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
    if(mapZoom < 2.6){
      mapZoom = 2.6;
    } else if(mapZoom< 4){
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

    if(beforeZoomPosition != null) {
      newZoom = beforeZoomZoom;
      mapPosition = beforeZoomPosition;

      beforeZoomZoom = beforeZoomPosition = null;
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

      if(filter == "kontinente"){
        var locationData = LocationService().getCountryLocation(list[0]["land"]);
        return locationData["kontinentGer"] + " / " + locationData["kontinentEng"];
      }else if(filter == "stadt"){
        return list[0]["ort"];
      }

      for(var item in list){
        if(!titleList.contains(item[filter])) titleList.add(item[filter]);
      }

      return titleList.join(" / ");
    }

    selectPopupMenuText(profils){
      if(mapZoom <2.5){
        return createPopupWindowTitle(profils, "kontinente");
      } else if(mapZoom <4.0){
        return createPopupWindowTitle(profils, "land");
      } else if(mapZoom< cityZoom){
        return createPopupWindowTitle(profils, "land");
      } else {
        return createPopupWindowTitle(profils, "stadt");
      }

    }

    createPopupProfils(profil){
      popupItems = [];

      childrenAgeStringToStringAge(childrenAgeList){
        List yearChildrenAgeList = [];
        childrenAgeList.sort();
        var alterZusatz = spracheIstDeutsch ? "J": "y";


        childrenAgeList.forEach((child){
          var childYears = global_functions.ChangeTimeStamp(child).intoYears();
          yearChildrenAgeList.add(childYears.toString() +  alterZusatz);
        });

        return yearChildrenAgeList.reversed.join(" , ");
      }

      popupItems.add(
          Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            child: Text(
                selectPopupMenuText(profil["profils"]),
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
                  child: Row(
                    children: [
                      ProfilImage(profil),
                      SizedBox(width: 10),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profil["name"], style: const TextStyle(fontWeight: FontWeight.bold),),
                            const SizedBox(height: 5),
                            Text(childrenAgeStringToStringAge(profil["kinder"])),
                            const SizedBox(height: 5),
                            Text(profil["ort"]+", " + profil["land"])
                          ]
                      )
                    ],
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
              padding: const EdgeInsets.all(10),
              child: Text(
                  selectPopupMenuText(event["profils"]),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              )
          )
      );


      for(var event in event["profils"]){
        popupItems.add(
            EventCard(
              margin: const EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
              event: event,
              withInteresse: true,
              afterPageVisit: () async {
                events = await EventDatabase().getData("*", "WHERE art != 'privat' AND art != 'private' ORDER BY wann ASC");

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
              }
            )
        );
      }

      popupItems = [Wrap(spacing: 10, alignment: WrapAlignment.center, children: popupItems)];
      // kann geändert werden wenn Profils auch Karten sind (wie die Events)
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
          child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              }),
              child: DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.8,
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
                             child: ListView(
                                 padding: const EdgeInsets.only(top:5),
                                 controller: controller,
                                 children: popupItems
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
            ),
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
              point: LatLng(ownProfil["latt"]+0.07, ownProfil["longt"]+0.02),
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
                  beforeZoomPosition = mapPosition;
                  beforeZoomZoom= mapZoom;
                  zoomAtPoint(position);
                  setState(() {

                  });
                }
            )

        );
      }

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
                beforeZoomPosition = mapPosition;
                beforeZoomZoom= mapZoom;
                zoomAtPoint(position);
              })
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