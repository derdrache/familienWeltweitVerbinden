import 'dart:convert';

import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';
import 'package:uuid/uuid.dart';

import '../../../windows/nutzerrichtlinen.dart';
import 'community_details.dart';
import '../../../widgets/google_autocomplete.dart';
import '../../start_page.dart';

class CommunityErstellen extends StatefulWidget {
  const CommunityErstellen({Key key}) : super(key: key);

  @override
  State<CommunityErstellen> createState() => _CommunityErstellenState();
}

class _CommunityErstellenState extends State<CommunityErstellen> {
  var nameController = TextEditingController();
  var beschreibungKontroller = TextEditingController();
  var linkKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete(withoutTopMargin: true,);
  var userId = FirebaseAuth.instance.currentUser.uid;
  var ownCommunity = true;
  final translator = GoogleTranslator();
  bool chooseCurrentLocation = false;
  bool secretChat = false;


  saveCommunity() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var communityId = uuid.v4();

    var communityData = {
      "id": communityId,
      "name": nameController.text,
      "beschreibung": beschreibungKontroller.text,
      "beschreibungGer":beschreibungKontroller.text,
      "beschreibungEng": beschreibungKontroller.text,
      "link": linkKontroller.text,
      "ort": locationData["city"],
      "land": locationData["countryname"],
      "latt": locationData["latt"],
      "longt": locationData["longt"],
      "erstelltAm": DateTime.now().toString(),
      "members": json.encode(ownCommunity ? [userId] : []),
      "erstelltVon": userId,
      "ownCommunity": ownCommunity,
      "secretChat": secretChat
    };

    if (!checkValidationAndSendError(communityData)) return false;

    saveDB(communityData, locationData);

    communityData["bild"] = "assets/bilder/village.jpg";
    communityData["interesse"] = [];
    communityData["members"] = [];
    communityData["einladung"] = [];

    var allCommunities = Hive.box('secureBox').get("communities") ?? [];
    allCommunities.add(communityData);

    return communityData;
  }

  saveDB(communityData, locationData) async{
    bool descriptionIsGerman = true;

    var languageCheck = await translator.translate(communityData["beschreibung"]);
    descriptionIsGerman = languageCheck.sourceLanguage.code == "de";

    if(descriptionIsGerman){
      communityData["beschreibungGer"] = communityData["beschreibung"];
      communityData["beschreibungEng"] = await descriptionTranslation(communityData["beschreibungGer"], "auto");
      communityData["beschreibungEng"] += "\n\nThis is an automatic translation";
    }else{
      communityData["beschreibungEng"] = communityData["beschreibung"];
      communityData["beschreibungGer"] = await descriptionTranslation(
          communityData["beschreibungEng"] + "\n\n Hierbei handelt es sich um eine automatische Übersetzung","de");
      communityData["beschreibungGer"] = communityData["beschreibungGer"] + "\n\nHierbei handelt es sich um eine automatische Übersetzung";
    }

    await CommunityDatabase().addNewCommunity(Map.of(communityData));

    StadtinfoDatabase().addNewCity(locationData);
    ChatGroupsDatabase().addNewChatGroup(
        userId, "</community=${communityData["id"]}"
    );
  }

  descriptionTranslation(text, targetLanguage) async{
    text = text.replaceAll("'", "");

    var translation = await translator.translate(text,
        from: "auto", to: targetLanguage);

    return translation.toString();
  }

  checkValidationAndSendError(communityData) {
    if (communityData["name"].isEmpty) {
      customSnackbar(context, AppLocalizations.of(context).bitteNameEingeben);
    } else if (communityData["beschreibung"].isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context).bitteCommunityBeschreibungEingeben);
    } else if (communityData["ort"] == null || communityData["ort"].isEmpty) {
      customSnackbar(context, AppLocalizations.of(context).bitteStadtEingeben);
    } else {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = AppLocalizations.of(context).stadtEingeben;

    chooseOwnLocationBox(){
      return Container(
        margin: const EdgeInsets.only(left: 15, right: 15),
        child: Row(children: [
          Text(AppLocalizations.of(context).aktuellenOrtVerwenden, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Expanded(child: SizedBox.shrink()),
          Switch(value: chooseCurrentLocation, onChanged: (bool){
            if(bool){
              var ownProfil = Hive.box('secureBox').get("ownProfil");
              var currentLocaton = {
                "city": ownProfil["ort"],
                "countryname": ownProfil["land"],
                "longt": ownProfil["longt"],
                "latt": ownProfil["latt"],
              };
              ortAuswahlBox.setLocation(currentLocaton);
            } else{
              ortAuswahlBox.clear();
            }
            setState(() {
              chooseCurrentLocation = bool;
            });
          })
        ],),
      );
    }

    ownCommunityBox() {
      return Padding(
        padding: EdgeInsets.only(left:15, right: 15),
        child: Row(
          children: [
            Expanded(
                child: Text(AppLocalizations.of(context).frageTeilGemeinschaft,
                    maxLines: 2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Checkbox(
                value: ownCommunity,
                onChanged: (value) {
                  setState(() {
                    ownCommunity = value;
                  });
                }),
          ],
        ),
      );
    }

    secretChatQuestionBox(){
      return Padding(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: Row(
          children: [
            Expanded(child: Text(AppLocalizations.of(context).geheimerChat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Switch(
                value: secretChat,
                onChanged: (newValue){
                  setState(() {
                    secretChat = newValue;
                  });
                }
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).communityErstellen,
          buttons: [
            IconButton(
                onPressed: () async {
                  var communityData = await saveCommunity();

                  global_func.changePageForever(
                      context, StartPage(selectedIndex: 2, informationPageIndex: 2,));
                  global_func.changePage(
                      context, CommunityDetails(community: communityData));
                },
                icon: const Icon(Icons.done, size: 30))
          ]),
      body: ListView(
        children: [
          customTextInput(
              AppLocalizations.of(context).communityName, nameController),
          chooseOwnLocationBox(),
          ortAuswahlBox,
          customTextInput(AppLocalizations.of(context).linkEingebenOptional,
              linkKontroller),
          customTextInput(AppLocalizations.of(context).beschreibungCommunity,
              beschreibungKontroller,
              moreLines: 5, textInputAction: TextInputAction.newline),
          Center(child: secretChatQuestionBox()),
          ownCommunityBox(),
          Center(child: NutzerrichtlinenAnzeigen(page: "create")),
          const SizedBox(height: 20)
        ],
      ),
    );
  }
}
