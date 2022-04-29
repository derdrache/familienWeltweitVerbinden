import 'dart:io';
import 'dart:ui';

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
import 'show_profil.dart';
import 'events/eventCard.dart';

class ErkundenPage extends StatefulWidget {
  const ErkundenPage({Key key}) : super(key: key);

  @override
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage> {
  Box profilBox, eventBox;
  MapController mapController = MapController();
  var ownProfil;
  Set<String> allUserName = {};
  var countriesList = {};
  List filterList = [];
  List profilsBackup = [] , profils = [], aktiveProfils = [];
  List eventsBackup = [], events = [], aktiveEvents = [];
  List profilBetweenCountries, profilCountries, profilsBetween, profilsCities;
  List eventsKontinente, eventsCountries, eventsBetween, eventsCities;
  double minMapZoom = kIsWeb ? 2.0 : 1.6;
  double maxZoom = 9;
  double currentMapZoom = 1.6;
  double cityZoom = 6.5;
  double countryZoom = 4.0;
  double kontinentZoom = 2.5;
  var searchAutocomplete = SearchAutocomplete();
  var mapPosition;
  bool buildLoaded = false;
  bool popupActive = false;
  List<Widget> popupItems = [];
  var lastEventPopup;
  var monthsUntilInactive = 6;

  @override
  void initState() {
    profilBox = Hive.box('profilBox');
    eventBox = Hive.box("eventBox");

    setProfils();
    setEvents();

    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());
    super.initState();
  }

  setProfils() {
    profils = profilBox.get("list") ?? [];

    for (var profil in profils) {
      if (profil["id"] == userId) {
        ownProfil = profil;
      } else {
        allUserName.add(profil["name"]);
      }
    }

    profils.remove(ownProfil);

    profilsBackup = profils;
    createAndSetZoomProfils();
  }

  setEvents() {
    events = eventBox.get("list") ?? [];
    eventsBackup = events;

    createAndSetZoomEvents();
  }

  _asyncMethod() async {
    await getProfilsDB();
    changeProfilList();
    createAndSetZoomProfils();

    await getEventsDB();
    createAndSetZoomEvents();

    setSearchAutocomplete();

    buildLoaded = true;
  }

  getProfilsDB() async {
    List<dynamic> dbProfils = await ProfilDatabase().getData(
        "id, name, land, interessen, kinder, latt, longt, ort, reiseart,"
          "sprachen, aboutme, friendlist, emailAnzeigen, bild, bildStandardFarbe,"
          "lastLogin, aufreiseSeit, aufreiseBis",
        "ORDER BY ort ASC");
    if (dbProfils == false) dbProfils = [];

    dbProfils = sortProfils(dbProfils);

    profilBox.put("list", dbProfils);
    profils = dbProfils;
  }

  sortProfils(profils) {
    var allCountries = LocationService().getAllCountries();

    profils.sort((a, b) {
      var profilALand = a['land'];
      var profilBLand = b['land'];

      if(allCountries["eng"].contains(profilALand)){
        var index = allCountries["eng"].indexOf(profilALand);
        profilALand = allCountries["ger"][index];
      }
      if(allCountries["eng"].contains(profilBLand)){
        var index = allCountries["eng"].indexOf(profilBLand);
        profilBLand = allCountries["ger"][index];
      }

      int compareCountry =  (profilBLand).compareTo(profilALand) as int;

      if (compareCountry != 0) return compareCountry;

      return b["ort"].compareTo(a["ort"]) as int;
    });


    return profils;
  }

  changeProfilList(){
    var inactiveProfils = [];

    for (var profil in profils) {
      profil["lastLogin"] = profil["lastLogin"] ?? DateTime.parse("2022-02-13");
      var timeDifference = Duration(
          microseconds: (DateTime.now().microsecondsSinceEpoch -
              DateTime.parse(profil["lastLogin"].toString())
                  .microsecondsSinceEpoch)
              .abs());
      var monthDifference = timeDifference.inDays / 30.44;

      if (profil["id"] == userId) {
        ownProfil = profil;
      } else if (monthDifference >= monthsUntilInactive) {
        inactiveProfils.add(profil);
      } else {
        allUserName.add(profil["name"]);
      }
    }

    for (var profil in inactiveProfils) {
      profils.remove(profil);
    }

    profils.remove(ownProfil);

    profilsBackup = profils;
  }

