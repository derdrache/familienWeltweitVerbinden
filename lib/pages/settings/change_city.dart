import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/locationsService.dart';
import '../../services/notification.dart' as notifications;
import '../../widgets/custom_appbar.dart';
import '../../widgets/google_autocomplete.dart';
import '../../services/database.dart';


import '../../widgets/layout/custom_snackbar.dart';

class ChangeLocationPage extends StatefulWidget {
  const ChangeLocationPage({Key? key}) : super(key: key);

  @override
  State<ChangeLocationPage> createState() => _ChangeLocationPageState();
}

class _ChangeLocationPageState extends State<ChangeLocationPage> {
  TextEditingController ortChangeKontroller = TextEditingController();
  List suggestedCities = [];
  List<Widget> suggestedCitiesList = [];
  int selectedIndex = -1;
  Map locationData = {};
  var autoComplete = GoogleAutoComplete();
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  bool selected = false;

  @override
  void initState() {
    autoComplete.onConfirm = () {
      if(selected) return;
      save();
      Navigator.pop(context);
    };

    super.initState();
  }

  joindAndRemoveChatGroups(locationDict, oldLocationDict) async {
    final Map leaveCity = getCityFromHive(cityName: oldLocationDict["city"], latt: oldLocationDict["latt"]) ?? {};
    final Map leaveCountry = getCityFromHive(cityName: oldLocationDict["countryname"], latt: oldLocationDict["latt"], isCountry: true) ?? {};

    ChatGroupsDatabase().joinAndCreateCityChat(locationDict["city"], locationDict["latt"]);
    if(locationDict["city"] != locationDict["countryname"]) ChatGroupsDatabase().joinAndCreateCityChat(locationDict["countryname"], locationDict["latt"], isCountry: true);

    ChatGroupsDatabase().leaveChat("</stadt=${leaveCity["id"]}");
    if(oldLocationDict["city"] != oldLocationDict["countryname"]) ChatGroupsDatabase().leaveChat("</stadt=${leaveCountry["id"]}");
  }

  addVisitedCountries(newCountry) async {
    List visitedCountries = ownProfil["besuchteLaender"];
    Map allCountries = LocationService().getAllCountryNames();
    String targetLanguage =
        getVisitedCountriesLanguage(visitedCountries, allCountries);
    int wrongLanguageIndex = targetLanguage == "ger"
        ? allCountries["eng"].indexOf(newCountry)
        : allCountries["ger"].indexOf(newCountry);

    if (wrongLanguageIndex > -1) {
      newCountry = allCountries["ger"][wrongLanguageIndex];
    }

    if (visitedCountries.contains(newCountry)) return;

    ownProfil["besuchteLaender"].add(newCountry);
    ProfilDatabase().updateProfil(
        "besuchteLaender = JSON_ARRAY_APPEND(besuchteLaender, '\$', '$newCountry')",
        "WHERE id = '${ownProfil["id"]}'");
  }

  getVisitedCountriesLanguage(visitedCountries, allCountries) {
    final bool isGermanDeviceLanguage = kIsWeb
        ? PlatformDispatcher.instance.locale.languageCode == "de"
        : Platform.localeName == "de_DE";
    String visitedCountriesLanguage = ownProfil["besuchteLaender"].isEmpty
        ? isGermanDeviceLanguage
            ? "ger"
            : "eng"
        : allCountries["ger"].contains(ownProfil["besuchteLaender"][0])
            ? "ger"
            : "eng";

    return visitedCountriesLanguage;
  }

  saveLocation(locationDict) async {
    ownProfil["ort"] = locationDict["city"];
    ownProfil["longt"] = locationDict["longt"];
    ownProfil["latt"] = locationDict["latt"];
    ownProfil["land"] = locationDict["countryname"];

    ProfilDatabase().updateProfilLocation(ownProfil["id"], locationDict);
  }

  deleteChangeCityNewsSameDay() async {
    var now = DateTime.now();
    var nextDay = DateTime(now.year, now.month, now.day + 1);
    var formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(now);
    String tomorrow = formatter.format(nextDay);
    String dateQuery =
        "erstelltAm >='$today 00:00:00' AND erstelltAm <'$tomorrow 00:00:00'";

    var getTodaysEntries = await NewsPageDatabase().getData("*",
        "WHERE erstelltVon = '${ownProfil["id"]}' AND typ = 'ortswechsel' AND $dateQuery",
        returnList: true);

    if (getTodaysEntries == false) return;

    for (var news in getTodaysEntries) {
      NewsPageDatabase().delete(news["id"]);
    }
  }

  saveNewsPage(locationDict) async {
    Map dbLocation = Map.of(locationDict);
    dbLocation["city"] = dbLocation["city"].replaceAll("'", "''");
    dbLocation["ort"] = dbLocation["ort"].replaceAll("'", "''");
    dbLocation["countryname"] = dbLocation["countryname"].replaceAll("'", "''");

    var newLocationNews = {
      "typ": "ortswechsel",
      "information": json.encode(dbLocation),
    };

    bool isSaved = await NewsPageDatabase().addNewNews(newLocationNews);
    if (!isSaved) return;

    var newsFeed = Hive.box("secureBox").get("newsFeed");
    newsFeed.add({
      "typ": "ortswechsel",
      "information": locationDict,
      "erstelltVon": ownProfil["id"],
      "erstelltAm": DateTime.now().toString()
    });
  }

  deleteOldTravelPlan(locationDict) {
    List travelPlans = ownProfil["reisePlanung"];
    List removePlans = [];

    for (var travelPlan in travelPlans) {
      var isPast = DateTime.parse(travelPlan["bis"]).compareTo(DateTime.now()) == -1;

      if (isPast) {
        removePlans.add(travelPlan);
        break;
      }
    }

    if (removePlans.isEmpty) return;

    for(var removePlan in removePlans){
      travelPlans.remove(removePlan);
    }

    ProfilDatabase().updateProfil(
        "reisePlanung = '$travelPlans'", "WHERE id = '${ownProfil["id"]}'");
  }

  changeAllDbEntries(locationDict, oldLocationDict) async {
    await StadtinfoDatabase().addFamiliesInCity(locationDict, ownProfil["id"]);

    joindAndRemoveChatGroups(locationDict, oldLocationDict);
    deleteChangeCityNewsSameDay();
    saveNewsPage(locationDict);
    notifications.prepareNewLocationNotification();

    deleteOldTravelPlan(locationDict);
    addVisitedCountries(locationDict["countryname"]);
  }

  save() async {
    var locationData = autoComplete.getGoogleLocationData();

    if (locationData["city"] == null) {
      customSnackBar(context, AppLocalizations.of(context)!.ortEingeben);
      return;
    }
    selected = true;

    var locationDict = {
      "city": locationData["city"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
      "countryname": locationData["countryname"],
    };
    Map ownProfilData = Hive.box("secureBox").get("ownProfil");
    Map oldLocationDict = {
      "city": ownProfilData["ort"],
      "longt": ownProfilData["longt"],
      "latt": ownProfilData["latt"],
      "countryname": ownProfilData["land"],
    };

    saveLocation(locationDict);

    changeAllDbEntries(locationDict, oldLocationDict);


    if (context.mounted){
      customSnackBar(
          context,
          "${AppLocalizations.of(context)!.aktuelleOrt} ${AppLocalizations.of(context)!.erfolgreichGeaender}",
          color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    autoComplete.hintText = AppLocalizations.of(context)!.neuenOrtEingeben;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.ortAendern,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            autoComplete,
          ],
        ),
      ),
    );
  }
}
