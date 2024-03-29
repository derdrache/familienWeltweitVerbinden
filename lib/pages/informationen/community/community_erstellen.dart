import 'dart:convert';

import 'package:familien_suche/pages/informationen/community/community_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';
import 'package:uuid/uuid.dart';

import '../../../global/style.dart' as style;
import '../../../global/global_functions.dart' as global_func;
import '../../../services/database.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../../widgets/nutzerrichtlinen.dart';
import '../../start_page.dart';
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
      "members": ownCommunity ? [userId] : [],
      "erstelltVon": userId,
      "ownCommunity": ownCommunity,
      "secretChat": secretChat
    };

    if (!checkValidationAndSendError(communityData)) return false;

    saveDB(Map.of(communityData), locationData);

    communityData["bild"] = "assets/bilder/village.jpg";
    communityData["interesse"] = [];
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
    }else{
      communityData["nameEng"] = communityData["name"];
      communityData["nameGer"] = await descriptionTranslation(communityData["name"], "de");
      communityData["beschreibungEng"] = communityData["beschreibung"];
      communityData["beschreibungGer"] = await descriptionTranslation(communityData["beschreibungEng"],"de");
    }

    communityData["members"] = json.encode(communityData["members"]);

    await CommunityDatabase().addNewCommunity(communityData);

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
      customSnackBar(context, AppLocalizations.of(context)!.bitteNameEingeben);
    } else if (communityData["beschreibung"].isEmpty) {
      customSnackBar(context,
          AppLocalizations.of(context)!.bitteCommunityBeschreibungEingeben);
    } else if (communityData["ort"] == null || communityData["ort"].isEmpty) {
      customSnackBar(context, AppLocalizations.of(context)!.bitteStadtEingeben);
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: style.webWidth),
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
        ),
      );
    }

    secretChatQuestionBox(){
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Container(
          constraints: const BoxConstraints(maxWidth: style.webWidth),
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
        ),
      );
    }

    return Scaffold(
        resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.communityErstellen,
          buttons: [
            IconButton(
                onPressed: () async {
                  var communityData = await saveCommunity();

                    global_func.changePage(
                        context, CommunityDetails(community: communityData, toMainPage: true,));

                },
                tooltip: AppLocalizations.of(context)!.tooltipEingabeBestaetigen,
                icon: const Icon(Icons.done, size: 30))
          ]),
      body: Column(
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
