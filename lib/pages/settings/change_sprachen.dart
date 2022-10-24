import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeSprachenPage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var selected;
  var isGerman;

  ChangeSprachenPage({Key key, this.selected, this.isGerman})
      : sprachenInputBox = CustomMultiTextForm(
            selected: selected,
            auswahlList: isGerman
                ? global_variablen.sprachenListe
                : global_variablen.sprachenListeEnglisch);

  var sprachenInputBox;

  @override
  Widget build(BuildContext context) {
    saveButton() {
      return IconButton(
        icon: const Icon(Icons.done),
        onPressed: () async {
          if (sprachenInputBox.getSelected() == null ||
              sprachenInputBox.getSelected().isEmpty) {
            customSnackbar(
                context, AppLocalizations.of(context).spracheAuswaehlen);
          } else {
            await ProfilDatabase().updateProfil(
                "sprachen = '${jsonEncode(sprachenInputBox.getSelected())}'",
                "WHERE id = '$userId'");

            updateHiveProfil("sprachen", sprachenInputBox.getSelected());

            customSnackbar(
                context,
                AppLocalizations.of(context).sprachen +
                    " " +
                    AppLocalizations.of(context).erfolgreichGeaender,
                color: Colors.green);
            Navigator.pop(context);
          }
        },
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).spracheVeraendern,
          buttons: [saveButton()]),
      body: sprachenInputBox,
    );
  }
}
