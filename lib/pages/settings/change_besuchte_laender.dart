import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/locationsService.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_multi_select.dart';

class ChangeBesuchteLaenderPage extends StatefulWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List visitedCountriesList;
  bool isGerman;

  ChangeBesuchteLaenderPage(
      {Key? key, required this.visitedCountriesList, required this.isGerman})
      : super(key: key);

  @override
  State<ChangeBesuchteLaenderPage> createState() =>
      _ChangeBesuchteLaenderPageState();
}

class _ChangeBesuchteLaenderPageState extends State<ChangeBesuchteLaenderPage> {
  late CustomMultiTextForm besuchteLaenderDropdown;

  @override
  void initState() {
    Map allCountries = LocationService().getAllCountryNames();
    List allCountriesLanguage;
    bool unselectedAndGerman = widget.visitedCountriesList.isEmpty && widget.isGerman;
    bool selectedIsGerman = widget.visitedCountriesList.isNotEmpty
        && allCountries["ger"].contains(widget.visitedCountriesList[0]);

    if(unselectedAndGerman || selectedIsGerman){
      allCountriesLanguage = allCountries["ger"];
    }else{
      allCountriesLanguage = allCountries["eng"];
    }

    besuchteLaenderDropdown = CustomMultiTextForm(
        auswahlList: allCountriesLanguage,
        selected: widget.visitedCountriesList,
        onConfirm: (){
          saveInDB();
        },
    );

    super.initState();
  }

  saveInDB() async{
    var selectedCountries = besuchteLaenderDropdown.getSelected();

    await ProfilDatabase().updateProfil(
        "besuchteLaender = '${jsonEncode(selectedCountries)}'",
        "WHERE id = '${widget.userId}'");

    updateHiveOwnProfil("besuchteLaender", selectedCountries);
  }

  @override
  Widget build(BuildContext context) {
    besuchteLaenderDropdown.hintText =
        AppLocalizations.of(context)!.besuchteLaender;

    return Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.besucheLaenderVeraendern,
        ),
        body: ListView(
          children: [
            besuchteLaenderDropdown,
          ],
        ));
  }
}
