import 'dart:io';
import 'dart:ui';

import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/pages/weltkarte/stadtinformation.dart';
import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../widgets/month_picker.dart';
import 'create_stadtinformation.dart';
import '../../global/global_functions.dart';
import '../../services/database.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../global/variablen.dart' as global_var;
import '../../widgets/profil_image.dart';
import '../../widgets/search_autocomplete.dart';
import '../../services/locationsService.dart';
import '../show_profil.dart';
import '../events/eventCard.dart';

class ErkundenPage extends StatefulWidget {
  const ErkundenPage({Key key}) : super(key: key);

  @override
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage> {
  Box profilBox, eventBox, stadtinfoUserBox;
  MapController mapController = MapController();
  var ownProfil = Hive.box("ownProfilBox").get("list");
  Set<String> allUserName = {};
  List allCities = Hive.box("stadtinfoBox").get("list");
  var countriesList = {};
  List<String> citiesList = [];
  List filterList = [];
  List profilsBackup = [], profils = [], aktiveProfils = [];
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
  var popupTyp = "";
  List<Widget> popupItems = [];
  List popupCities = [];
  var lastEventPopup;
  var monthsUntilInactive = 3;
  bool friendMarkerOn = false, eventMarkerOn = false, reiseplanungOn = false;

  @override
  void initState() {
    profilBox = Hive.box('profilBox');
    eventBox = Hive.box("eventBox");
    stadtinfoUserBox = Hive.box("stadtinfoUserBox");

    removeCitiesWithoutInformation();
    setProfils();
    setEvents();

    WidgetsBinding.instance?.addPostFrameCallback((_) => _asyncMethod());
    super.initState();
  }

  removeCitiesWithoutInformation() {
    var newAllCities = [];

    for (var city in allCities) {
      var condition = city["kosten"] != null ||
          city["wetter"] != null ||
          city["kosten"] != null ||
          city["internet"] != null ||
          city["familien"].isNotEmpty;

      if (condition) {
        newAllCities.add(city);
      }
    }

    allCities = newAllCities;
  }

  setProfils() {
    var ownProfilPuffer;
    profils = profilBox.get("list") ?? [];

    for (var profil in profils) {
      if (profil["id"] == userId) {
        ownProfilPuffer = profil;
      } else {
        allUserName.add(profil["name"]);
      }
    }

    profils.remove(ownProfilPuffer);
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

    refreshHiveBox();
  }

  refreshHiveBox() async {
    var stadtinfoUser =
        await StadtinfoUserDatabase().getData("*", "", returnList: true);
    Hive.box("stadtinfoUserBox").put("list", stadtinfoUser);
  }

  getProfilsDB() async {
    List<dynamic> dbProfils =
        await ProfilDatabase().getData("*", "ORDER BY ort ASC");
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

      if (allCountries["eng"].contains(profilALand)) {
        var index = allCountries["eng"].indexOf(profilALand);
        profilALand = allCountries["ger"][index];
      }
      if (allCountries["eng"].contains(profilBLand)) {
        var index = allCountries["eng"].indexOf(profilBLand);
        profilBLand = allCountries["ger"][index];
      }

      int compareCountry = (profilBLand).compareTo(profilALand) as int;

      if (compareCountry != 0) return compareCountry;

      return b["ort"].compareTo(a["ort"]) as int;
    });

