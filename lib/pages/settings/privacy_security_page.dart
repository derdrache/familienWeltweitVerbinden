import 'dart:io';
import 'dart:ui';

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
  var profil;

  PrivacySecurityPage({Key key, this.profil}) : super(key: key);

  @override
  _PrivacySecurityPageState createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  double fontsize = 20;
  var automaticLocationDropdown = CustomDropDownButton();
  var reiseplanungDropdown = CustomDropDownButton();
  var exactLocationDropdown = CustomDropDownButton();
  var spracheIstDeutsch = kIsWeb
      ? window.locale.languageCode == "de"
      : Platform.localeName == "de_DE";

  
  saveAutomaticLocation() async {
    if(widget.profil["reiseart"] == "fixed location" || widget.profil["reiseart"] == "Fester Standort"){
      customSnackbar(context, AppLocalizations.of(context).automatischerStandortNichtMoeglich);
      return;
    }

    var locationAuswahl = automaticLocationDropdown.getSelected();

    if (locationAuswahl != standortbestimmung[0] &&
        locationAuswahl != standortbestimmungEnglisch[0]) {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    }

    ProfilDatabase().updateProfil(
        "automaticLocation ='$locationAuswahl'", "WHERE id ='$userId'");
  }

  saveReiseplanung() async{
    var reiseplanungPrivacyAuswahl = reiseplanungDropdown.getSelected();

    var secureBox = Hive.box("secureBox");
    var ownProfil = secureBox.get("ownProfil");
    ownProfil["reiseplanungPrivacy"] = reiseplanungPrivacyAuswahl;
    secureBox.put("ownProfil", ownProfil);


    ProfilDatabase().updateProfil(
        "reiseplanungPrivacy = '$reiseplanungPrivacyAuswahl'",
        "WHERE id = '$userId'"
    );
  }

  saveExactLocation() async{
    var exactLocationPrivacyAuswahl = exactLocationDropdown.getSelected();

    var secureBox = Hive.box("secureBox");
    var ownProfil = secureBox.get("ownProfil");
    ownProfil["genauerStandortPrivacy"] = exactLocationPrivacyAuswahl;
    secureBox.put("ownProfil", ownProfil);


    ProfilDatabase().updateProfil(
        "genauerStandortPrivacy = '$exactLocationPrivacyAuswahl'",
        "WHERE id = '$userId'"
    );
  }

  setAutomaticLocationDropdown(){
    var locationList = spracheIstDeutsch ?
      standortbestimmung : standortbestimmungEnglisch;
    var selected = widget.profil["automaticLocation"] != null ?
      (spracheIstDeutsch ?
      global_func.changeEnglishToGerman(widget.profil["automaticLocation"]) :
      global_func.changeGermanToEnglish(widget.profil["automaticLocation"])) :
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
    global_func.changeEnglishToGerman(widget.profil["genauerStandortPrivacy"]) :
    global_func.changeGermanToEnglish(widget.profil["genauerStandortPrivacy"]);

    exactLocationDropdown = CustomDropDownButton(
      items: items,
      selected: selected,
      onChange: () => saveExactLocation(),
    );
  }

  setReiseplanungDropdown(){
    var items = spracheIstDeutsch ? privacySetting : privacySettingEnglisch;
    var selected = spracheIstDeutsch ?
    global_func.changeEnglishToGerman(widget.profil["reiseplanungPrivacy"]) :
    global_func.changeGermanToEnglish(widget.profil["reiseplanungPrivacy"]);

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
                value: widget.profil["emailAnzeigen"] == 1 ? true : false,
                inactiveThumbColor: Colors.grey[700],
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    widget.profil["emailAnzeigen"] = value == true ? 1 : 0;
                  });
                  ProfilDatabase().updateProfil(
                      "emailAnzeigen = '${widget.profil["emailAnzeigen"]}'",
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
            SizedBox(width: 150, child: automaticLocationDropdown)
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
            SizedBox(width: 150,child: exactLocationDropdown)
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
          SizedBox(width: 150,child: reiseplanungDropdown)
        ],)
      );
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
                    ProfilDatabase().deleteProfil(widget.profil["id"]);
                    DbDeleteImage(widget.profil["bild"]);
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
      body: Column(
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
    );
  }
}
