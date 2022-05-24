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
  var ortInput = GoogleAutoComplete(width: 160);

  saveButton() {
    return IconButton(
        icon: const Icon(Icons.done),
        onPressed: () async {

          ProfilDatabase().updateProfil(
              "reisePlanung = '${jsonEncode(widget.reiseplanung)}'",
              "WHERE id = '${widget.userId}'"
          );

          Navigator.pop(context);
          customSnackbar(
              context, AppLocalizations.of(context).besuchteLaenderUpdate,
              color: Colors.green);


        });
  }

  addNewTravelPlan() {
    //var ortData = ortInput.getGoogleLocationData();
    var ortData = {
      "city": "Bonn",
      "countryname": "Germany",
      "longt": 7.0982068,
      "latt": 50.73743,
    };

    if (vonDate.getDate() == null ||
        bisDate.getDate() == null ||
        ortData["city"] == null) {
      customSnackbar(context, AppLocalizations.of(context).vollstaendigeDatenZukunftsOrtEingeben);
      return;
    }

    widget.reiseplanung.add({
      "von": vonDate.getDate().toString(),
      "bis": bisDate.getDate().toString(),
      "ortData": ortData
    });


    setState(() {
      vonDate = MonthPickerBox();
      bisDate = MonthPickerBox();
    });
  }

  @override
  Widget build(BuildContext context) {
    vonDate.hintText = AppLocalizations.of(context).von;
    bisDate.hintText = AppLocalizations.of(context).bis;
    ortInput.hintText = AppLocalizations.of(context).ort;

    addNewPlanBox() {
      return Container(
          margin: EdgeInsets.all(10),
          width: 800,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  vonDate,
                  SizedBox(width: 10),
                  bisDate,
                  SizedBox(width: 10),
                  ortInput,
                ],
              ),
              IconButton(
                  onPressed: () => addNewTravelPlan(),
                  icon: Icon(
                    Icons.add_circle,
                    size: 40,
                  ))
            ],
          ));
    }

    showReiseplanung(){
      return Container(
        child: ListView(
          children: [

          ],
        ),
      );
    }

    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context).reisePlanungVeraendern,
            buttons: <Widget>[saveButton()]),
        body: ListView(
          children: [
            addNewPlanBox(),
            Container(
                margin: const EdgeInsets.all(10),
                child: Text(
                  AppLocalizations.of(context).reisePlanung + ": ",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                )),
          ],
        ));
  }
}
