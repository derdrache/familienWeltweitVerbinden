import 'dart:io';
import 'dart:ui';

import '../../auth/secrets.dart';
import '../../global/variablen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import '../../global/global_functions.dart' as global_func;

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart' as global_functions;
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../login_register_page/login_page.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({Key key}) : super(key: key);

  @override
  _PrivacySecurityPageState createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  Map ownProfil = Hive.box("secureBox").get("ownProfil");
  final double fontsize = 20;
  var automaticLocationDropdown = CustomDropDownButton();
  var reiseplanungDropdown = CustomDropDownButton();
  var exactLocationDropdown = CustomDropDownButton();
  final bool spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  
  saveAutomaticLocation() async {
    if(ownProfil["reiseart"] == "fixed location" || ownProfil["reiseart"] == "Fester Standort"){
      customSnackbar(context, AppLocalizations.of(context).automatischerStandortNichtMoeglich);
      return;
    }

    var automaticLocationOption = automaticLocationDropdown.getSelected();

    if (automaticLocationOption != standortbestimmung[0] &&
        automaticLocationOption != standortbestimmungEnglisch[0]) {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
    }

    ownProfil["automaticLocation"] = automaticLocationOption;

    ProfilDatabase().updateProfil(
        "automaticLocation ='$automaticLocationOption'", "WHERE id ='$userId'");
  }

  saveReiseplanung() async{
    var reiseplanungPrivacyAuswahl = reiseplanungDropdown.getSelected();

    ownProfil["reiseplanungPrivacy"] = reiseplanungPrivacyAuswahl;

    ProfilDatabase().updateProfil(
        "reiseplanungPrivacy = '$reiseplanungPrivacyAuswahl'",
        "WHERE id = '$userId'"
    );
  }

  saveExactLocation() async{
    var exactLocationPrivacyAuswahl = exactLocationDropdown.getSelected();

    ownProfil["genauerStandortPrivacy"] = exactLocationPrivacyAuswahl;

    ProfilDatabase().updateProfil(
        "genauerStandortPrivacy = '$exactLocationPrivacyAuswahl'",
        "WHERE id = '$userId'"
    );
  }

  setAutomaticLocationDropdown(){
    var locationList = spracheIstDeutsch ?
      standortbestimmung : standortbestimmungEnglisch;
    var selected = ownProfil["automaticLocation"] != null ?
      (spracheIstDeutsch ?
      global_func.changeEnglishToGerman(ownProfil["automaticLocation"]) :
      global_func.changeGermanToEnglish(ownProfil["automaticLocation"])) :
      (spracheIstDeutsch
          ? standortbestimmung[0]
          : standortbestimmungEnglisch[0]);

    automaticLocationDropdown = CustomDropDownButton(
      items: locationList,
      selected: selected,
      onChange: () => saveAutomaticLocation(),
    );
  }

  setExactLocationDropdown(){
    var items = spracheIstDeutsch ? privacySetting : privacySettingEnglisch;
    var selected = spracheIstDeutsch ?
    global_func.changeEnglishToGerman(ownProfil["genauerStandortPrivacy"]) :
    global_func.changeGermanToEnglish(ownProfil["genauerStandortPrivacy"]);

    exactLocationDropdown = CustomDropDownButton(
      items: items,
      selected: selected,
      onChange: () => saveExactLocation(),
    );
  }

  setReiseplanungDropdown(){
    var items = spracheIstDeutsch ? privacySetting : privacySettingEnglisch;
    var selected = spracheIstDeutsch ?
    global_func.changeEnglishToGerman(ownProfil["reiseplanungPrivacy"]) :
    global_func.changeGermanToEnglish(ownProfil["reiseplanungPrivacy"]);

    reiseplanungDropdown = CustomDropDownButton(
        items: items,
        selected: selected,
        onChange: () => saveReiseplanung(),
    );
  }


  @override
  Widget build(BuildContext context) {
    setAutomaticLocationDropdown();
    setReiseplanungDropdown();
    setExactLocationDropdown();


    emailSettingContainer() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context).emailAlleSichtbar,
              style: TextStyle(fontSize: fontsize),
            ),
            const Expanded(child: SizedBox(width: 20)),
            Switch(
                value: ownProfil["emailAnzeigen"] == 1 ? true : false,
                inactiveThumbColor: Colors.grey[700],
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    ownProfil["emailAnzeigen"] = value == true ? 1 : 0;
                  });
                  ProfilDatabase().updateProfil(
                      "emailAnzeigen = '${ownProfil["emailAnzeigen"]}'",
                      "WHERE id = '$userId'");
                })
          ],
        ),
      );
    }

    automaticLocationContainer() {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).automatischeStandortbestimmung,
                style: TextStyle(fontSize: fontsize),
              ),
            ),
            SizedBox(width: 170, child: automaticLocationDropdown)
          ],
        ),
      );
    }

    exactLocationBox(){
      return Container(
          margin: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).genauerStandortSichtbarFuer,
                style: TextStyle(fontSize: fontsize),
              ),
            ),
            SizedBox(width: 170,child: exactLocationDropdown)
          ],)
      );
    }

    reiseplanungBox(){
      return Container(
        margin: const EdgeInsets.all(10),
        child: Row(children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context).reiseplanungSichtbarFuer,
              style: TextStyle(fontSize: fontsize),
            ),
          ),
          SizedBox(width: 170,child: reiseplanungDropdown)
        ],)
      );
    }

    chooseProfilIdWindow(){

    }

    deleteProfilWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).accountLoeschen,
              height: 90,
              children: [
                const SizedBox(height: 10),
                Center(
                    child: Text(
                        AppLocalizations.of(context).accountWirklichLoeschen))
              ],
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    var deleteProfil = ownProfil;

                    if(userId == mainAdmin){
                      var choosenProfilId = chooseProfilIdWindow();
                      deleteProfil = getProfilFromHive(profilId: choosenProfilId);
                    }

                    print(deleteProfil["id"]);
                    return;
                    ProfilDatabase().deleteProfil(deleteProfil["id"]);
                    DbDeleteImage(deleteProfil["bild"]);
                    setState(() {});
                    global_functions.changePageForever(
                        context, LoginPage());
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context).abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          });
    }

    deleteProfilContainer() {
      return FloatingActionButton.extended(
          backgroundColor: Colors.red,
          label: Text(AppLocalizations.of(context).accountLoeschen),
          onPressed: () => deleteProfilWindow());
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).privatsphaereSicherheit),
      body: SafeArea(
        child: Column(
          children: [
            emailSettingContainer(),
            automaticLocationContainer(),
            exactLocationBox(),
            reiseplanungBox(),
            const Expanded(child: SizedBox.shrink()),
            deleteProfilContainer(),
            const SizedBox(height: 10)
          ],
        ),
      ),
    );
  }
}
