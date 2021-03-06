import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/locationsService.dart';
import '../../widgets/custom_appbar.dart';

class ChangeBesuchteLaenderPage extends StatefulWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;
  List selected;
  bool isGerman;

  ChangeBesuchteLaenderPage(
      {Key key, this.selected, this.isGerman})
      : super(key: key);

  @override
  State<ChangeBesuchteLaenderPage> createState() =>
      _ChangeBesuchteLaenderPageState();
}

class _ChangeBesuchteLaenderPageState extends State<ChangeBesuchteLaenderPage> {
  var besuchteLaenderDropdown = CustomMultiTextForm();

  @override
  void initState() {
    var allCountries = LocationService().getAllCountries();
    besuchteLaenderDropdown = CustomMultiTextForm(
        auswahlList:
            widget.isGerman ? allCountries["ger"] : allCountries["eng"],
        selected: widget.selected,
        onConfirm: (value) {
          saveInDB();
          setState(() {});
        });
    super.initState();
  }

  saveInDB() {
    var selectedCountries = besuchteLaenderDropdown.getSelected();

    ProfilDatabase().updateProfil(
        "besuchteLaender = '${jsonEncode(selectedCountries)}'",
        "WHERE id = '${widget.userId}'");

    customSnackbar(context, AppLocalizations.of(context).besuchteLaenderUpdate,
        color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    besuchteLaenderDropdown.hintText =
        AppLocalizations.of(context).laenderAuswahl;

    besuchteLaenderBox() {
      var visitedCountriesWidgetlist = [];
      var visitedCountries = besuchteLaenderDropdown.getSelected();

      for (var country in visitedCountries) {
        visitedCountriesWidgetlist.add(Container(
          margin: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
          child: Text(country),
        ));
      }

      return visitedCountriesWidgetlist;
    }

    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).besucheLaenderVeraendern,
        ),
        body: ListView(
          children: [
            besuchteLaenderDropdown,
            const SizedBox(height: 10),
            Container(
                margin: const EdgeInsets.all(10),
                child: Text(
                  AppLocalizations.of(context).besuchteLaender + ": ",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                )),
            ...besuchteLaenderBox()
          ],
        ));
  }
}
