import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/google_autocomplete.dart';
import '../../widgets/month_picker.dart';

class ChangeReiseplanungPage extends StatefulWidget {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  List reiseplanung;
  bool isGerman;

  ChangeReiseplanungPage(
      {Key key,this.reiseplanung, this.isGerman})
      : super(key: key);

  @override
  State<ChangeReiseplanungPage> createState() => _ChangeReiseplanungPageState();
}

class _ChangeReiseplanungPageState extends State<ChangeReiseplanungPage> {
  var vonDate = MonthPickerBox();
  var bisDate = MonthPickerBox();
  var ortInput = GoogleAutoComplete();

  saveProfilReiseplanung(){
    ProfilDatabase().updateProfil(
        "reisePlanung = '${jsonEncode(widget.reiseplanung)}'",
        "WHERE id = '${widget.userId}'");
    updateHiveOwnProfil("reisePlanung", widget.reiseplanung);
  }

  saveInDatabase(){
    if(checkDuplicateEntry()){
      widget.reiseplanung.removeLast();
      customSnackbar(context, "Doppelter Eintrag");
      return;
    }

    saveProfilReiseplanung();

    StadtinfoDatabase().addNewCity(ortInput);

    NewsPageDatabase().addNewNews({
      "typ": "reiseplanung",
      "information": json.encode(widget.reiseplanung.last),
    });
  }

  checkDuplicateEntry(){
    List allReiseplanung = List.of(widget.reiseplanung);
    Map checkReiseplanung = allReiseplanung.last;
    allReiseplanung.removeLast();

    for(var reiseplanung in allReiseplanung){
      var isEqual = const DeepCollectionEquality().equals(checkReiseplanung,reiseplanung);
      if(isEqual) return true;
    }

    return false;
  }

  checkOverlappingPeriods(newPlan) {
    DateTime vonDateNewPlan = DateTime.parse(newPlan["von"]);
    DateTime bisDateNewPlan = DateTime.parse(newPlan["bis"]);

    for (var plan in widget.reiseplanung) {
      DateTime vonDatePlan = DateTime.parse(plan["von"]);
      DateTime bisDatePlan = DateTime.parse(plan["bis"]);

      if(vonDateNewPlan.isBefore(bisDatePlan) && vonDateNewPlan.isAfter(vonDatePlan)) return true;

      if(bisDateNewPlan.isBefore(bisDatePlan) && bisDateNewPlan.isAfter(vonDatePlan)) return true;

    }

    return false;
  }

  addNewTravelPlan() {
    var ortData = ortInput.getGoogleLocationData();

    if (vonDate.getDate() == null ||
        bisDate.getDate() == null ||
        ortData["city"] == null) {
      customSnackbar(context,
          AppLocalizations.of(context).vollstaendigeDatenZukunftsOrtEingeben);
      return;
    }

    if (bisDate.getDate().isBefore(vonDate.getDate())) {
      customSnackbar(context, AppLocalizations.of(context).vonKleinerAlsBis);
      return;
    }

    var newReiseplan = {
      "von": vonDate.getDate().toString(),
      "bis": bisDate.getDate().toString(),
      "ortData": ortData
    };

    if (checkOverlappingPeriods(newReiseplan)) {
      customSnackbar(
          context, AppLocalizations.of(context).zeitraumUeberschneidetSich);
      return;
    }

    widget.reiseplanung.add(newReiseplan);

    saveInDatabase();

    setState(() {
      vonDate = MonthPickerBox();
      bisDate = MonthPickerBox();
      ortInput.clear();
    });
  }

  deleteReiseplan(reiseplan) {
    widget.reiseplanung.remove(reiseplan);

    saveProfilReiseplanung();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    vonDate.hintText = AppLocalizations.of(context).von;
    bisDate.hintText = AppLocalizations.of(context).bis;
    ortInput.hintText = AppLocalizations.of(context).ort;

    transformDateToText(dateString) {
      DateTime date = DateTime.parse(dateString);

      return date.month.toString() + "." + date.year.toString();
    }

    addNewPlanBox() {
      return Container(
          margin: const EdgeInsets.all(10),
          width: 800,
          child: Row(
            children: [
              Column(
                children: [
                  SizedBox(width: 300,child: ortInput),
                  Row(
                    children: [
                      vonDate,
                      const SizedBox(width: 40),
                      bisDate,
                    ],
                  ),
                ],
              ),
              Expanded(
                child: IconButton(
                    onPressed: () => addNewTravelPlan(),
                    icon: const Icon(
                      Icons.add_circle,
                      size: 50,
                    )
                ),
              )
            ],
          ));
    }

    showReiseplanung() {
      List<Widget> reiseplanungBox = [];

      widget.reiseplanung.sort((a, b) => a["von"].compareTo(b["von"]) as int );

      for (var planung in widget.reiseplanung) {
        String ortText = planung["ortData"]["city"];

        if (planung["ortData"]["city"] != planung["ortData"]["countryname"]) {
          ortText += " / " + planung["ortData"]["countryname"];
        }

        reiseplanungBox.add(Container(
            margin: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    transformDateToText(planung["von"]) +
                        " - " +
                        transformDateToText(planung["bis"]) +
                        " in " +
                        ortText,
                    style: const TextStyle(fontSize: 18),
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: () => deleteReiseplan(planung),
                )
              ],
            )));
      }

      return ListView(
        children: reiseplanungBox,
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context).reisePlanungVeraendern,
      ),
      body: Column(
        children: [
          addNewPlanBox(),
          Expanded(child: showReiseplanung())
        ],
      )
    );
  }
}
