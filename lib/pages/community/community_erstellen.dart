import 'dart:convert';

import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:familien_suche/pages/community/community_details.dart';
import 'package:familien_suche/services/database.dart';
import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

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

  

  saveCommunity() async{
    var locationData = ortAuswahlBox.getGoogleLocationData();
    var uuid = const Uuid();
    var communityId = uuid.v4();

    var communityData = {
      "id": communityId,
      "name" : nameController.text,
      "beschreibung": beschreibungKontroller.text,
      "link": linkKontroller.text,
      "ort": locationData["city"],
      "land": locationData["countryname"],
      "latt": locationData["latt"],
      "longt": locationData["longt"],
      "erstelltAm": DateTime.now().toString(),
      "members": json.encode([userId]),
      "erstelltVon": userId
    };

    if(!checkValidationAndSendError(communityData)) return false;

    await CommunityDatabase().addNewCommunity(communityData);

    return true;

  }

  checkValidationAndSendError(communityData){
    if(communityData["name"].isEmpty){
      customSnackbar(context, AppLocalizations.of(context).bitteNameEingeben);
    }else if(communityData["beschreibung"].isEmpty){
      customSnackbar(context, AppLocalizations.of(context).bitteCommunityBeschreibungEingeben);
    }else if(communityData["ort"].isEmpty){
      customSnackbar(context, AppLocalizations.of(context).bitteStadtEingeben);
    } else{
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = AppLocalizations.of(context).stadtEingeben;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).communityErstellen,
          buttons: [
            IconButton(
                onPressed: () async {
                  var success = await saveCommunity();
                  if(!success) return;

                  var community = await CommunityDatabase().getData("*", "WHERE erstelltVon = '$userId'");

                  global_func.changePageForever(context, StartPage(selectedIndex: 2));
                  global_func.changePage(context, CommunityDetails(community: community));
    },
                icon: const Icon(Icons.done, size: 30))
          ]),
      body: ListView(
        children: [
          customTextInput(AppLocalizations.of(context).communityName, nameController),
          ortAuswahlBox,
          customTextInput(AppLocalizations.of(context).linkEingebenOptional, linkKontroller),
          customTextInput(AppLocalizations.of(context).beschreibungCommunity, beschreibungKontroller, moreLines: 5, textInputAction: TextInputAction.newline)
        ],
      ),
    );
  }
}