import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';


class ChangeAboutmePage extends StatelessWidget {
  var userId;
  var bioTextKontroller;


  ChangeAboutmePage({Key key,this.userId,this.bioTextKontroller}) : super(key: key);

  @override
  Widget build(BuildContext context) {


    saveButton(){
      return IconButton(
        icon: Icon(Icons.done),
        onPressed: () async {
          await ProfilDatabase().updateProfil("aboutme = '${bioTextKontroller.text}'",
              "WHERE id = '$userId'");
          customSnackbar(context,
              AppLocalizations.of(context).ueberMich + " "+
                  AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
          Navigator.pop(context);
        }
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).ueberMichVeraendern,
          buttons: [saveButton()]
      ),
      body: Column(
        children: [
          customTextInput(
            AppLocalizations.of(context).ueberMich,
            bioTextKontroller,
            moreLines: 10,
            hintText: AppLocalizations.of(context).aboutusHintText
          )
        ],
      )


    );
  }
}