    return profils;
  }

  changeProfilList() {
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

    for (var city in allCities) {
      if (city["isCity"] == 1) citiesList.add(city["ort"]);
    }

    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).filterErkunden,
      searchableItems: global_var.reisearten +
          global_var.interessenListe +
          global_var.sprachenListe +
          allUserName.toList() +
          countryDropDownList +
          citiesList,
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
        var numberName =
            int.parse(list[i]["name"]) + (profil["name"] == null ? 0 : 1);

        list[i]["name"] = numberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (!newPoint) {
      list.add({
        "ort": profil["ort"],
        "name": profil["name"] == null ? "0" : "1",
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
        var addNumberName =
            int.parse(list[i]["name"]) + (profil["name"] == null ? 0 : 1);

        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (!newCity) {
      list.add({
        "ort": profil["ort"],
        "name": profil["name"] == null ? "0" : "1",
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
        var addNumberName =
            int.parse(list[i]["name"]) + (profil["name"] == null ? 0 : 1);

        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (checkNewCountry) {
      var country = profil["land"];
      var position = LocationService().getCountryLocation(country);

      list.add({
        "name": profil["name"] == null ? "0" : "1",
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

      if ((kontinentGeodataListitem["kontinentGer"] ==
              kontinentGeodataProfil["kontinentGer"]) ||
          (list[i]["latt"] == profil["latt"] &&
              list[i]["longt"] == profil["longt"])) {
        newPoint = false;

        var addNumberName =
            int.parse(list[i]["name"]) + (profil["name"] == null ? 0 : 1);

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
        "name": profil["name"] == null ? "0" : "1",
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
    var pufferProfilContinents = [];

    addCityProfils();

    for (var i = 0; i < profils.length; i++) {
      pufferProfilCountries =
          await createCountries(pufferProfilCountries, profils[i]);
      pufferProfilContinents =
          await createContinents(pufferProfilContinents, profils[i]);

      pufferProfilBetween = createBetween(pufferProfilBetween, profils[i], 1);

      pufferProfilCities = createCities(pufferProfilCities, profils[i]);
    }

    profilsCities = pufferProfilCities;
    profilsBetween = pufferProfilBetween;
    profilCountries = pufferProfilCountries;
    profilBetweenCountries = pufferProfilContinents;

    changeProfil(currentMapZoom);
  }

  addCityProfils() {
    if (filterList.isEmpty) {
      profils = profils + allCities;
    } else {
      var matchFilter = [];

      for (var city in allCities) {
        if (filterList.contains(city["ort"]) ||
            filterList.contains(city["land"])) {
          matchFilter.add(city);
        }
      }

      profils = profils + matchFilter;
    }
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
    var profilOrt = profil["ort"];

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
    var cityMatch = checkMatch(filterList, [profilOrt], citiesList);

    if (spracheMatch &&
        reiseartMatch &&
        interesseMatch &&
        userMatch &&
        countryMatch &&
        cityMatch) return true;

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
    filterList = searchAutocomplete.getSelected();

    for (var profil in profilsBackup) {
      if (checkFilter(profil)) filterProfils.add(profil);
    }

    setState(() {
      profils = filterProfils;
      createAndSetZoomProfils();
    });
  }

  zoomOut() {
    double newZoom;

    if (currentMapZoom > cityZoom + 1) {
      newZoom = cityZoom;
    } else if (currentMapZoom > countryZoom) {
      newZoom = countryZoom;
    } else if (currentMapZoom > kontinentZoom) {
      newZoom = kontinentZoom;
    } else {
      newZoom = minMapZoom;
    }

    mapController.move(mapPosition, newZoom);
    currentMapZoom = newZoom;
    FocusScope.of(context).unfocus();
    changeProfil(currentMapZoom);
  }

  createPopupCityInformations(profils) {
    var selectedCitiesData = [];
    popupCities = [];

    for (var city in allCities) {
      for (var profil in profils) {
        if (city["ort"] == profil["ort"]) {
          if (profil["name"] == null && friendMarkerOn) break;

          selectedCitiesData.add(city);
          break;
        }
      }
    }

    for (var city in selectedCitiesData) {
      var newCity = true;

      for (var i = 0; i < popupCities.length; i++) {
        if (popupCities[i]["names"].contains(city["ort"])) {
          newCity = false;
        } else if (popupCities[i]["latt"] == city["latt"] &&
            popupCities[i]["longt"] == city["longt"]) {
          popupCities[i]["names"].add(city["ort"]);
          newCity = false;
        }
      }

      if (newCity) {
        popupCities.add({
          "names": [city["ort"]],
          "latt": city["latt"],
          "longt": city["longt"]
        });
      }
    }
  }

  openSelectCityWindow() {
    List<Widget> cityAuswahl = [];

    for (var city in popupCities) {
      cityAuswahl.add(InkWell(
        onTap: () => changePage(
            context, StadtinformationsPage(ortName: city["names"].join(" / "))),
        child: Container(
            margin: const EdgeInsets.all(10),
            child: Text(city["names"].join(" / "))),
      ));
    }

    if (popupCities.isEmpty) {
      cityAuswahl.add(Container(
          margin: const EdgeInsets.all(10),
          child: Text(
              AppLocalizations.of(context).keineStadtinformationVorhanden,
              style: const TextStyle(color: Colors.grey))));
    }

    if (popupCities.length == 1 && currentMapZoom >= cityZoom) {
      changePage(context,
          StadtinformationsPage(ortName: popupCities[0]["names"].join(" / ")));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: AppLocalizations.of(context).ortAuswaehlen,
          children: cityAuswahl,
        );
      },
    );
  }

  openSelectReiseplanungsDateWindow() {
    var vonDate = MonthPickerBox(hintText: AppLocalizations.of(context).von);
    var bisDate = MonthPickerBox(hintText: AppLocalizations.of(context).bis);

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: "",
            children: [
              Container(
                  margin: const EdgeInsets.all(20),
                  child: Text(
                    AppLocalizations.of(context).weltkarteReiseplanungSuchen,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  )),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  vonDate,
                  const SizedBox(
                    width: 30,
                  ),
                  bisDate
                ],
              ),
              Container(
                margin: const EdgeInsets.all(30),
                child: FloatingActionButton.extended(
                    onPressed: () {
                      if (vonDate.getDate() == null) {
                        customSnackbar(context,
                            AppLocalizations.of(context).datumEingeben);
                        return;
                      }

                      reiseplanungOn = true;
                      eventMarkerOn = false;
                      friendMarkerOn = false;
                      setState(() {});

                      Navigator.pop(context);

                      showReiseplaungMatchedProfils(
                          vonDate.getDate(), bisDate.getDate());
                    },
                    label: Text(AppLocalizations.of(context).anzeigen)),
              )
            ],
          );
        });
  }

  showReiseplaungMatchedProfils(von, bis) {
    von = von;
    bis = bis ?? von;
    var selectDates = [von];
    var selectedProfils = [];

    while (von != bis) {
      von = DateTime(von.year, von.month + 1, von.day);
      selectDates.add(von);
    }

    for (var profil in profils) {
      var reiseplanung = profil["reisePlanung"];

      if (reiseplanung == null) continue;

      reiseplanungLoop:
      for (var planung in reiseplanung) {
        var planungVon = DateTime.parse(planung["von"]);
        var planungBis = DateTime.parse(planung["bis"]);

        if (selectDates.contains(planungVon)) {
          profil["ort"] = planung["ortData"]["city"];
          profil["land"] = planung["ortData"]["countryname"];
          profil["latt"] = planung["ortData"]["latt"];
          profil["longt"] = planung["ortData"]["longt"];

          selectedProfils.add(profil);
          continue reiseplanungLoop;
        }

        while (planungVon != planungBis) {
          planungVon =
              DateTime(planungVon.year, planungVon.month + 1, planungVon.day);
          if (selectDates.contains(planungVon)) {
            profil["ort"] = planung["ortData"]["city"];
            profil["land"] = planung["ortData"]["countryname"];
            profil["latt"] = planung["ortData"]["latt"];
            profil["longt"] = planung["ortData"]["longt"];

            selectedProfils.add(profil);
            continue reiseplanungLoop;
          }
        }
      }
    }

    profils = selectedProfils;
    createAndSetZoomProfils();
  }

  changeProfils(changeList) {
    var newProfilList = [];

    for (var profilId in changeList) {
      for (var profil in profilBox.get("list") ?? []) {
        if (profilId == profil["id"]) {
          newProfilList.add(profil);
          break;
        }
      }
    }
    profils = newProfilList;
    createAndSetZoomProfils();
  }

  @override
  Widget build(BuildContext context) {
    var genauerStandortBezeichnung =
        AppLocalizations.of(context).genauerStandort;
    ownProfil = Hive.box("ownProfilBox").get("list");
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
      if (friendMarkerOn) return AppLocalizations.of(context).freundesListe;

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

    createPopupProfils(profils) {
      popupItems = [];
      popupTyp = "profils";
      var selectUserProfils = [];

      for (var profil in profils) {
        if (profil["name"] != null) selectUserProfils.add(profil);
        if (profil["ort"].isEmpty) profil["ort"] = genauerStandortBezeichnung;
      }

      popupItems.add(SliverAppBar(
        toolbarHeight: kIsWeb ? 40 : 30,
        backgroundColor: Colors.white,
        flexibleSpace: Center(
            child: Text(selectPopupMenuText(profils),
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
        itemExtent: kIsWeb ? 90.0 : 80.0,
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          var profilData = selectUserProfils[index];

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
                          //const SizedBox(height: 5),
                          Text(profilData["ort"] + ", " + profilData["land"])
                        ])
                  ],
                )),
          );
        }, childCount: selectUserProfils.length),
      ));

      return popupItems;
    }

    createPopupEvents(event) {
      popupItems = [];
      popupTyp = "events";

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
                    top: 60,
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
                  if (popupTyp == "profils")
                    Positioned(
                      left: 5,
                      top: 60,
                      child: IconButton(
                        icon: const Icon(
                          Icons.feed,
                          size: 30,
                        ),
                        onPressed: () => openSelectCityWindow(),
                      ),
                    ),
                  if (currentMapZoom > minMapZoom)
                    Positioned(
                      top: 0,
                      right: 80,
                      child: FloatingActionButton(
                          heroTag: "zoom out 2",
                          child: const Icon(Icons.zoom_out_map),
                          onPressed: () => zoomOut()),
                    ),
                  Positioned(
                      top: 0,
                      right: 10,
                      child: FloatingActionButton(
                          heroTag: "create Stadtinformation 2",
                          child: const Icon(Icons.create),
                          onPressed: () => changePage(
                              context, const CreateStadtinformationsPage())))
                ],
              );
            }),
      ));
    }

    createOwnMarker() {
      if (ownProfil != null) {
        allMarker.add(Marker(
            width: 30.0,
            height: 30.0,
            point: LatLng(ownProfil["latt"] + 0.07, ownProfil["longt"] + 0.02),
            builder: (_) => Icon(
                  Icons.flag,
                  color: Colors.green[900],
                  size: 30,
                )));
      }
    }

    Marker profilMarker(numberText, position, buttonFunction) {
      double size = 30;

      if (numberText.length == 1) {
        size -= 5;
      } else if (numberText.length == 3) {
        size += 5;
      }

      return Marker(
          width: size,
          height: size,
          point: position,
          builder: (ctx) => numberText != "0"
              ? FloatingActionButton(
                  heroTag: "MapMarker" + position.toString(),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  mini: true,
                  child: Center(child: Text(numberText)),
                  onPressed: buttonFunction)
              : FloatingActionButton(
                  heroTag: "MapMarker" + position.toString(),
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Center(child: Icon(Icons.info)),
                  onPressed: buttonFunction)
      );
    }

    createProfilMarker() {
      for (var profil in aktiveProfils) {
        if (friendMarkerOn && profil["name"] == "0") continue;

        var position = LatLng(profil["latt"], profil["longt"]);
        allMarker.add(profilMarker(profil["name"], position, () {
          popupActive = true;
          createPopupProfils(profil["profils"]);
          createPopupCityInformations(profil["profils"]);
          setState(() {});
        }));
      }
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

    createEventMarker() {
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

        allMarker.add(eventMarker(event["name"], position, () {
          lastEventPopup = event;
          popupActive = true;
          createPopupEvents(event);
          setState(() {});
        }));
      }
    }

    createAllMarker() async {
      createOwnMarker();
      if (!eventMarkerOn) createProfilMarker();
      if (eventMarkerOn) createEventMarker();
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

    friendButton() {
      return Positioned(
          right: 5,
          top: 60,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Stack(
              children: [
                if (!friendMarkerOn)
                  Icon(Icons.favorite_outline,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                if (friendMarkerOn)
                  Icon(Icons.favorite,
                      size: 32, color: Theme.of(context).colorScheme.primary)
              ],
            ),
            onPressed: () {
              if (friendMarkerOn) {
                friendMarkerOn = false;
                popupActive = false;
                profils = profilsBackup;
                createAndSetZoomProfils();
              } else {
                friendMarkerOn = true;
                eventMarkerOn = false;
                reiseplanungOn = false;
                changeProfils(ownProfil["friendlist"]);

                popupActive = true;
                createPopupProfils(profils);
                createPopupCityInformations(profils);
              }

              setState(() {});
            },
          ));
    }

    eventButton() {
      return Positioned(
          right: 5,
          top: 110,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Stack(
              children: [
                if (!eventMarkerOn)
                  Icon(Icons.calendar_today_outlined,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                if (eventMarkerOn)
                  Icon(Icons.event_note,
                      size: 36, color: Theme.of(context).colorScheme.primary)
              ],
            ),
            onPressed: () {
              if (eventMarkerOn) {
                eventMarkerOn = false;
              } else {
                eventMarkerOn = true;
                friendMarkerOn = false;
                reiseplanungOn = false;
              }

              setState(() {});
            },
          ));
    }

    reiseplanungButton() {
      return Positioned(
          right: 5,
          top: 165,
          child: IconButton(
              padding: EdgeInsets.zero,
              icon: reiseplanungOn
                  ? Icon(Icons.schedule,
                      size: 32, color: Theme.of(context).colorScheme.primary)
                  : Icon(Icons.update,
                      size: 36, color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                if (reiseplanungOn) {
                  reiseplanungOn = false;
                  profils = profilsBackup;
                  createAndSetZoomProfils();
                  setState(() {});
                } else {
                  openSelectReiseplanungsDateWindow();
                }
              }));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
        child: Stack(children: [
          ownFlutterMap(),
          searchAutocomplete,
          if (popupActive) markerPopupContainer(),
          friendButton(),
          eventButton(),
          reiseplanungButton()
        ]),
      ),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (currentMapZoom > minMapZoom && !popupActive)
          FloatingActionButton(
              heroTag: "zoom out 1",
              child: const Icon(Icons.zoom_out_map),
              onPressed: () => zoomOut()),
        const SizedBox(width: 10),
        if (!popupActive)
          FloatingActionButton(
              heroTag: "create Stadtinformation 1",
              child: const Icon(Icons.create),
              onPressed: () =>
                  changePage(context, const CreateStadtinformationsPage())),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
