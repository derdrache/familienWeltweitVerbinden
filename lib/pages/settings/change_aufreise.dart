import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/variablen.dart';
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_dropdown_button.dart';
import '../../widgets/layout/custom_snackbar.dart';


class ChangeAufreisePage extends StatefulWidget {
  final bool isGerman;
  DateTime? aufreiseSeit;
  DateTime? aufreiseBis;

  ChangeAufreisePage({
    this.aufreiseSeit,
    this.aufreiseBis,
    required this.isGerman,
    Key? key}) : super(key: key);

  @override
  State<ChangeAufreisePage> createState() => _ChangeAufreisePageState();
}

class _ChangeAufreisePageState extends State<ChangeAufreisePage> {
  late String reiseStatus;
  late CustomDropdownButton aufreiseDropdownButton;
  late bool noTraveling;
  late bool pastTravler;
  late bool stillTraveling;

  @override
  void initState() {
    reiseStatus = getReiseStatus();

    aufreiseDropdownButton = CustomDropdownButton(
      items: widget.isGerman ? aufreise : aufreiseEnglisch,
      selected: reiseStatus,
      onChange: () {
        setState(() {});
      }
    );



    super.initState();
  }

  getReiseStatus(){
    if(widget.aufreiseSeit == null){
      return widget.isGerman ? aufreise[0] : aufreiseEnglisch[0];
    } else if(widget.aufreiseBis == null){
      return widget.isGerman ? aufreise[2] : aufreiseEnglisch[2];
    } else{
      return widget.isGerman ? aufreise[1] : aufreiseEnglisch[1];
    }
  }

  checkValidation(){
    if(noTraveling) return true;

    if(widget.aufreiseSeit == null) {
      customSnackBar(context, AppLocalizations.of(context)!.eingebenSeitWannReise);
      return false;
    }

    if(widget.aufreiseBis == null && pastTravler){
      customSnackBar(context, AppLocalizations.of(context)!.eingebenBisWannReise);
      return false;
    }

    return true;
  }

  save() async{
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    bool validation = checkValidation();

    if(!validation) return;

    if(noTraveling) {
      ProfilDatabase().updateProfil(
          "aufreiseSeit = NULL, aufreiseBis = NULL", "WHERE id = '$userId'");
      updateHiveOwnProfil("aufreiseSeit", null);
      updateHiveOwnProfil("aufreiseBis", null);
    } else if(pastTravler){
      ProfilDatabase().updateProfil(
          "aufreiseSeit = '${widget.aufreiseSeit.toString()}',"
              "aufreiseBis = '${widget.aufreiseBis.toString()}'",
          "WHERE id = '$userId'");
      updateHiveOwnProfil("aufreiseSeit", widget.aufreiseSeit.toString());
      updateHiveOwnProfil("aufreiseBis", widget.aufreiseBis.toString());
    } else{
      ProfilDatabase().updateProfil(
          "aufreiseSeit = '${widget.aufreiseSeit.toString()}', aufreiseBis = NULL",
          "WHERE id = '$userId'");
      updateHiveOwnProfil("aufreiseSeit", widget.aufreiseSeit.toString());
      updateHiveOwnProfil("aufreiseBis", null);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    noTraveling = aufreiseDropdownButton.selected == aufreise[0]
        || aufreiseDropdownButton.selected == aufreiseEnglisch[0];
    pastTravler = aufreiseDropdownButton.selected == aufreise[1]
        || aufreiseDropdownButton.selected == aufreiseEnglisch[1];
    stillTraveling = aufreiseDropdownButton.selected == aufreise[2]
        || aufreiseDropdownButton.selected == aufreiseEnglisch[2];


    aufreiseBox(text, reiseDatum){
      String aufreiseString = AppLocalizations.of(context)!.datumAuswaehlen;

      if(reiseDatum != null) {
        var dateFormat = DateFormat('MM-yyyy');
        var dateTime = DateTime(reiseDatum.year, reiseDatum.month, reiseDatum.day);
        aufreiseString = dateFormat.format(dateTime);
      }

      return Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 600,
          child: Row(children: [
            Text(text, style: const TextStyle(fontSize: 20),),
            const SizedBox(width: 10),
            ElevatedButton(
              child: Text(aufreiseString, style: const TextStyle(fontSize: 20)),
              onPressed: () async{
                reiseDatum = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  lastDate: DateTime.now(),
                  firstDate: DateTime(DateTime.now().year - 100),
                );


                if(context.mounted && text == AppLocalizations.of(context)!.seit) widget.aufreiseSeit = reiseDatum;
                if(context.mounted && text == AppLocalizations.of(context)!.bis) widget.aufreiseBis = reiseDatum;

                setState(() {});
              },
            )
          ]),
        ),
      );
    }

    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context)!.aufReiseAendern,
        ),
        body: Align(
          child: Column(children: [
            aufreiseDropdownButton,
            if(!noTraveling) aufreiseBox(
                AppLocalizations.of(context)!.seit,
                widget.aufreiseSeit,
            ),
            if(pastTravler) aufreiseBox(
                AppLocalizations.of(context)!.bis,
                widget.aufreiseBis,
            ),
            if(stillTraveling) Container(
              margin: const EdgeInsets.only(left: 10),
              width: 600,
              child: Row(children: [
                Text(AppLocalizations.of(context)!.bis, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 20),
                Text(AppLocalizations.of(context)!.offen, style: const TextStyle(fontSize: 20)),
              ],),
            ),
            const SizedBox(height: 20),
            FloatingActionButton.extended(
                label: Text(
                  AppLocalizations.of(context)!.speichern,
                  style: const TextStyle(fontSize: 20),
                ),
                onPressed: () => save())
          ]),
        )
    );
  }
}

