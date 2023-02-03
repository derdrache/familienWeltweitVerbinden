import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../global/custom_widgets.dart';
import '../../services/locationsService.dart';
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
  final String userId = FirebaseAuth.instance.currentUser.uid;
  TextEditingController ortChangeKontroller = TextEditingController();
  List suggestedCities = [];
  List<Widget> suggestedCitiesList = [];
  int selectedIndex = -1;
  Map locationData = {};
  var autoComplete = GoogleAutoComplete();
  var ownProfil = Hive.box("secureBox").get("ownProfil");

  @override
  void initState() {
    autoComplete.onConfirm = (){
      save();
    };
    super.initState();
  }

  saveChatGroups(locationDict, oldLocation) async{

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

    ProfilDatabase().updateProfilLocation(userId, locationDict);
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
      "erstelltVon": userId,
      "erstelltAm": DateTime.now().toString()
    });
  }

  saveCityInformation(locationDict){
    StadtinfoDatabase().addNewCity(locationDict);
    StadtinfoDatabase().update(
        "familien = JSON_ARRAY_APPEND(familien, '\$', '$userId')",
        "WHERE (ort LIKE '%${locationDict["city"]}%' OR ort LIKE '%${locationDict["countryname"]}%') AND JSON_CONTAINS(familien, '\"$userId\"') < 1");
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

    saveChatGroups(locationDict, oldLocation);
    saveLocation(locationDict);
    addVisitedCountries(locationDict["countryname"]);
    saveNewsPage(locationDict);
    saveCityInformation(locationDict);

    customSnackbar(context,
    AppLocalizations.of(context).aktuelleOrt +" "+
            AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    autoComplete.hintText = AppLocalizations.of(context).aktuellenOrtEingeben;

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).ortAendern,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          autoComplete,
        ],
      ),
    );
  }
}
