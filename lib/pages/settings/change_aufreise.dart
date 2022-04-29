import 'package:familien_suche/global/variablen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../global/global_functions.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';


class ChangeAufreisePage extends StatefulWidget {
  var isGerman;
  var aufreiseSeit;
  var aufreiseBis;

  ChangeAufreisePage({this.aufreiseSeit, this.aufreiseBis, this.isGerman, Key key}) : super(key: key);

  @override
  _ChangeAufreisePageState createState() => _ChangeAufreisePageState();
}

class _ChangeAufreisePageState extends State<ChangeAufreisePage> {
  var reiseStatus = "";
  var aufreiseDropdownButton = CustomDropDownButton();

  @override
  void initState() {
    setReiseStatus();

    aufreiseDropdownButton = CustomDropDownButton(
      items: widget.isGerman ? aufreise : aufreiseEnglisch,
      selected: reiseStatus,
      onChange: (){
        setState(() {

        });
      },
    );



    super.initState();
  }

  setReiseStatus(){
    if(widget.aufreiseSeit == null){
      reiseStatus = reiseStatus = widget.isGerman ? aufreise[0] : aufreiseEnglisch[0];
    } else if(widget.aufreiseBis == null){
      reiseStatus = reiseStatus = widget.isGerman ? aufreise[2] : aufreiseEnglisch[2];
    }
    reiseStatus = reiseStatus = widget.isGerman ? aufreise[1] : aufreiseEnglisch[1];
  }

  checkValidation(){
    if(aufreiseDropdownButton.selected == aufreise[0]
        || aufreiseDropdownButton.selected == aufreiseEnglisch[0]) return true;

    if(widget.aufreiseSeit == null && widget.aufreiseBis == null &&
        (aufreiseDropdownButton.selected != aufreise[0]
            || aufreiseDropdownButton.selected != aufreiseEnglisch[0] )) {
      customSnackbar(context, "Bitte gib ein, seit wann ihr auf reisen seid/wart");
      return false;
    }

    if(widget.aufreiseSeit == null){
      customSnackbar(context, "Bitte gib ein, seit wann ihr auf reisen seid/wart");
      return false;
    }
    if(widget.aufreiseBis == null && (aufreiseDropdownButton.selected == aufreise[1]
        || aufreiseDropdownButton.selected == aufreiseEnglisch[1] )){
      customSnackbar(context, "Bitte gib ein, bis wann ihr auf reisen wart");
      return false;
    }


    return true;
  }

  saveFunction() async{
    var userId = FirebaseAuth.instance.currentUser.uid;
    var validation = checkValidation();

    if(validation == false) return;

    if(aufreiseDropdownButton.selected == aufreise[0]
        || aufreiseDropdownButton.selected == aufreiseEnglisch[0]){
      ProfilDatabase().updateProfil(
          "aufreiseSeit = NULL, aufreiseBis = NULL", "WHERE id = '$userId'");
    } else if(aufreiseDropdownButton.selected == aufreise[2]
        || aufreiseDropdownButton.selected == aufreiseEnglisch[2]){
      ProfilDatabase().updateProfil(
          "aufreiseSeit = '${widget.aufreiseSeit.toString()}', aufreiseBis = NULL",
          "WHERE id = '$userId'");
    } else{
      ProfilDatabase().updateProfil(
          "aufreiseSeit = '${widget.aufreiseSeit.toString()}',"
              "aufreiseBis = '${widget.aufreiseBis.toString()}'",
          "WHERE id = '$userId'");
    }

    Navigator.pop(context);

  }

  saveButton(){
    return TextButton(
        child: Icon(Icons.done),
        onPressed: () => saveFunction()
    );
  }


  @override
  Widget build(BuildContext context) {


    aufreiseBox(text, reiseDatum, reiseDatumTyp){
      var aufreiseString = AppLocalizations.of(context).datumAuswaehlen;

      if(reiseDatum != null) {
        var dateFormat = DateFormat('MM-yyyy');
        var dateTime = DateTime(reiseDatum.year, reiseDatum.month, reiseDatum.day);
        aufreiseString = dateFormat.format(dateTime);
      }

      return Padding(
        padding: EdgeInsets.all(10),
        child: Container(
          width: 600,
          child: Row(children: [
            Text(text, style: TextStyle(fontSize: 20),),
            SizedBox(width: 10),
            ElevatedButton(
              child: Text(aufreiseString, style: TextStyle(fontSize: 20)),
              onPressed: () async{
                reiseDatum = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  lastDate: DateTime.now(),
                  firstDate: DateTime(DateTime.now().year - 100),
                );

                if(reiseDatumTyp == "seit") widget.aufreiseSeit = reiseDatum;
                if(reiseDatumTyp == "bis") widget.aufreiseBis = reiseDatum;

                setState(() {});
              },
            )
          ]),
        ),
      );
    }



    return Scaffold(
        appBar: customAppBar(
            title: AppLocalizations.of(context).aufReiseAendern,
            buttons: <Widget>[saveButton()]
        ),
        body: Column(children: [
          aufreiseDropdownButton,
          if(aufreiseDropdownButton.selected != aufreise[0]
              && aufreiseDropdownButton.selected != aufreiseEnglisch[0])
            aufreiseBox(AppLocalizations.of(context).seit, widget.aufreiseSeit, "seit"),
          if(aufreiseDropdownButton.selected == aufreise[1]
              || aufreiseDropdownButton.selected == aufreiseEnglisch[1])
            aufreiseBox(AppLocalizations.of(context).bis, widget.aufreiseBis, "bis"),
          if(aufreiseDropdownButton.selected == aufreise[2]
          || aufreiseDropdownButton.selected == aufreiseEnglisch[2]) Container(
            width: 600,
            child: Row(children: [
              Text(AppLocalizations.of(context).bis, style: TextStyle(fontSize: 20)),
              SizedBox(width: 20),
              Text(AppLocalizations.of(context).offen, style: TextStyle(fontSize: 20)),
            ],),
          )
        ])
    );
  }
}

