import 'dart:ui';
import 'dart:io';
import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../global/global_functions.dart' as global_functions;
import '../../global/variablen.dart' as global_var;
import '../../widgets/profil_image.dart';
import '../../widgets/search_autocomplete.dart';
import '../../widgets/flexible_date_picker.dart';
import '../../services/database.dart';
import '../../services/locationsService.dart';
import '../../widgets/badge_icon.dart';
import '../informationen/community/community_card.dart';
import '../informationen/meetups/meetupCard.dart';
import '../show_profil.dart';

class ErkundenPage extends StatefulWidget {
  const ErkundenPage({Key key}) : super(key: key);

  @override
  _ErkundenPageState createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage>
    with WidgetsBindingObserver {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var profils = [];
  var profilsBackup = [];
  var ownProfil = Hive.box('secureBox').get("ownProfil") ?? [];
  var allCities = Hive.box('secureBox').get("stadtinfo") ?? [];
  var events = [];
  var communities = Hive.box('secureBox').get("communities") ?? [];
  var familyProfils = Hive.box('secureBox').get("familyProfils") ?? [];
  MapController mapController = MapController();
  Set<String> allUserName = {};
  var countriesList = LocationService().getAllCountryNames();
  List<String> allCitiesNames = [];
  List filterList = [];
  List aktiveProfils = [];
  List aktiveEvents = [];
  List aktiveCommunities = [];
  List profilsContinents,
      profilsCountries,
      profilsBetween,
      profilsCities,
      profilsExact;
  List eventsKontinente, eventsCountries, eventsBetween, eventsCities;
  List communitiesContinents,
      communitiesCountries,
      communitiesBetween,
      communitiesCities;
  double minMapZoom = kIsWeb ? 2.0 : 1.6;
  double maxZoom = 14;
  double currentMapZoom = 1.6;
  double exactZoom = 10;
  double cityZoom = 8.5;
  double countryZoom = 5.5;
  double kontinentZoom = 3.5;
  var searchAutocomplete = SearchAutocomplete();
  LatLng mapPosition;
  bool popupActive = false;
  var popupTyp = "";
  List<Widget> popupItems = [];
  var lastEventPopup;
  var monthsUntilInactive = 3;
  var mounted = false;
  bool friendMarkerOn = false,
      eventMarkerOn = false,
      reiseplanungOn = false,
      communityMarkerOn = false,
      filterOn = false;
  bool createMenuIsOpen = false;
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  @override
  void initState() {
    var hiveProfils = List.of(Hive.box('secureBox').get("profils") ?? []);
    profils = [for (var profil in hiveProfils) Map.of(profil)];

    setEvents();

    changeProfilToFamilyProfil();
    removeProfilsAndCreateAllUserName();
    sortProfils(profils);

    profilsBackup = profils;
    createAndSetZoomLevels(profils, "profils");
    createAndSetZoomLevels(communities, "communities");

    setSearchAutocomplete();

    WidgetsBinding.instance.addObserver(this);

    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => mounted = true);
  }

  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && this.mounted) {
      await _refreshData();
      setState(() {});
    }
  }

  _refreshData() async {
    await refreshHiveProfils();
    refreshHiveNewsPage();
    refreshHiveChats();
    await refreshHiveMeetups();
    await refreshHiveCommunities();
  }


  setEvents() {
    var localDbEvents = Hive.box('secureBox').get("events") ?? [];

    for (var event in localDbEvents) {
      if (event["art"] != 'privat' && event["art"] != 'private') {
        events.add(event);
      }
    }

    createAndSetZoomLevels(events, "events");
  }

  changeAllCitiesAndCreateCityNames() {
    var stadtInfoUser = Hive.box("secureBox").get("stadtinfoUser") ?? [];
    var newAllCities = [];
    var allCityUserInformation = <String>{};

    for (var userInfo in stadtInfoUser) {
      allCityUserInformation.add(userInfo["ort"]);
    }

    for (var city in allCities) {
      var hasCityUserInfo = false;
      var condition = city["isCity"] == 1 &&
          (city["kosten"] != null ||
              city["wetter"] != null ||
              city["internet"] != null ||
              city["familien"].isNotEmpty &&
                  (city["familien"].length == 1 &&
                      !city["familien"].contains(userId)));

      for (var cityUser in allCityUserInformation) {
        if (city["ort"].contains(cityUser)) {
          hasCityUserInfo = true;
          break;
        }
      }

      if (condition || hasCityUserInfo) {
        newAllCities.add(city);
      }
      if(city["isCity"] == 1) allCitiesNames.add(city["ort"]);
    }

    allCities = newAllCities;
  }

  removeProfilsAndCreateAllUserName() {
    var removeProfils = [];

    for (var profil in profils) {
      profil["lastLogin"] = profil["lastLogin"] ?? DateTime.parse("2022-02-13");
      var timeDifference = Duration(
          microseconds: (DateTime
              .now()
              .microsecondsSinceEpoch -
              DateTime
                  .parse(profil["lastLogin"].toString())
                  .microsecondsSinceEpoch)
              .abs());
      var monthDifference = timeDifference.inDays / 30.44;

      if (profil["id"] == userId ||
          ownProfil["geblocktVon"].contains(profil["id"]) ||
          monthDifference >= monthsUntilInactive ||
          profil["land"].isEmpty) {
        removeProfils.add(profil);
      } else {
        if (profil["family"] != null && profil["family"]["status"] == "main") {
          allUserName.add(profil["family"]["name"]);
        }
        allUserName.add(profil["name"]);
      }
    }

    for (var profil in removeProfils) {
      profils.remove(profil);
    }
  }

  changeProfilToFamilyProfil() {
    var deleteProfils = [];

    for (var familyProfil in familyProfils) {
      if (familyProfil["active"] == 0 ||
          familyProfil["name"].isEmpty ||
          familyProfil["mainProfil"].isEmpty) continue;

      var members = familyProfil["members"];
      var membersFound = 0;
      var familyName = (spracheIstDeutsch ? "Familie:" : "family") + " " +
          familyProfil["name"];
      for (var i = 0; i < profils.length; i++) {
        if (profils[i]["id"] == familyProfil["mainProfil"]) {
          membersFound += 1;
          profils[i]["family"] = {
            "name": familyName,
            "status": "main"
          };
        } else if (members.contains(profils[i]["id"])) {
          membersFound += 1;
          profils[i]["family"] = {
            "name": familyName,
            "status": "member"
          };
        }
        if (membersFound == members.length) break;
      }
    }

    for (var profil in deleteProfils) {
      profils.remove(profil);
    }
  }

  sortProfils(profils) {
    var allCountries = LocationService().getAllCountryNames();
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


      int compareCountry = profilBLand.compareTo(profilALand) as int;

      if (compareCountry == 0) return a["ort"].compareTo(b["ort"]) as int;

      return compareCountry;
    });

    return profils;
  }

  setSearchAutocomplete() {
    var countryList =
    spracheIstDeutsch ? countriesList["ger"] : countriesList["eng"];

    changeAllCitiesAndCreateCityNames();

    searchAutocomplete = SearchAutocomplete(
        searchableItems:
        allUserName.toList() + countryList + allCitiesNames,
        onConfirm: () {
          filterList = searchAutocomplete.getSelected();
          friendMarkerOn = false;
          eventMarkerOn = false;
          reiseplanungOn = false;
          filterOn = false;

          filterProfils();
          popupActive = true;
          createPopupProfils(profils);
        },
        onRemove: () {
          filterList = [];
          friendMarkerOn = false;
          eventMarkerOn = false;
          reiseplanungOn = false;
          filterOn = false;
          popupActive = false;
          filterProfils();
        });
  }

  filterProfils() {
    var filterProfils = [];

    if (filterList.isEmpty) {
      filterProfils = profilsBackup;
    } else {
      for (var profilGroup in aktiveProfils ?? []) {
        for (var profil in profilGroup["profils"]) {
          if (checkIfInFilter(profil)) {
            filterProfils.add(profil);
          } else {
            for (var family in familyProfils) {
              var familyName = (spracheIstDeutsch ? "Familie:" : "family") +
                  " " + family["name"];
              if (family["mainProfil"] == profil["id"] &&
                  filterList.contains(familyName)) {
                var familyProfil = Map.from(profil);
                familyProfil["name"] = familyName;
                filterProfils.add(familyProfil);
              }
            }
          }
        }
      }
    }


    setState(() {
      profils = filterProfils;
      createAndSetZoomLevels(profils, "profils");
    });
  }

  checkIfInFilter(profil) {
    var profilInteressen = profil["interessen"];
    var profilReiseart = profil["reiseart"];
    var profilSprachen = profil["sprachen"];
    var profilName = profil["name"];
    var profilLand = profil["land"];
    var profilOrt = profil["ort"];
    var profilKinder = profil["kinder"];
    var profilKinderYear = [];

    for (var kind in profilKinder) {
      profilKinderYear
          .add(global_functions.ChangeTimeStamp(kind).intoYears().toString());
    }

    if (filterList.isEmpty) return true;

    var spracheMatch = checkMatch(filterList, profilSprachen,
        global_var.sprachenListe + global_var.sprachenListeEnglisch);
    var reiseartMatch = checkMatch(filterList, [profilReiseart],
        global_var.reisearten + global_var.reiseartenEnglisch);
    var interesseMatch = checkMatch(filterList, profilInteressen,
        global_var.interessenListe + global_var.interessenListeEnglisch);
    var userMatch =
    checkMatch(filterList, [profilName], allUserName, simpleSearch: true);
    var countryMatch = checkMatch(
        filterList, [profilLand], countriesList["ger"] + countriesList["eng"]);
    var cityMatch = checkMatch(filterList, [profilOrt], allCitiesNames);
    var kinderMatch = checkMatch(filterList, profilKinderYear,
        List.generate(18, (i) => (i + 1).toString()),
        simpleSearch: true);

    if (spracheMatch &&
        reiseartMatch &&
        interesseMatch &&
        userMatch &&
        countryMatch &&
        cityMatch &&
        kinderMatch) return true;

    return false;
  }

  checkMatch(List selected, List checkList, globalList,
      {simpleSearch = false}) {
    bool globalMatch = false;
    bool match = false;

    for (var select in selected) {
      if (globalList.contains(select)) globalMatch = true;

      if (checkList.contains(select)) match = true;

      if (simpleSearch) continue;

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

  createAndSetZoomLevels(mainList, typ) async {
    var pufferCities = [];
    var pufferBetween = [];
    var pufferCountries = [];
    var pufferContinents = [];
    var pufferExact = [];

    if (typ == "profils") addCityProfils();

    for (var mainItem in mainList) {
      if (mainItem["family"] != null && typ == "profils") {
        if (mainItem["family"]["status"] == "main") {
          mainItem["name"] = mainItem["family"]["name"];
        } else {
          continue;
        }
      }

      pufferCountries =
      await createCountriesZoomLevel(pufferCountries, mainItem);
      pufferContinents =
      await createContinentsZoomLevel(pufferContinents, mainItem);
      pufferBetween = createBetweenZoomLevel(pufferBetween, mainItem, 1);

      pufferCities = createCitiesZoomLevel(pufferCities, mainItem);
      if (typ == "profils") {
        pufferExact =
            createCitiesZoomLevel(pufferExact, mainItem, exactLocation: true);
      }
    }

    if (typ == "profils") {
      profilsCities = pufferCities;
      profilsBetween = pufferBetween;
      profilsCountries = pufferCountries;
      profilsContinents = pufferContinents;
      profilsExact = pufferExact;
    } else if (typ == "events") {
      eventsCities = pufferCities;
      eventsBetween = pufferBetween;
      eventsCountries = pufferCountries;
      eventsKontinente = pufferContinents;
    } else if (typ == "communities") {
      communitiesCities = pufferCities;
      communitiesBetween = pufferBetween;
      communitiesCountries = pufferCountries;
      communitiesContinents = pufferContinents;
    }

    changeProfil(currentMapZoom);
  }

  addCityProfils() {
    if (filterList.isEmpty) {
      profils = allCities + profils;
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

  createBetweenZoomLevel(list, profil, abstand) {
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

  createCitiesZoomLevel(list, profil, {exactLocation = false}) {
    var newCity = true;

    if (exactLocation && !checkGenauerStandortPrivacy(profil)) return list;

    for (var i = 0; i < list.length; i++) {
      double profilLongt = profil["longt"];
      double profilLatt = profil["latt"];

      var geodataCondition =
          profilLongt == list[i]["longt"] && profilLatt == list[i]["latt"];
      var sameCityCondition = list[i]["ort"] == null
          ? false
          : list[i]["ort"].contains(profil["ort"]);

      if (geodataCondition || (sameCityCondition && !exactLocation)) {
        newCity = false;
        var addNumberName =
            int.parse(list[i]["name"]) + (profil["name"] == null ? 0 : 1);

        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (newCity) {
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

  checkGenauerStandortPrivacy(profil) {
    bool genauerStandortIsActiv =
        profil["automaticLocation"] == "genauer Standort" ||
            profil["automaticLocation"] == "exact location";

    if (!genauerStandortIsActiv) return true;

    var iamFollower = ownProfil["friendlist"].contains(profil["id"]);
    var followsMe = profil["friendlist"].contains(ownProfil["id"]);

    var allCondition = profil["genauerStandortPrivacy"] == "Alle" ||
        profil["genauerStandortPrivacy"] == "all";
    var follwerCondition = profil["genauerStandortPrivacy"] == "Follower" ||
        profil["genauerStandortPrivacy"] == "follower";
    var friendCondition = profil["genauerStandortPrivacy"] == "Freunde" ||
        profil["genauerStandortPrivacy"] == "friends";

    var accessCondition = allCondition ||
        (follwerCondition && iamFollower) ||
        (friendCondition && iamFollower && followsMe);

    if (accessCondition) return true;

    return false;
  }

  createCountriesZoomLevel(list, profil) {
    var checkNewCountry = true;

    for (var i = 0; i < list.length; i++) {
      var listCountryLocation =
      LocationService().getCountryLocation(list[i]["countryname"]);
      var profilCountryLocation =
      LocationService().getCountryLocation(profil["land"]);

      if (profilCountryLocation == null) {
        checkNewCountry = false;
        continue;
      }

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

  createContinentsZoomLevel(list, profil) {
    var newPoint = true;

    var landGedataProfil = LocationService().getCountryLocation(profil["land"]);
    if (landGedataProfil == null) return list;

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

  changeProfil(zoom) {
    var choosenProfils = [];
    var selectedEventList = [];
    var selectedComunityList = [];

    if (zoom > exactZoom) {
      choosenProfils = profilsExact;
      selectedEventList = eventsCities;
      selectedComunityList = communitiesCities;
    } else if (zoom > cityZoom) {
      choosenProfils = profilsCities;
      selectedEventList = eventsCities;
      selectedComunityList = communitiesCities;
    } else if (zoom > countryZoom) {
      choosenProfils = profilsBetween;
      selectedEventList = eventsBetween;
      selectedComunityList = communitiesBetween;
    } else if (zoom > kontinentZoom) {
      choosenProfils = profilsCountries;
      selectedEventList = eventsCountries;
      selectedComunityList = communitiesCountries;
    } else {
      choosenProfils = profilsContinents;
      selectedEventList = eventsKontinente;
      selectedComunityList = communitiesContinents;
    }


    if (mounted) {
      setState(() {
        aktiveProfils = choosenProfils ?? [];
        aktiveEvents = selectedEventList ?? [];
        aktiveCommunities = selectedComunityList ?? [];
      });
    }
  }

  zoomOut() {
    double newZoom;

    if (currentMapZoom > cityZoom) {
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

  openSelectReiseplanungsDateWindow() {
    var datePicker = FlexibleDatePicker(
      startYear: DateTime
          .now()
          .year,
      withMonth: true,
      multiDate: true,
      withEndDateSwitch: true,
      inaccurateDate: true,
    );

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: "",
            children: [
              Container(
                  margin: const EdgeInsets.all(20),
                  child: Text(
                    AppLocalizations
                        .of(context)
                        .weltkarteReiseplanungSuchen,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  )),
              const SizedBox(height: 10),
              datePicker,
              Container(
                margin: const EdgeInsets.all(30),
                child: FloatingActionButton.extended(
                    onPressed: () {
                      var selectedDate = datePicker.getDate();

                      if (selectedDate == null) {
                        customSnackbar(context, AppLocalizations
                            .of(context)
                            .datumEingeben);
                        return;
                      }

                      if (selectedDate.runtimeType == DateTime) {
                        selectedDate = [selectedDate, null];
                      } else {
                        if (selectedDate[1].isBefore(selectedDate[0])) {
                          customSnackbar(context, AppLocalizations
                              .of(context)
                              .bisDatumFalsch);
                          return;
                        }
                      }

                      setLookForReiseplanung(selectedDate[0], selectedDate[1]);

                      Navigator.pop(context);
                    },
                    label: Text(AppLocalizations
                        .of(context)
                        .anzeigen)),
              )
            ],
          );
        });
  }

  setLookForReiseplanung(von, bis) {
    reiseplanungOn = true;
    eventMarkerOn = false;
    friendMarkerOn = false;
    communityMarkerOn = false;
    filterOn = false;
    filterList = [];

    showReiseplaungMatchedProfils(
        von, bis);
  }

  showReiseplaungMatchedProfils(von, bis) {
    von = DateTime(von.year, von.month, von.day);
    bis = bis ?? von;
    var selectDates = [von];
    Set<Map> selectedProfils = <Map>{};

    while (von != bis) {
      von = DateTime(von.year, von.month + 1, von.day);
      selectDates.add(von);
    }

    for (var profil in profils) {
      var reiseplanung = profil["reisePlanung"];
      bool hasFixedLocation = profil["reiseart"] == global_var.reisearten[0]
          || profil["reiseart"] == global_var.reiseartenEnglisch[0];

      if(profil["id"] == userId) continue;
      if(hasFixedLocation){
        selectedProfils.add(profil);
        continue;
      }
      if(reiseplanung == null) continue;

      for (var planung in reiseplanung) {
        var planungVon = DateTime.parse(planung["von"]);
        var planungBis = DateTime.parse(planung["bis"]);

        if (selectDates.contains(planungVon)) {
          var newProfil = Map.of(profil);
          newProfil["ort"] = planung["ortData"]["city"];
          newProfil["land"] = planung["ortData"]["countryname"];
          newProfil["latt"] = planung["ortData"]["latt"];
          newProfil["longt"] = planung["ortData"]["longt"];

          selectedProfils.add(newProfil);
          continue;
        }

        while (planungVon != planungBis) {
          planungVon =
              DateTime(planungVon.year, planungVon.month + 1, planungVon.day);
          if (selectDates.contains(planungVon)) {
            var newProfil = Map.of(profil);
            newProfil["ort"] = planung["ortData"]["city"];
            newProfil["land"] = planung["ortData"]["countryname"];
            newProfil["latt"] = planung["ortData"]["latt"];
            newProfil["longt"] = planung["ortData"]["longt"];

            selectedProfils.add(newProfil);
            break;
          }
        }
      }
    }

    profils = selectedProfils.toList();
    createAndSetZoomLevels(profils, "profils");
  }

  openFilterWindow() async {
    var sprachenSelection = spracheIstDeutsch
        ? global_var.sprachenListe
        : global_var.sprachenListeEnglisch;
    var interessenSelection = spracheIstDeutsch
        ? global_var.interessenListe
        : global_var.interessenListeEnglisch;
    var reiseartSelection = spracheIstDeutsch
        ? global_var.reisearten
        : global_var.reiseartenEnglisch;
    var alterKinderSelection =
    List<String>.generate(18, (i) => (i + 1).toString());

    await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, windowSetState) {
            return CustomAlertDialog(
              title: "",
              children: [
                createCheckBoxen(windowSetState, reiseartSelection,
                    AppLocalizations
                        .of(context)
                        .reisearten),
                createCheckBoxen(windowSetState, alterKinderSelection,
                    AppLocalizations
                        .of(context)
                        .alterDerKinder),
                createCheckBoxen(windowSetState, interessenSelection,
                    AppLocalizations
                        .of(context)
                        .interessen),
                createCheckBoxen(windowSetState, sprachenSelection,
                    AppLocalizations
                        .of(context)
                        .sprachen),
              ],
            );
          });
        });

    if (filterList.isNotEmpty) {
      filterOn = true;
      popupActive = true;
      createPopupProfils(profils, spezialActivation: true);
    } else {
      filterOn = false;
      popupActive = false;
    }

    setState(() {});
  }

  createCheckBoxen(windowSetState, selectionList, title) {
    List<Widget> checkBoxWidget = [];

    for (var selection in selectionList) {
      var widthFactor = 0.5;

      if (selection.length < 3) widthFactor = 0.2;

      checkBoxWidget.add(FractionallySizedBox(
        widthFactor: widthFactor,
        child: Row(
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: Checkbox(
                  value: filterList.contains(selection),
                  onChanged: (newValue) {
                    if (newValue == true) {
                      filterList.add(selection);
                    } else {
                      filterList.remove(selection);
                    }
                    windowSetState(() {});

                    friendMarkerOn = false;
                    eventMarkerOn = false;
                    reiseplanungOn = false;
                    communityMarkerOn = false;

                    filterProfils();
                  }),
            ),
            Expanded(
                child: InkWell(
                  onTap: () => changeCheckboxState(selection, windowSetState),
                  child: Text(
                    selection,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                  ),
                ))
          ],
        ),
      ));
    }

    return Column(
      children: [
        Text(title),
        const SizedBox(height: 5),
        Wrap(children: [...checkBoxWidget]),
        const SizedBox(height: 10)
      ],
    );
  }

  changeCheckboxState(selection, windowSetState) {
    if (filterList.contains(selection)) {
      filterList.remove(selection);
    } else {
      filterList.add(selection);
    }
    windowSetState(() {});
  }

  createPopupProfils(profils, {spezialActivation = false}) {
    popupItems = [];
    popupTyp = "profils";
    var selectUserProfils = [];

    for (var profil in profils) {
      if (profil["name"] != null) selectUserProfils.add(profil);
    }

    popupItems.add(SliverAppBar(
      toolbarHeight: kIsWeb ? 60 : 50,
      backgroundColor: Colors.white,
      flexibleSpace: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
        child: Text(selectPopupMenuText(profils, spezialActivation),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
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

    changeTextLength(string) {
      if (string.length > 40) {
        return string.replaceRange(20, string.length, '...');
      }

      return string;
    }

    popupItems.add(SliverFixedExtentList(
      itemExtent: 90,
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        var profilData = selectUserProfils[index];
        var genauerStandortKondition = profilData["automaticLocation"] ==
            global_var.standortbestimmung[1] ||
            profilData["automaticLocation"] ==
                global_var.standortbestimmungEnglisch[1] &&
                checkGenauerStandortPrivacy(profilData);

        return GestureDetector(
          onTap: () {
            global_functions.changePage(
                context,
                ShowProfilPage(profil: profilData,));
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
                        Text(
                            childrenAgeStringToStringAge(profilData["kinder"])),
                        const SizedBox(height: 5),
                        genauerStandortKondition
                            ? Text("📍 " +
                            changeTextLength(profilData["ort"]) +
                            ", " +
                            changeTextLength(profilData["land"]))
                            : Text(changeTextLength(profilData["ort"]) +
                            ", " +
                            changeTextLength(profilData["land"]))
                      ])
                ],
              )),
        );
      }, childCount: selectUserProfils.length),
    ));

    return popupItems;
  }

  selectPopupMenuText(profils, spezialActivation) {
    if (spezialActivation) {
      if (friendMarkerOn) return AppLocalizations
          .of(context)
          .freundesListe;
      if (filterOn) return AppLocalizations
          .of(context)
          .filterErgebnisse;
      if (eventMarkerOn) return AppLocalizations
          .of(context)
          .neueMeetups;
      if (communityMarkerOn) {
        return AppLocalizations
            .of(context)
            .neueCommunities;
      }
    }

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

  createPopupWindowTitle(list, filter) {
    Set<String> titleList = {};

    if (filter == "kontinente") {
      var locationData = LocationService().getCountryLocation(list[0]["land"]);
      if (locationData["kontinentGer"] == locationData["kontinentEng"]) {
        return locationData["kontinentEng"];
      }
      return locationData["kontinentGer"] +
          " / " +
          locationData["kontinentEng"];
    } else if (filter == "stadt") {
      return list[0]["ort"] ?? list[0]["stadt"];
    }

    for (var item in list) {
      if (!titleList.contains(item[filter])) titleList.add(item[filter]);
    }

    return titleList.join(" / ");
  }

  activateFriendlistProfils(changeList) {
    var newProfilList = [];

    for (var profilId in changeList) {
      for (var profil in Hive.box('secureBox').get("profils") ?? []) {
        if (profilId == profil["id"]) {
          newProfilList.add(profil);
          break;
        }
      }
    }
    profils = newProfilList;
    createAndSetZoomLevels(profils, "profils");
  }

  setProfilsFromHive() {
    var hiveProfils = Hive.box('secureBox').get("profils") ?? [];
    profils = [for (var profil in hiveProfils) Map.of(profil)];
    removeProfilsAndCreateAllUserName();
    changeProfilToFamilyProfil();
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> allMarker = [];
    searchAutocomplete.hintText = AppLocalizations
        .of(context)
        .filterErkunden;

    createPopupCards({event, community, spezialActivation = false}) {
      double screenWidth = MediaQuery
          .of(context)
          .size
          .width;
      var crossAxisCount = screenWidth / 250;
      popupItems = [];
      popupTyp = event != null ? "events" : "community";
      var showItems = event ?? community;

      popupItems.add(SliverAppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.white,
        flexibleSpace: Center(
            child: Text(
                selectPopupMenuText(showItems["profils"], spezialActivation),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
        pinned: true,
      ));

      popupItems.add(SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount.round(),
            childAspectRatio: 0.75,
          ),
          delegate:
          SliverChildBuilderDelegate((BuildContext context, int index) {
            var itemData = showItems["profils"][index];

            if (event != null) {
              return MeetupCard(
                  margin: const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 10),
                  meetupData: itemData,
                  withInteresse: true,
                  afterPageVisit: () async {
                    events = await MeetupDatabase().getData("*",
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
                    createPopupCards(event: lastEventPopup);
                    setState(() {});
                  });
            } else {
              return CommunityCard(
                community: itemData,
                margin: const EdgeInsets.only(
                    top: 15, bottom: 15, left: 25, right: 25),
                withFavorite: true,
              );
            }
          }, childCount: showItems["profils"].length)));

      return popupItems;
    }

    Widget worldChatButton(){
      return FloatingActionButton(
          heroTag: "worldchat",
          child: const Icon(Icons.message),
          onPressed: () =>
              global_functions.changePage(
                  context, ChatDetailsPage(
                chatId: "1",
                isChatgroup: true,
              )));
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
                minChildSize: 0.27,
                maxChildSize: 0.83,
                builder: (context, controller) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 130),
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
                        top: 130,
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
                      Positioned(
                          top: 60, right: 10, child: worldChatButton())
                    ],
                  );
                }),
          ));
    }

    createOwnMarker() {
      double lattShift = 0.002;
      double longtShift = 0.001;

      if (currentMapZoom > countryZoom && currentMapZoom < cityZoom) {
        lattShift = 0.4;
        longtShift = 0.2;
      } else if (currentMapZoom > cityZoom && currentMapZoom < 10) {
        lattShift = 0.07;
        longtShift = 0.02;
      } else if (currentMapZoom > 10 && currentMapZoom < 12.5) {
        lattShift = 0.02;
        longtShift = 0.01;
      }

      if (ownProfil != null) {
        allMarker.add(Marker(
            width: 30.0,
            height: 30.0,
            point: LatLng(
                ownProfil["latt"] + lattShift, ownProfil["longt"] + longtShift),
            // 0.07 => 0.02
            builder: (_) =>
                Icon(
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
          builder: (ctx) =>
              FloatingActionButton(
                  heroTag: "MapMarker" + position.toString(),
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  mini: true,
                  child: Center(child: Text(numberText)),
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
          setState(() {});
        }));
      }
    }

    Marker eventMarker(numberText, position, buttonFunction, isOnline) {
      double markerSize = 32;

      return Marker(
        width: markerSize,
        height: markerSize,
        point: position,
        builder: (ctx) =>
            IconButton(
              padding: EdgeInsets.zero,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.calendar_today,
                      size: markerSize,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary),
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
                                      color: Colors.black))))),
                  if (isOnline)
                    Positioned(
                        top: -20,
                        left: 4,
                        child: Icon(
                          Icons.wifi,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ))
                ],
              ),
              onPressed: buttonFunction,
            ),
      );
    }

    createEventMarker() {
      for (var event in aktiveEvents) {
        bool isOnline = event["profils"][0]["typ"] == global_var.meetupTyp[1] ||
            event["profils"][0]["typ"] == global_var.meetupTypEnglisch[1];
        var position = LatLng(event["latt"], event["longt"]);

        allMarker.add(eventMarker(event["name"], position, () {
          lastEventPopup = event;
          popupActive = true;
          createPopupCards(event: event);
          setState(() {});
        }, isOnline));
      }
    }

    communityMarker(numberText, position, buttonFunction) {
      double markerSize = 32;

      return Marker(
        width: markerSize,
        height: markerSize,
        point: position,
        builder: (ctx) =>
            IconButton(
              padding: EdgeInsets.zero,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.cottage_outlined,
                      size: markerSize,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary),
                  Positioned(
                      top: 8,
                      left: 8.5,
                      child: Container(
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(left: 1),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(9.0),
                                  topRight: Radius.circular(9.0))),
                          width: 15,
                          height: 18,
                          child: Text(numberText,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black
                              )
                          )
                      )
                  ),
                ],
              ),
              onPressed: buttonFunction,
            ),
      );
    }

    createCommunityMarker() {
      for (var community in aktiveCommunities) {
        var position = LatLng(community["latt"], community["longt"]);

        allMarker.add(communityMarker(community["name"], position, () {
          popupActive = true;
          createPopupCards(community: community);
          setState(() {});
        }));
      }
    }

    createAllMarker() async {
      createOwnMarker();
      if (!eventMarkerOn && !communityMarkerOn) createProfilMarker();
      if (eventMarkerOn) createEventMarker();
      if (communityMarkerOn) createCommunityMarker();
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
            mapPosition = position.center;
            FocusScope.of(context).unfocus();
            if (currentMapZoom != position.zoom) {
              mapController.move(mapPosition, position.zoom);
              currentMapZoom = position.zoom;
              changeProfil(currentMapZoom);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: allMarker,
          )
        ],
      );
    }

    friendButton() {
      return Positioned(
          right: 5,
          top: 65,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Stack(
              children: [
                if (!friendMarkerOn)
                  Icon(Icons.favorite_outline,
                      size: 32, color: Theme
                          .of(context)
                          .colorScheme
                          .primary),
                if (friendMarkerOn)
                  Icon(Icons.favorite,
                      size: 32, color: Theme
                          .of(context)
                          .colorScheme
                          .primary)
              ],
            ),
            onPressed: () {
              if (friendMarkerOn) {
                friendMarkerOn = false;
                popupActive = false;
                setProfilsFromHive();
                createAndSetZoomLevels(profils, "profils");
              } else {
                friendMarkerOn = true;
                eventMarkerOn = false;
                reiseplanungOn = false;
                communityMarkerOn = false;
                filterOn = false;
                filterList = [];

                activateFriendlistProfils(ownProfil["friendlist"]);

                popupActive = true;
                createPopupProfils(profils, spezialActivation: true);
              }

              setState(() {});
            },
          ));
    }

    eventButton() {
      var newEvents = [];
      var lastLoginEvents = Hive.box('secureBox').get("lastLoginEvents") ?? [];

      for (var event in events) {
        var isNew = true;

        for (var oldEvent in lastLoginEvents) {
          if (event["name"] == oldEvent["name"] &&
              event["erstelltAm"] == oldEvent["erstelltAm"] &&
              event["erstelltVon"] == oldEvent["erstelltVon"]) {
            isNew = false;
          }
        }

        if (isNew) newEvents.add(event);
      }

      return Positioned(
          right: 50,
          top: 65,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Stack(
              children: [
                if (!eventMarkerOn)
                  BadgeIcon(
                    icon: Icons.calendar_today_outlined,
                    size: 32,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                    text: newEvents.isEmpty ? "" : newEvents.length.toString(),
                  ),
                if (eventMarkerOn)
                  Icon(Icons.event_busy,
                      size: 36, color: Theme
                          .of(context)
                          .colorScheme
                          .primary)
              ],
            ),
            onPressed: () {
              if (eventMarkerOn) {
                eventMarkerOn = false;
                popupActive = false;
              } else {
                eventMarkerOn = true;
                friendMarkerOn = false;
                reiseplanungOn = false;
                communityMarkerOn = false;
                filterOn = false;
                filterList = [];
                popupActive = false;

                if (newEvents.isNotEmpty) {
                  popupActive = true;
                  createPopupCards(
                      event: {"profils": newEvents}, spezialActivation: true);
                  Hive.box('secureBox').put("lastLoginEvents", events);
                }
              }

              setState(() {});
            },
          ));
    }

    communityButton() {
      var newCommunity = [];
      var lastLoginCommunites =
          Hive.box('secureBox').get("lastLoginCommunity") ?? [];

      for (var community in communities) {
        var isNew = true;

        for (var oldCommunity in lastLoginCommunites) {
          if (community["name"] == oldCommunity["name"] &&
              community["erstelltAm"] == oldCommunity["erstelltAm"] &&
              community["erstelltVon"] == oldCommunity["erstelltVon"]) {
            isNew = false;
          }
        }

        if (isNew) newCommunity.add(community);
      }

      return Positioned(
          right: 100,
          top: 65,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Stack(
              children: [
                if (!communityMarkerOn)
                  BadgeIcon(
                    icon: Icons.cottage_outlined,
                    size: 36,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                    text: newCommunity.isEmpty
                        ? ""
                        : newCommunity.length.toString(),
                  ),
                if (communityMarkerOn)
                  Icon(Icons.cottage,
                      size: 36, color: Theme
                          .of(context)
                          .colorScheme
                          .primary)
              ],
            ),
            onPressed: () {
              if (communityMarkerOn) {
                communityMarkerOn = false;
                popupActive = false;
              } else {
                communityMarkerOn = true;
                eventMarkerOn = false;
                friendMarkerOn = false;
                reiseplanungOn = false;
                filterOn = false;
                filterList = [];
                popupActive = false;

                if (newCommunity.isNotEmpty) {
                  popupActive = true;
                  createPopupCards(
                      community: {"profils": newCommunity},
                      spezialActivation: true);
                  Hive.box('secureBox').put("lastLoginCommunity", communities);
                }
              }

              setState(() {});
            },
          ));
    }

    reiseplanungButton() {
      return Positioned(
          right: 150,
          top: 65,
          child: IconButton(
              padding: EdgeInsets.zero,
              icon: reiseplanungOn
                  ? Icon(Icons.update_disabled,
                  size: 32, color: Theme
                      .of(context)
                      .colorScheme
                      .primary)
                  : Icon(Icons.update,
                  size: 36, color: Theme
                      .of(context)
                      .colorScheme
                      .primary),
              onPressed: () {
                if (reiseplanungOn) {
                  reiseplanungOn = false;
                  setProfilsFromHive();
                  createAndSetZoomLevels(profils, "profils");
                } else {
                  openSelectReiseplanungsDateWindow();
                }
              }));
    }

    filterButton() {
      return Positioned(
          right: 195,
          top: 65,
          child: IconButton(
              padding: EdgeInsets.zero,
              icon: filterOn
                  ? Icon(Icons.filter_list_off,
                  size: 32, color: Theme
                      .of(context)
                      .colorScheme
                      .primary)
                  : Icon(Icons.filter_list,
                  size: 34, color: Theme
                      .of(context)
                      .colorScheme
                      .primary),
              onPressed: () {
                openFilterWindow();
              }));
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ownFlutterMap(),
          searchAutocomplete,
          if (popupActive) markerPopupContainer(),
          friendButton(),
          eventButton(),
          communityButton(),
          reiseplanungButton(),
          filterButton()
        ]),
      ),
      floatingActionButton: popupActive ? null : worldChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
