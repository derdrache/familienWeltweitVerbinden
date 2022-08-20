import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:familien_suche/pages/community/community_details.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../services/locationsService.dart';
import '../../widgets/google_autocomplete.dart';
import '../start_page.dart';

class CommunityErstellen extends StatefulWidget {
  const CommunityErstellen({Key key}) : super(key: key);

  @override
  State<CommunityErstellen> createState() => _CommunityErstellenState();
}

class _CommunityErstellenState extends State<CommunityErstellen> {
  var nameController = TextEditingController();
  var beschreibungKontroller = TextEditingController();
  var linkKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete();
  var userId = FirebaseAuth.instance.currentUser.uid;
  var ownCommunity = true;
  var locationDropdown = CustomDropDownButton();
  var kontinentDropdown = CustomDropDownButton();


  @override
  void initState() {
    var isGerman = kIsWeb
        ? window.locale.languageCode == "de"
        : Platform.localeName == "de_DE";
    var allContinents = LocationService().getAllContinents();

    locationDropdown = CustomDropDownButton(
      items: ["Ort / Land", "Kontinent"],
      hintText: "Genauigkeit des Standorts der Gemeinschaft",
      selected: "Ort / Land",
      onChange: () => setState(() {}),
    );

    kontinentDropdown = CustomDropDownButton(
      items: isGerman ? allContinents["ger"] : allContinents["eng"],
      hintText: "Kontinent auswählen",
    );

    super.initState();
  }

  saveCommunity() async {
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var communityId = uuid.v4();

    var communityData = {
      "id": communityId,
      "name": nameController.text,
      "beschreibung": beschreibungKontroller.text,
      "link": linkKontroller.text,
      "ort": locationData["city"],
      "land": locationData["countryname"],
      "latt": locationData["latt"],
      "longt": locationData["longt"],
      "erstelltAm": DateTime.now().toString(),
      "members": json.encode([userId]),
      "erstelltVon": userId,
      "ownCommunity": ownCommunity
    };

    if (!checkValidationAndSendError(communityData)) return false;

    await CommunityDatabase().addNewCommunity(communityData);

    return true;
  }

  checkValidationAndSendError(communityData) {
    if (communityData["name"].isEmpty) {
      customSnackbar(context, AppLocalizations.of(context).bitteNameEingeben);
    } else if (communityData["beschreibung"].isEmpty) {
      customSnackbar(context,
          AppLocalizations.of(context).bitteCommunityBeschreibungEingeben);
    } else if (communityData["ort"].isEmpty) {
      customSnackbar(context, AppLocalizations.of(context).bitteStadtEingeben);
    } else {
      return true;
    }
  }



  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = AppLocalizations.of(context).stadtEingeben;


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
                  var success = await saveCommunity();
                  if (!success) return;

                  var community = await CommunityDatabase()
                      .getData("*", "WHERE erstelltVon = '$userId'");

                  global_func.changePageForever(
                      context, StartPage(selectedIndex: 3));
                  global_func.changePage(
                      context, CommunityDetails(community: community));
                },
                icon: const Icon(Icons.done, size: 30))
          ]),
      body: ListView(
        children: [
          customTextInput(
              AppLocalizations.of(context).communityName, nameController),
          locationDropdown,
          if(locationDropdown.selected != "Kontinent") ortAuswahlBox,
          if(locationDropdown.selected == "Kontinent") kontinentDropdown,
          ownCommunityBox(),
          customTextInput(AppLocalizations.of(context).linkEingebenOptional,
              linkKontroller),
          customTextInput(AppLocalizations.of(context).beschreibungCommunity,
              beschreibungKontroller,
              moreLines: 5, textInputAction: TextInputAction.newline)
        ],
      ),
    );
  }
}
