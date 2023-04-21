import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:hive/hive.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/google_autocomplete.dart';
import '../../widgets/flexible_date_picker.dart';
import '../../widgets/month_picker.dart';
import '../../services/notification.dart';

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
  var datePicker = FlexibleDatePicker(
                    startYear: DateTime.now().year,
                    withMonth: true,
                    multiDate: true,
                  );
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
    var newLocation = ortInput.googleSearchResult;
    StadtinfoDatabase().addNewCity(newLocation);

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

    if(datePicker.getDate() == null || ortData["city"] == null){
      customSnackbar(context,
          AppLocalizations.of(context).vollstaendigeDatenZukunftsOrtEingeben);
      return;
    }

    var startDate = datePicker.getDate()[0];
    var endDate = datePicker.getDate()[1];

    if (endDate.isBefore(startDate)) {
      customSnackbar(context, AppLocalizations.of(context).vonKleinerAlsBis);
      return;
    }

    var newReiseplan = {
      "von": startDate.toString(),
      "bis": endDate.toString(),
      "ortData": ortData
    };

    if (checkOverlappingPeriods(newReiseplan)) {
      customSnackbar(
          context, AppLocalizations.of(context).zeitraumUeberschneidetSich);
      return;
    }

    widget.reiseplanung.add(newReiseplan);

    saveInDatabase();
    prepareNewTravelPlanNotification();

    setState(() {
      datePicker.clear();
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
                  FlexibleDatePicker(
                    startYear: DateTime.now().year,
                    withMonth: true,
                    multiDate: true,
                  )
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
