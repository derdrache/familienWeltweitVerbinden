import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeTradePage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var textKontroller;

  ChangeTradePage({Key key, this.textKontroller}) : super(key: key);

  @override
  Widget build(BuildContext context) {


    saveButton(){
      return IconButton(
          icon: const Icon(Icons.done),
          onPressed: () async {
            await ProfilDatabase().updateProfil("tradeNotize = '${textKontroller.text}'",
                "WHERE id = '$userId'");
            customSnackbar(context,
                AppLocalizations.of(context).verkaufenTauschenSchenken + " "+
                    AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
            Navigator.pop(context);
          }
      );
    }

    return Scaffold(
        appBar: CustomAppBar(
            title: AppLocalizations.of(context).tradeVeraendern,
            buttons: [saveButton()]
        ),
        body: Column(
          children: [
            customTextInput(
                AppLocalizations.of(context).verkaufenTauschenSchenken,
                textKontroller,
                moreLines: 10,
                hintText: AppLocalizations.of(context).tradeHintText
            )
          ],
        )


    );
  }
}


