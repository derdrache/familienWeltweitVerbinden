import 'dart:convert';

import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';
import 'package:uuid/uuid.dart';

import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../../windows/nutzerrichtlinen.dart';
import 'community_details.dart';
import '../../../widgets/google_autocomplete.dart';

class CommunityErstellen extends StatefulWidget {
  const CommunityErstellen({Key? key}) : super(key: key);

  @override
  State<CommunityErstellen> createState() => _CommunityErstellenState();
}

class _CommunityErstellenState extends State<CommunityErstellen> {
  var nameController = TextEditingController();
  var beschreibungKontroller = TextEditingController();
  var linkKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete(margin: const EdgeInsets.only(top: 0, bottom:5, left:10, right:10),withOwnLocation: true, withWorldwideLocation: true);
  var userId = Hive.box("secureBox").get("ownProfil")["id"];
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
      "nameGer": nameController.text,
      "nameEng": nameController.text,
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
      communityData["nameGer"] = communityData["name"];
      communityData["nameEng"] = await descriptionTranslation(communityData["name"], "auto");
      communityData["beschreibungGer"] = communityData["beschreibung"];
      communityData["beschreibungEng"] = await descriptionTranslation(communityData["beschreibungGer"], "auto");
      communityData["beschreibungEng"] += "\n\nThis is an automatic translation";
    }else{
      communityData["nameEng"] = communityData["name"];
      communityData["nameGer"] = await descriptionTranslation(communityData["name"], "de");
      communityData["beschreibungEng"] = communityData["beschreibung"];
      communityData["beschreibungGer"] = await descriptionTranslation(
          communityData["beschreibungEng"] + "\n\n Hierbei handelt es sich um eine automatische Übersetzung","de");
      communityData["beschreibungGer"] = communityData["beschreibungGer"] + "\n\nDies ist eine automatische Übersetzung";
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
      customSnackbar(context, AppLocalizations.of(context)!.bitteNameEingeben);
    } else if (communityData["beschreibung"].isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context)!.bitteCommunityBeschreibungEingeben);
    } else if (communityData["ort"] == null || communityData["ort"].isEmpty) {
      customSnackbar(context, AppLocalizations.of(context)!.bitteStadtEingeben);
    } else {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = AppLocalizations.of(context)!.stadtEingeben;

    ownCommunityBox() {
      return Padding(
        padding: const EdgeInsets.only(left:15, right: 15),
        child: Row(
          children: [
            Expanded(
                child: Text(AppLocalizations.of(context)!.frageTeilGemeinschaft,
                    maxLines: 2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Checkbox(
                value: ownCommunity,
                onChanged: (value) {
                  setState(() {
                    ownCommunity = value!;
                  });
                }),
          ],
        ),
      );
    }

    secretChatQuestionBox(){
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Row(
          children: [
            Expanded(child: Text(AppLocalizations.of(context)!.geheimerChat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
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
          title: AppLocalizations.of(context)!.communityErstellen,
          buttons: [
            IconButton(
                onPressed: () async {
                  var communityData = await saveCommunity();

                  if (context.mounted){
                    Navigator.pop(context);
                    global_func.changePage(
                        context, CommunityDetails(community: communityData));
                  }
                },
                tooltip: AppLocalizations.of(context)!.tooltipEingabeBestaetigen,
                icon: const Icon(Icons.done, size: 30))
          ]),
      body: ListView(
        children: [
          CustomTextInput(
              AppLocalizations.of(context)!.communityName, nameController, maxLength: 40),
          ortAuswahlBox,
          CustomTextInput(AppLocalizations.of(context)!.linkEingebenOptional,
              linkKontroller),
          CustomTextInput(AppLocalizations.of(context)!.beschreibungCommunity,
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
