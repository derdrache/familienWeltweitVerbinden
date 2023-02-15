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


  saveCommunity() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var communityId = uuid.v4();
    bool descriptionIsGerman = true;
    String beschreibungGer = "";
    String beschreibungEng = "";

    var languageCheck = await translator.translate(beschreibungKontroller.text);
    descriptionIsGerman = languageCheck.sourceLanguage.code == "de";

    if(descriptionIsGerman){
      beschreibungGer = beschreibungKontroller.text;
      beschreibungEng = await descriptionTranslation(beschreibungGer, "auto");
      beschreibungEng += "\n\nThis is an automatic translation";
    }else{
      beschreibungEng = beschreibungKontroller.text;
      beschreibungGer = await descriptionTranslation(
          beschreibungEng + "\n\n Hierbei handelt es sich um eine automatische Übersetzung","de");
      beschreibungGer = beschreibungGer + "\n\nHierbei handelt es sich um eine automatische Übersetzung";
    }

    var communityData = {
      "id": communityId,
      "name": nameController.text,
      "beschreibung": beschreibungKontroller.text,
      "beschreibungGer":beschreibungGer,
      "beschreibungEng": beschreibungEng,
      "link": linkKontroller.text,
      "ort": locationData["city"],
      "land": locationData["countryname"],
      "latt": locationData["latt"],
      "longt": locationData["longt"],
      "erstelltAm": DateTime.now().toString(),
      "members": json.encode(ownCommunity ? [userId] : []),
      "erstelltVon": userId,
      "ownCommunity": ownCommunity
    };

    if (!checkValidationAndSendError(communityData)) return false;

    await CommunityDatabase().addNewCommunity(communityData);
    StadtinfoDatabase().addNewCity(locationData);
    ChatGroupsDatabase().addNewChatGroup(
        userId, "</community=$communityId"
    );

    return communityId;
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
          Text(AppLocalizations.of(context).aktuellenOrtVerwenden),
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
      double screenWidth = MediaQuery.of(context).size.width;

      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.only(left:10),
                width: screenWidth * 0.75,
                child: Text(AppLocalizations.of(context).frageTeilGemeinschaft,
                    maxLines: 2, style: const TextStyle(fontSize: 16))),
            const Expanded(
              child: SizedBox.shrink(),
            ),
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

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).communityErstellen,
          buttons: [
            IconButton(
                onPressed: () async {
                  var communityId = await saveCommunity();
                  
                  var community = await CommunityDatabase()
                      .getData("*", "WHERE id = '$communityId'");

                  global_func.changePageForever(
                      context, StartPage(selectedIndex: 2, informationPageIndex: 2,));
                  global_func.changePage(
                      context, CommunityDetails(community: community));
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
          ownCommunityBox(),
          Center(child: NutzerrichtlinenAnzeigen(page: "create")),
          const SizedBox(height: 20)
        ],
      ),
    );
  }
}
