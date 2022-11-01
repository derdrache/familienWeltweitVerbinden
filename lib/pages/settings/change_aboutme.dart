import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';


class ChangeAboutmePage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var oldText;
  var textKontroller = TextEditingController();

  ChangeAboutmePage({Key key,this.oldText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    textKontroller.text = oldText;

    saveButton(){
      return IconButton(
        icon: const Icon(Icons.done),
        onPressed: () async {
          await ProfilDatabase().updateProfil("aboutme = '${textKontroller.text}'",
              "WHERE id = '$userId'");
          updateHiveOwnProfil("aboutme", textKontroller.text);

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
              textKontroller,
            moreLines: 10,
            hintText: AppLocalizations.of(context).aboutusHintText,
            textInputAction: TextInputAction.newline
          )
        ],
      )


    );
  }
}
