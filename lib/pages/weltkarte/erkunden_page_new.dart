import 'dart:async';
import 'dart:ui';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:familien_suche/l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:uuid/uuid.dart';

import '../../functions/user_speaks_german.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../global/profil_sprachen.dart';
import '../../global/variablen.dart' as global_var;
import '../../global/style.dart' as style;
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/ownIconButton.dart';
import '../../widgets/profil_image.dart';
import '../../widgets/search_autocomplete.dart';
import '../../widgets/flexible_date_picker.dart';
import '../../services/database.dart';
import '../../services/locationsService.dart';
import '../../windows/dialog_window.dart';
import '../chat/chat_details.dart';
import '../informationen/community/community_card.dart';
import '../informationen/location/location_details/information_main.dart';
import '../informationen/meetups/meetup_card.dart';
import '../show_profil.dart';

class ErkundenPage extends StatefulWidget {
  const ErkundenPage({Key? key}) : super(key: key);

  @override
  State<ErkundenPage> createState() => _ErkundenPageState();
}

class _ErkundenPageState extends State<ErkundenPage> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  List profils = [];
  List profilsBackup = [];
  var ownProfil = Hive.box('secureBox').get("ownProfil") ?? {};
  List allCities = Hive.box('secureBox').get("stadtinfo") ?? [];
  List events = [];
  List communities = Hive.box('secureBox').get("communities") ?? [];
  List insiderInfos = [];
  List familyProfils = Hive.box('secureBox').get("familyProfils") ?? [];
  final Completer<GoogleMapController> mapController = Completer<GoogleMapController>();
  Set<String> allUserName = {};
  var countriesList = LocationService().getAllCountryNames();
  List<String> allCitiesNames = [];
  List filterList = [];
  List aktiveLocationData = [];
  List aktiveEvents = [];
  List aktiveCommunities = [];
  List aktiveInsiderInfos = [];
  Map profilLevels = {
    "continents": [],
    "countries": [],
    "between": [],
    "cities": [],
    "exact": []
  };
  Map meetupLevels = {
    "continents": [],
    "countries": [],
    "between": [],
    "cities": [],
    "exact": []
  };
  Map communityLevels = {
    "continents": [],
    "countries": [],
    "between": [],
    "cities": [],
    "exact": []
  };
  Map insiderInfoLevels = {
    "continents": [],
    "countries": [],
    "between": [],
    "cities": [],
    "exact": []
  };
  List? insiderInfoContinents;
  double minZoom = kIsWeb ? 2.0 : 1.6;
  double maxZoom = 14;
  double currentZoom = 2.0;
  double exactZoom = 10;
  double cityZoom = 8.5;
  double countryZoom = 5.5;
  double kontinentZoom = 3.5;
  SearchAutocomplete searchAutocomplete = SearchAutocomplete(
    searchableItems: const [],
  );
  late LatLng mapPosition;
  List<Widget> popupItems = [];
  var monthsUntilInactive = 3;
  bool buildDone = false;
  bool friendMarkerOn = false,
      eventMarkerOn = false,
      reiseplanungOn = false,
      communityMarkerOn = false,
      insiderInfoOn = false,
      filterOn = false;
  var spracheIstDeutsch = kIsWeb
      ? PlatformDispatcher.instance.locale.languageCode == "de"
      : Platform.localeName == "de_DE";
  var hiveProfils = List.of(Hive.box('secureBox').get("profils") ?? []);
  bool systemIsGerman =
      WidgetsBinding.instance.platformDispatcher.locales[0].languageCode == "de";
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    profils = [for (var profil in hiveProfils) Map.of(profil)];
    changeProfilToFamilyProfil();
    removeProfilsAndCreateAllUserName();
    sortProfils(profils);

    createAndSetZoomLevels(profils, "profils");

    createOwnMarker();

    WidgetsBinding.instance.addPostFrameCallback((_) => afterInit());

  }

  removeProfilsAndCreateAllUserName() {
    var removeProfils = [];

    for (var profil in profils + hiveProfils) {
      profil["lastLogin"] = profil["lastLogin"] ?? DateTime.parse("2022-02-13");
      var timeDifference = Duration(
          microseconds: (DateTime.now().microsecondsSinceEpoch -
              DateTime.parse(profil["lastLogin"].toString())
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
    List removeProfils = [];

    for (var familyProfil in familyProfils) {
      bool isActive = familyProfil["active"] == 1;
      bool hasName = familyProfil["name"].isNotEmpty;
      bool hasMainProfil = familyProfil["mainProfil"].isNotEmpty;

      if (!isActive || !hasName || !hasMainProfil) continue;

      var members = familyProfil["members"];
      var membersFound = 0;
      var familyName =
          (spracheIstDeutsch ? "Familie: " : "family: ") + familyProfil["name"];

      for (var i = 0; i < profils.length; i++) {
        if (profils[i]["id"] == familyProfil["mainProfil"]) {
          membersFound += 1;
          profils[i]["name"] = familyName;
        } else if (members.contains(profils[i]["id"])) {
          membersFound += 1;
          removeProfils.add(profils[i]);
        }
        if (membersFound == members.length) break;
      }
    }

    for (var profil in removeProfils) {
      profils.removeWhere((element) => element["id"] == profil["id"]);
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


  afterInit() async {
    await createProfilMarker();

    setState(() {});
  }

  createOwnMarker(){
    double lattShift = 0.002;
    double longtShift = 0.001;

    if (currentZoom > countryZoom && currentZoom < cityZoom) {
      lattShift = 0.4;
      longtShift = 0.2;
    } else if (currentZoom > cityZoom && currentZoom < 10) {
      lattShift = 0.07;
      longtShift = 0.02;
    } else if (currentZoom > 10 && currentZoom < 12.5) {
      lattShift = 0.02;
      longtShift = 0.01;
    }

    if (ownProfil != null) {
      markers.add(
          Marker(
            markerId: MarkerId("ownPosition"),
            position: LatLng(ownProfil["latt"] + lattShift, ownProfil["longt"] + longtShift),
      ));
    }
  }

  createProfilMarker() async {
    var size = Size(150, 150);
    markers = {};

    for (var profil in aktiveLocationData) {
      if (friendMarkerOn && profil["name"] == "0") continue;

      var uuid = Uuid();
      String newId = uuid.v4();

      markers.add(
          Marker(
              markerId: MarkerId(newId),
              position: LatLng(profil["latt"], profil["longt"] ),
              icon: await TextOnImage(
                text: profil["name"],
              ).toBitmapDescriptor(
                  logicalSize: size, imageSize: size
              ),
              onTap: () {
                //bottomSheet(profils: profil["profils"]);
              }
          )
      );
    }



    setState(() {});
  }

  createAndSetZoomLevels(mainList, typ) {
    var pufferCities = [];
    var pufferBetween = [];
    var pufferCountries = [];
    var pufferContinents = [];
    var pufferExact = [];

    for (var mainItem in mainList) {
      pufferCountries = createCountriesZoomLevel(pufferCountries, mainItem);
      pufferContinents = createContinentsZoomLevel(pufferContinents, mainItem);
      pufferBetween = createBetweenZoomLevel(pufferBetween, mainItem);
      pufferCities = createCitiesZoomLevel(pufferCities, mainItem);
      if (typ == "profils") {
        pufferExact =
            createCitiesZoomLevel(pufferExact, mainItem, exactLocation: true);
      }
    }

    late Map typLevels;
    if (typ == "profils") {
      typLevels = profilLevels;
    } else if (typ == "events") {
      typLevels = meetupLevels;
    } else if (typ == "communities") {
      typLevels = communityLevels;
    } else if (typ == "insiderInfo") {
      typLevels = insiderInfoLevels;
    }

    typLevels["continents"] = pufferContinents;
    typLevels["countries"] = pufferCountries;
    typLevels["between"] = pufferBetween;
    typLevels["cities"] = pufferCities;
    typLevels["exact"] = pufferExact;

    changeProfil(currentZoom);
  }

  createCountriesZoomLevel(list, profil) {
    var checkNewCountry = true;

    for (var i = 0; i < list.length; i++) {
      if(profil["land"] == "Online") profil["land"] = "Weltweit";
      var listCountryLocation =
      LocationService().getCountryLocationData(list[i]["countryname"]);
      var profilCountryLocation =
      LocationService().getCountryLocationData(profil["land"]);

      if (profilCountryLocation == null) {
        checkNewCountry = false;
        continue;
      }

      if (listCountryLocation["latt"] == profilCountryLocation["latt"] &&
          listCountryLocation["longt"] == profilCountryLocation["longt"]) {
        checkNewCountry = false;
        var addNumberName = int.parse(list[i]["name"]) + 1;

        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (checkNewCountry) {
      var country = profil["land"];
      var position = LocationService().getCountryLocationData(country);
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

  createContinentsZoomLevel(list, profil) {
    var newPoint = true;

    var landGedataProfil = LocationService().getCountryLocationData(profil["land"]);
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

        var addNumberName = int.parse(list[i]["name"]) + 1;

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

  createBetweenZoomLevel(list, profil) {
    var abstand = 1;
    var newPoint = false;

    for (var i = 0; i < list.length; i++) {
      num originalLatt = profil["latt"];
      num newLatt = list[i]["latt"];
      num originalLongth = profil["longt"];
      num newLongth = list[i]["longt"];
      bool check = (newLatt + abstand >= originalLatt &&
          newLatt - abstand <= originalLatt) &&
          (newLongth + abstand >= originalLongth &&
              newLongth - abstand <= originalLongth);

      if (check) {
        newPoint = true;
        var numberName = int.parse(list[i]["name"]) + 1;

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

  createCitiesZoomLevel(list, profil, {exactLocation = false}) {
    var newCity = true;

    if (exactLocation && !checkGenauerStandortPrivacy(profil)) return list;

    for (var i = 0; i < list.length; i++) {
      int accuracyFactor = 100;
      num profilLongt = (profil["longt"] * accuracyFactor).round();
      num profilLatt = (profil["latt"] * accuracyFactor).round();

      var geodataCondition =
          profilLongt == (list[i]["longt"] * accuracyFactor).round() &&
              profilLatt == (list[i]["latt"] * accuracyFactor).round();
      var sameCityCondition = list[i]["ort"] == null
          ? false
          : list[i]["ort"].contains(profil["ort"]);

      if (geodataCondition || (sameCityCondition && !exactLocation)) {
        newCity = false;
        var addNumberName = int.parse(list[i]["name"]) + 1;

        list[i]["name"] = addNumberName.toString();
        list[i]["profils"].add(profil);
        break;
      }
    }

    if (newCity) {
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

  changeProfil(zoom) {
    var choosenProfils = [];
    var selectedEventList = [];
    var selectedComunityList = [];
    var selectedInsiderInfoList = [];

    if (zoom > exactZoom) {
      choosenProfils = profilLevels["exact"];
      selectedEventList = meetupLevels["cities"];
      selectedComunityList = communityLevels["cities"];
      selectedInsiderInfoList = insiderInfoLevels["cities"];
    } else if (zoom > cityZoom) {
      choosenProfils = profilLevels["cities"];
      selectedEventList = meetupLevels["cities"];
      selectedComunityList = communityLevels["cities"];
      selectedInsiderInfoList = insiderInfoLevels["cities"];
    } else if (zoom > countryZoom) {
      choosenProfils = profilLevels["between"];
      selectedEventList = meetupLevels["between"];
      selectedComunityList = communityLevels["between"];
      selectedInsiderInfoList = insiderInfoLevels["between"];
    } else if (zoom > kontinentZoom) {
      choosenProfils = profilLevels["countries"];
      selectedEventList = meetupLevels["countries"];
      selectedComunityList = communityLevels["countries"];
      selectedInsiderInfoList = insiderInfoLevels["countries"];
    } else {
      choosenProfils = profilLevels["continents"];
      selectedEventList = meetupLevels["continents"];
      selectedComunityList = communityLevels["continents"];
      selectedInsiderInfoList = insiderInfoLevels["continents"];
    }

    aktiveLocationData = choosenProfils;
    aktiveEvents = selectedEventList;
    aktiveCommunities = selectedComunityList;
    aktiveInsiderInfos = selectedInsiderInfoList;
  }


  void _onCameraMove(CameraPosition position) {

    if (position.zoom != currentZoom){
      currentZoom = position.zoom;

      changeProfil(currentZoom);
      createProfilMarker();

      setState(() {});
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
            GoogleMap(
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            mapToolbarEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(minZoom, maxZoom),
            initialCameraPosition: CameraPosition(
              target: const LatLng(25, 0),
              zoom: minZoom,
            ),
            markers: markers,
            onCameraMove: _onCameraMove,
            onMapCreated: (GoogleMapController controller) {
              mapController.complete(controller);
            }
          ),
          searchAutocomplete,
          Positioned.fill(
            bottom: 10,
            child: Align(
              alignment: Alignment.bottomCenter,
              child:Text(AppLocalizations.of(context)!.inaktiveKartenHinweis)
            )
          )
        ]),
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class TextOnImage extends StatelessWidget {
  const TextOnImage({
    super.key,
    required this.text,
  });
  final String text;
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
      ),
      Text(
        text,
        style: TextStyle(color: Colors.black, fontSize: 60, fontWeight: FontWeight.bold),
      )
    ]
    );
  }
}