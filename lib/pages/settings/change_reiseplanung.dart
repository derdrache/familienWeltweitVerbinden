import 'dart:convert';

import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/google_autocomplete.dart';
import '../../widgets/month_picker.dart';

class ChangeReiseplanungPage extends StatefulWidget {
  String userId;
  List reiseplanung;
  bool isGerman;

  ChangeReiseplanungPage(
      {Key key, this.userId, this.reiseplanung, this.isGerman})
      : super(key: key);

  @override
  State<ChangeReiseplanungPage> createState() => _ChangeReiseplanungPageState();
}

class _ChangeReiseplanungPageState extends State<ChangeReiseplanungPage> {
  var vonDate = MonthPickerBox();
  var bisDate = MonthPickerBox();
  var ortInput = GoogleAutoComplete(width: 180);

  saveInDatabase() {
    ProfilDatabase().updateProfil(
        "reisePlanung = '${jsonEncode(widget.reiseplanung)}'",
        "WHERE id = '${widget.userId}'");
  }

  checkOverlappingPeriods(newPlan) {
    var vonDateNewPlan = DateTime.parse(newPlan["von"]);
    var bisDateNewPlan = DateTime.parse(newPlan["bis"]);

    for (var plan in widget.reiseplanung) {
      var vonDatePlan = DateTime.parse(plan["von"]);
      var bisDatePlan = DateTime.parse(plan["bis"]);

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
    });
  }

  deleteReiseplan(reiseplan) {
    widget.reiseplanung.remove(reiseplan);

    saveInDatabase();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    vonDate.hintText = AppLocalizations.of(context).von;
    bisDate.hintText = AppLocalizations.of(context).bis;
    ortInput.hintText = AppLocalizations.of(context).ort;

    transformDateToText(dateString) {
      DateTime date = DateTime.parse(dateString);

      if ((date.month > DateTime.now().month &&
              date.year == DateTime.now().year) ||
          date.year > DateTime.now().year) {
        return date.month.toString() + "." + date.year.toString();
      } else {
        return AppLocalizations.of(context).jetzt;
      }
    }

    addNewPlanBox() {
      return Container(
          margin: const EdgeInsets.all(10),
          width: 800,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  vonDate,
                  const SizedBox(width: 10),
                  bisDate,
                  ortInput,
                ],
              ),
              IconButton(
                  onPressed: () => addNewTravelPlan(),
                  icon: const Icon(
                    Icons.add_circle,
                    size: 40,
                  ))
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
                  ),
                  onPressed: () => deleteReiseplan(planung),
                )
              ],
            )));
      }

      return Expanded(
        child: ListView(
          children: reiseplanungBox,
        ),
      );
    }

    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).reisePlanungVeraendern,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addNewPlanBox(),
            Container(
                margin: const EdgeInsets.all(10),
                child: Text(
                  AppLocalizations.of(context).reisePlanung + ": ",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                )),
            showReiseplanung()
          ],
        ));
  }
}