  getEventsDB() async {
    dynamic dbEvents = await EventDatabase().getData(
        "*", "WHERE art != 'privat' AND art != 'private' ORDER BY wann ASC",
        returnList: true);
    if (dbEvents == false) dbEvents = [];

    eventBox.put("list", dbEvents);
    events = dbEvents;

    eventsBackup = events;
  }

  setSearchAutocomplete() {
    countriesList = LocationService().getAllCountries();
    var spracheIstDeutsch = kIsWeb
        ? window.locale.languageCode == "de"
        : Platform.localeName == "de_DE";
    var countryDropDownList =
        spracheIstDeutsch ? countriesList["ger"] : countriesList["eng"];

    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).filterErkunden,
      searchableItems: global_var.reisearten +
          global_var.interessenListe +
          global_var.sprachenListe +
          allUserName.toList() +
          countryDropDownList,
      onConfirm: () => changeMapFilter(),
      onDelete: () => changeMapFilter(),
    );
  }

  createBetween(list, profil, abstand) {
    var newPoint = false;

    for (var i = 0; i < list.length; i++) {
      double originalLatt = profil["latt"];
      double newLatt = list[i]["latt"];
      double originalLongth = profil["longt"];
      double newLongth = list[i]["longt"];
      bool check = (newLatt + abstand >= originalLatt &&
              newLatt - abstand <= originalLatt) &&
          (newLongth + abstand >= originalLongth &&
              newLongth - abstand <= originalLongth);

      if (check) {
        newPoint = true;
        var numberName = int.parse(list[i]["name"]) + 1;
        if (numberName > 99) numberName = 99;
        list[i]["name"] = numberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (!newPoint) {
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

  createCities(list, profil) {
    var newCity = false;

    for (var i = 0; i < list.length; i++) {
      double profilLongt = profil["longt"];
      double profilLatt = profil["latt"];

      if (profilLongt == list[i]["longt"] && profilLatt == list[i]["latt"]) {
        newCity = true;
        var addNumberName = int.parse(list[i]["name"]) + 1;
        if (addNumberName > 99) addNumberName = 99;
        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (!newCity) {
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

    for (var i = 0; i < list.length; i++) {
      var listCountryLocation =
          LocationService().getCountryLocation(list[i]["countryname"]);
      var profilCountryLocation =
          LocationService().getCountryLocation(profil["land"]);

      if (listCountryLocation["latt"] == profilCountryLocation["latt"] &&
          listCountryLocation["longt"] == profilCountryLocation["longt"]) {
        checkNewCountry = false;
        var addNumberName = int.parse(list[i]["name"]) + 1;
        if (addNumberName > 99) addNumberName = 99;
        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (checkNewCountry) {
      var country = profil["land"];
      var position = LocationService().getCountryLocation(country);

      list.add({
        "name": "1",
        "countryname": country,
        "longt": position["longt"] ?? 0,
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

    var kontinentGeodataProfil = LocationService()
        .getKontinentLocation(landGedataProfil["kontinentGer"]);
    kontinentGeodataProfil ??= {"kontinentGer": landGedataProfil["nameGer"]};
    kontinentGeodataProfil ??= {"kontinentEng": landGedataProfil["nameEng"]};

    for (var i = 0; i < list.length; i++) {
      var kontinentGeodataListitem =
          LocationService().getKontinentLocation(list[i]["kontinent"]);
      kontinentGeodataListitem ??= {"kontinentGer": list[i]["kontinent"]};

      if (kontinentGeodataListitem["kontinentGer"] ==
          kontinentGeodataProfil["kontinentGer"]) {
        newPoint = false;
        var addNumberName = int.parse(list[i]["name"]) + 1;
        if (addNumberName > 99) addNumberName = 99;
        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (newPoint) {
      list.add({
        "kontinentName": landGedataProfil["kontinentGer"],
        "kontinent":
            landGedataProfil["kontinentGer"] ?? landGedataProfil["land"],
        "name": "1",
        "latt": kontinentGeodataProfil["latt"] ?? landGedataProfil["latt"],
        "longt": kontinentGeodataProfil["longt"] ?? landGedataProfil["longt"],
        "profils": [profil]
      });
    }

    return list;
  }

  createAndSetZoomProfils() async {
    var pufferProfilCities = [];
    var pufferProfilBetween = [];
    var pufferProfilCountries = [];
    var pufferProfilBetweenCountries = [];

    for (var i = 0; i < profils.length; i++) {
      pufferProfilCountries =
          await createCountries(pufferProfilCountries, profils[i]);
      pufferProfilBetweenCountries =
          await createContinents(pufferProfilBetweenCountries, profils[i]);

      pufferProfilBetween = createBetween(pufferProfilBetween, profils[i], 1);

      pufferProfilCities = createCities(pufferProfilCities, profils[i]);
    }

    profilsCities = pufferProfilCities;
    profilsBetween = pufferProfilBetween;
    profilCountries = pufferProfilCountries;
    profilBetweenCountries = pufferProfilBetweenCountries;

    changeProfil(currentMapZoom);
  }

  createAndSetZoomEvents() async {
    var pufferEventsCities = [];
    var pufferEventsBetween = [];
    var pufferEventsCountries = [];
    var pufferEventsBetweenCountries = [];

    for (var i = 0; i < events.length; i++) {
      pufferEventsCountries =
          await createCountries(pufferEventsCountries, events[i]);
      pufferEventsBetweenCountries =
          await createContinents(pufferEventsBetweenCountries, events[i]);

      pufferEventsBetween = createBetween(pufferEventsBetween, events[i], 1);

      pufferEventsCities = createCities(pufferEventsCities, events[i]);
    }

    eventsCities = pufferEventsCities;
    eventsBetween = pufferEventsBetween;
    eventsCountries = pufferEventsCountries;
    eventsKontinente = pufferEventsBetweenCountries;

    changeProfil(currentMapZoom);
  }

  changeProfil(zoom) {
    var choosenProfils = [];
    var selectedEventList = [];

    if (zoom > cityZoom) {
      choosenProfils = profilsCities;
      selectedEventList = eventsCities;
    } else if (zoom > countryZoom) {
      choosenProfils = profilsBetween;
      selectedEventList = eventsBetween;
    } else if (zoom > kontinentZoom) {
      choosenProfils = profilCountries;
      selectedEventList = eventsCountries;
    } else {
      choosenProfils = profilBetweenCountries;
      selectedEventList = eventsKontinente;
    }

    if (mounted) {
      setState(() {
        aktiveProfils = choosenProfils ?? [];
        aktiveEvents = selectedEventList ?? [];
      });
    }
  }

  checkFilter(profil) {
    var profilInteressen = profil["interessen"];
    var profilReiseart = profil["reiseart"];
    var profilSprachen = profil["sprachen"];
    var profilName = profil["name"];
    var profilLand = profil["land"];

    if (filterList.isEmpty) return true;

    var spracheMatch = checkMatch(filterList, profilSprachen,
        global_var.sprachenListe + global_var.sprachenListeEnglisch);
    var reiseartMatch = checkMatch(filterList, [profilReiseart],
        global_var.reisearten + global_var.reiseartenEnglisch);
    var interesseMatch = checkMatch(filterList, profilInteressen,
        global_var.interessenListe + global_var.interessenListeEnglisch);
    var userMatch =
        checkMatch(filterList, [profilName], allUserName, userSearch: true);
    var countryMatch = checkMatch(
        filterList, [profilLand], countriesList["ger"] + countriesList["eng"]);

    if (spracheMatch &&
        reiseartMatch &&
        interesseMatch &&
        userMatch &&
        countryMatch) return true;

    return false;
  }

  checkMatch(List selected, List checkList, globalList, {userSearch = false}) {
    bool globalMatch = false;
    bool match = false;

    for (var select in selected) {
      if (globalList.contains(select)) globalMatch = true;

      if (checkList.contains(select)) match = true;

      if (userSearch) continue;

      if (globalMatch && !match) {
        int halfListNumber = (globalList.length / 2).toInt();
        var positionGlobal = globalList.indexOf(select);
        var calculatePosition = positionGlobal < halfListNumber
            ? positionGlobal + halfListNumber
            : positionGlobal - halfListNumber;
        var otherLanguage = globalList[calculatePosition];

        if (checkList.contains(otherLanguage)) match = true;
      }
    }

    if (!globalMatch) return true;
    if (match) return true;

    return false;
  }

  changeMapFilter() {
    var filterProfils = [];

    for (var profil in profilsBackup) {
      if (checkFilter(profil)) filterProfils.add(profil);
    }

    setState(() {
      filterList = searchAutocomplete.getSelected();
      profils = filterProfils;
      createAndSetZoomProfils();
    });
  }

  zoomOut() {
    double newZoom;

    if (currentMapZoom > cityZoom + 1) {
      newZoom = cityZoom;
    } else if (currentMapZoom > countryZoom ) {
      newZoom = countryZoom;
    } else if(currentMapZoom > kontinentZoom) {
      newZoom = kontinentZoom;
    } else{
        newZoom = minMapZoom;
    }

      mapController.move(mapPosition, newZoom);
      currentMapZoom = newZoom;
      FocusScope.of(context).unfocus();
      changeProfil(currentMapZoom);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    var eventCrossAxisCount = screenWidth / 190;
    List<Marker> allMarker = [];

    createPopupWindowTitle(list, filter) {
      var titleList = [];

      if (filter == "kontinente") {
        var locationData =
            LocationService().getCountryLocation(list[0]["land"]);
        return locationData["kontinentGer"] +
            " / " +
            locationData["kontinentEng"];
      } else if (filter == "stadt") {
        return list[0]["ort"];
      }

      for (var item in list) {
        if (!titleList.contains(item[filter])) titleList.add(item[filter]);
      }

      return titleList.join(" / ");
    }

    selectPopupMenuText(profils) {
      if (currentMapZoom < kontinentZoom) {
        return createPopupWindowTitle(profils, "kontinente");
      } else if (currentMapZoom < countryZoom) {
        return createPopupWindowTitle(profils, "land");
      } else if (currentMapZoom < cityZoom) {
        return createPopupWindowTitle(profils, "land");
      } else {
        return createPopupWindowTitle(profils, "stadt");
      }
    }

    createPopupProfils(profil) {
      popupItems = [];

      popupItems.add(SliverAppBar(
        toolbarHeight: 30,
        backgroundColor: Colors.white,
        flexibleSpace: Center(
            child: Text(selectPopupMenuText(profil["profils"]),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
        pinned: true,
      ));

      childrenAgeStringToStringAge(childrenAgeList) {
        List yearChildrenAgeList = [];
        childrenAgeList.sort();
        var alterZusatz = spracheIstDeutsch ? "J" : "y";

        childrenAgeList.forEach((child) {
          var childYears = global_functions.ChangeTimeStamp(child).intoYears();
          yearChildrenAgeList.add(childYears.toString() + alterZusatz);
        });

        return yearChildrenAgeList.reversed.join(" , ");
      }

      popupItems.add(SliverFixedExtentList(
        itemExtent: 80.0,
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          var profilData = profil["profils"][index];

          return GestureDetector(
            onTap: () {
              global_functions.changePage(
                  context,
                  ShowProfilPage(
                    userName: ownProfil["name"],
                    profil: profilData,
                  ));
            },
            child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            width: 1, color: global_var.borderColorGrey))),
                child: Row(
                  children: [
                    ProfilImage(profilData),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profilData["name"],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(childrenAgeStringToStringAge(
                              profilData["kinder"])),
                          const SizedBox(height: 5),
                          Text(profilData["ort"] + ", " + profilData["land"])
                        ])
                  ],
                )),
          );
        }, childCount: profil["profils"].length),
      ));

      return popupItems;
    }

    createPopupEvents(event) {
      popupItems = [];

      popupItems.add(SliverAppBar(
        toolbarHeight: 30,
        backgroundColor: Colors.white,
        flexibleSpace: Center(
            child: Text(selectPopupMenuText(event["profils"]),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
        pinned: true,
      ));

      popupItems.add(SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: eventCrossAxisCount.round(), // 392 => 2  => 1036 =>
            childAspectRatio: 0.75,
          ),
          delegate:
              SliverChildBuilderDelegate((BuildContext context, int index) {
            var eventData = event["profils"][index];

            return EventCard(
                margin: const EdgeInsets.only(
                    top: 15, bottom: 15, left: 25, right: 25),
                event: eventData,
                withInteresse: true,
                afterPageVisit: () async {
                  events = await EventDatabase().getData("*",
                      "WHERE art != 'privat' AND art != 'private' ORDER BY wann ASC");

                  var refreshEvents = [];

                  for (var oldEvent in lastEventPopup["profils"]) {
                    for (var newEvents in events) {
                      if (oldEvent["id"] == newEvents["id"]) {
                        refreshEvents.add(newEvents);
                      }
                    }
                  }

                  lastEventPopup["profils"] = refreshEvents;
                  createPopupEvents(lastEventPopup);
                  setState(() {});
                });
          }, childCount: event["profils"].length)));

      return popupItems;
    }

    Marker profilMarker(numberText, position, buttonFunction) {
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

    Marker eventMarker(numberText, position, buttonFunction) {
      return Marker(
        width: 32.0,
        height: 32.0,
        point: position,
        builder: (ctx) => IconButton(
          padding: EdgeInsets.zero,
          icon: Stack(
            children: [
              Icon(Icons.calendar_today,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              Positioned(
                  top: 9.5,
                  left: 5.5,
                  child: Container(
                      padding: const EdgeInsets.only(left: 2, top: 1),
                      width: 21.5,
                      height: 18,
                      color: Colors.white,
                      child: Center(
                          child: Text(numberText,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black)))))
            ],
          ),
          onPressed: buttonFunction,
        ),
      );
    }

    markerPopupContainer() {
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
            builder: (context, controller) {
              return Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                          color: Colors.white,
                          child: CustomScrollView(
                              controller: controller, slivers: popupItems)),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 55,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          popupActive = false;
                        });
                      },
                    ),
                  ),
                  if (currentMapZoom > minMapZoom)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: FloatingActionButton(
                          heroTag: "zoom out",
                          child: const Icon(Icons.zoom_out_map),
                          onPressed: () => zoomOut()),
                    ),
                ],
              );
            }),
      ));
    }

    createAllMarker() async {
      List<Marker> markerList = [];

      if (ownProfil != null) {
        markerList.add(Marker(
          width: 30.0,
          height: 30.0,
          point: LatLng(ownProfil["latt"] + 0.07, ownProfil["longt"] + 0.02),
          builder: (ctx) => FloatingActionButton(
            heroTag: "ownMarker",
            backgroundColor: Colors.transparent,
            mini: true,
            child: Icon(
              Icons.flag,
              color: Colors.green[900],
              size: 30,
            ),
            onPressed: null,
          ),
        ));
      }

      for (var profil in aktiveProfils) {
        var position = LatLng(profil["latt"], profil["longt"]);
        markerList.add(profilMarker(profil["name"], position, () {
          popupActive = true;
          createPopupProfils(profil);
          setState(() {});
        }));
      }

      for (var event in aktiveEvents) {
        double basisVerschiebung, anpassungsVerschiebung, geteiltDurch;

        if (currentMapZoom > cityZoom) {
          basisVerschiebung = 0.35;
          anpassungsVerschiebung = currentMapZoom - cityZoom;
          geteiltDurch = 9.5;
        } else if (currentMapZoom > countryZoom) {
          basisVerschiebung = 1.5;
          anpassungsVerschiebung = currentMapZoom - 4.0;
          geteiltDurch = 2;
        } else {
          basisVerschiebung = 20;
          anpassungsVerschiebung = currentMapZoom;
          geteiltDurch = 0.23;
        }

        var position = LatLng(
            event["latt"],
            event["longt"] +
                basisVerschiebung -
                (anpassungsVerschiebung / geteiltDurch));

        markerList.add(eventMarker(event["name"], position, () {
          lastEventPopup = event;
          popupActive = true;
          createPopupEvents(event);
          setState(() {});
        }));
      }

      allMarker = markerList;
    }

    ownFlutterMap() {
      createAllMarker();

      return FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: LatLng(25, 0),
          zoom: minMapZoom,
          minZoom: minMapZoom,
          maxZoom: maxZoom,
          interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          onPositionChanged: (position, changed) {
            if (buildLoaded) {
              mapPosition = position.center;
              currentMapZoom = position.zoom;
              FocusScope.of(context).unfocus();
              changeProfil(currentMapZoom);
            }
          },
        ),
        layers: [
          TileLayerOptions(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']),
          MarkerLayerOptions(
            markers: allMarker,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
      child: Stack(children: [
        ownFlutterMap(),
        searchAutocomplete,
        if (popupActive) markerPopupContainer(),
        if (currentMapZoom > minMapZoom && !popupActive)
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
                heroTag: "zoom out 1",
                child: const Icon(Icons.zoom_out_map),
                onPressed: () => zoomOut()),
          ),
      ]),
    );
  }
}
