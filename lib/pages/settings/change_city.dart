import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../global/custom_widgets.dart';
import '../../services/locationsService.dart';
import '../../services/notification.dart' as notifications;
import '../../widgets/custom_appbar.dart';
import '../../widgets/google_autocomplete.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ChangeLocationPage extends StatefulWidget {
  const ChangeLocationPage({Key key}) : super(key: key);

  @override
  _ChangeLocationPageState createState() => _ChangeLocationPageState();
}

class _ChangeLocationPageState extends State<ChangeLocationPage> {
  TextEditingController ortChangeKontroller = TextEditingController();
  List suggestedCities = [];
  List<Widget> suggestedCitiesList = [];
  int selectedIndex = -1;
  Map locationData = {};
  var autoComplete = GoogleAutoComplete();
  Map ownProfil = Hive.box("secureBox").get("ownProfil");

  @override
  void initState() {
    autoComplete.onConfirm = (){
      save();
    };
    super.initState();
  }

  joindAndRemoveChatGroups(locationDict, oldLocation) async{
    final Map leaveCity = getCityFromHive(cityName: oldLocation) ?? {};
    String chatConnectId = leaveCity["id"].toString();

    ChatGroupsDatabase().leaveChat(chatConnectId);
    ChatGroupsDatabase().joinAndCreateCityChat(locationDict["city"]);
  }

  addVisitedCountries(newCountry) async{
    List visitedCountries = ownProfil["besuchteLaender"];
    Map allCountries = LocationService().getAllCountryNames();
    String targetLanguage = getVisitedCountriesLanguage(visitedCountries, allCountries);
    int wrongLanguageIndex = targetLanguage == "ger"
        ? allCountries["eng"].indexOf(newCountry)
        : allCountries["ger"].indexOf(newCountry);

    if(wrongLanguageIndex > -1) newCountry = allCountries["ger"][wrongLanguageIndex];

    if(visitedCountries.contains(newCountry)) return;


    ownProfil["besuchteLaender"].add(newCountry);
    ProfilDatabase().updateProfil(
        "besuchteLaender = JSON_ARRAY_APPEND(besuchteLaender, '\$', '$newCountry')",
        "WHERE id = '${ownProfil["id"]}'"
    );
  }

  getVisitedCountriesLanguage(visitedCountries, allCountries){
    final bool isGermanDeviceLanguage = kIsWeb
        ? window.locale.languageCode == "de"
        : Platform.localeName == "de_DE";
    String visitedCountriesLanguage = ownProfil["besuchteLaender"].isEmpty
        ?  isGermanDeviceLanguage ? "ger" : "eng"
        : allCountries["ger"].contains(ownProfil["besuchteLaender"][0])
          ? "ger" : "eng";

    return visitedCountriesLanguage;
  }

  saveLocation(locationDict) async {
    ownProfil["ort"] = locationDict["city"];
    ownProfil["longt"] =locationDict["longt"];
    ownProfil["latt"] =locationDict["latt"];
    ownProfil["land"] =locationDict["countryname"];

    ProfilDatabase().updateProfilLocation(ownProfil["id"], locationDict);
  }

  saveNewsPage(locationDict) async {
    bool isSaved =  await NewsPageDatabase().addNewNews({
      "typ": "ortswechsel",
      "information": json.encode(locationDict),
    });

    if(!isSaved) return;

    var newsFeed = Hive.box("secureBox").get("newsFeed");
    newsFeed.add({
      "typ": "ortswechsel",
      "information": locationDict,
      "erstelltVon": ownProfil["id"],
      "erstelltAm": DateTime.now().toString()
    });
  }

  saveCityInformation(locationDict){
    StadtinfoDatabase().addNewCity(locationDict);
    StadtinfoDatabase().update(
        "familien = JSON_ARRAY_APPEND(familien, '\$', '${ownProfil["id"]}')",
        "WHERE (ort LIKE '%${locationDict["city"]}%' OR ort LIKE '%${locationDict["countryname"]}%') AND JSON_CONTAINS(familien, '\"${ownProfil["id"]}\"') < 1");
  }

  deleteOldTravelPlan(locationDict){
    List travelPlans = ownProfil["reisePlanung"];
    Map removePlan = {};

    for(var travelPlan in travelPlans){
      bool sameCity =locationDict["city"] == travelPlan["ortData"]["city"];
      bool sameCountry = locationDict["countryname"] ==travelPlan["ortData"]["countryname"];
      bool sameMonth = DateTime.parse(travelPlan["von"]).month == DateTime.now().month;

      if(sameCity && sameCountry && sameMonth){
        removePlan = travelPlan;
      }
    }


    if(removePlan.isEmpty) return;

    travelPlans.remove(removePlan);
    ProfilDatabase().updateProfil("reisePlanung = '$travelPlans'", "WHERE id = '${ownProfil["id"]}'");

  }

  save() async {
    var locationData = autoComplete.getGoogleLocationData();


    if(locationData["city"] == null) {
      customSnackbar(context, AppLocalizations.of(context).ortEingeben);
      return;
    }

    var locationDict = {
      "city": locationData["city"],
      "longt": locationData["longt"],
      "latt": locationData["latt"],
      "countryname": locationData["countryname"],
    };
    final String oldLocation = Hive.box("secureBox").get("ownProfil")["ort"];

    saveLocation(locationDict);
    joindAndRemoveChatGroups(locationDict, oldLocation);
    saveNewsPage(locationDict);
    notifications.prepareFamilieAroundNotification();
    saveCityInformation(locationDict);

    deleteOldTravelPlan(locationDict);
    addVisitedCountries(locationDict["countryname"]);

    customSnackbar(context,
    AppLocalizations.of(context).aktuelleOrt +" "+
            AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    autoComplete.hintText = AppLocalizations.of(context).neuenOrtEingeben;

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).ortAendern,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          autoComplete,
        ],
      ),
    );
  }
}
