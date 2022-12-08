import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../global/custom_widgets.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/google_autocomplete.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ChangeCityPage extends StatefulWidget {
  const ChangeCityPage({Key key}) : super(key: key);

  @override
  _ChangeCityPageState createState() => _ChangeCityPageState();
}

class _ChangeCityPageState extends State<ChangeCityPage> {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  TextEditingController ortChangeKontroller = TextEditingController();
  List suggestedCities = [];
  List<Widget> suggestedCitiesList = [];
  int selectedIndex = -1;
  Map locationData = {};
  var autoComplete = GoogleAutoComplete();

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

  saveProfil(locationDict) async {
    var ownProfil = Hive.box("secureBox").get("ownProfil");
    ownProfil["ort"] = locationDict["city"];
    ownProfil["longt"] =locationDict["longt"];
    ownProfil["latt"] =locationDict["latt"];
    ownProfil["land"] =locationDict["countryname"];

    ProfilDatabase().updateProfilLocation(userId, locationDict);
  }

  saveNewsPage(locationDict){
    NewsPageDatabase().addNewNews({
      "typ": "ortswechsel",
      "information": json.encode(locationDict),
    });

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
        "WHERE ort LIKE '%${locationDict["city"]}%' AND JSON_CONTAINS(familien, '\"$userId\"') < 1");
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
    saveProfil(locationDict);
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
