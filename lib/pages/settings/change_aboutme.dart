import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ChangeAboutmePage extends StatelessWidget {
  var userId;
  var bioTextKontroller;


  ChangeAboutmePage({Key? key,required this.userId,required this.bioTextKontroller}) : super(key: key);

  @override
  Widget build(BuildContext context) {


    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: (){
          ProfilDatabase().updateProfil(
              userId, {"aboutme": bioTextKontroller.text});
          Navigator.pop(context);
        }
      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context)!.ueberMichVeraendern, button: saveButton()),
      body:customTextInput(AppLocalizations.of(context)!.ueberMich, bioTextKontroller, moreLines: 10)

    );
  }
}
