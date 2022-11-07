import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import '../../widgets/custom_appbar.dart';

class ChangeInteressenPage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var selected;
  var interessenInputBox;
  var isGerman;

  ChangeInteressenPage({Key key, this.selected, this.isGerman})
      : interessenInputBox = CustomMultiTextForm(
          auswahlList: isGerman
              ? global_variablen.interessenListe
              : global_variablen.interessenListeEnglisch,
          selected: selected,
        ), super(key: key);

  @override
  Widget build(BuildContext context) {
    saveButton() {
      return IconButton(
        icon: const Icon(Icons.done),
        onPressed: () async {
          if (interessenInputBox.getSelected() == null ||
              interessenInputBox.getSelected().isEmpty) {
            customSnackbar(
                context, AppLocalizations.of(context).interessenAuswaehlen);
          } else {
            await ProfilDatabase().updateProfil(
                "interessen = '${jsonEncode(interessenInputBox.getSelected())}'",
                "WHERE id = '$userId'");
            updateHiveOwnProfil("interessen", interessenInputBox.getSelected());

            customSnackbar(
                context,
                AppLocalizations.of(context).interessen +
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
          title: AppLocalizations.of(context).interessenVeraendern,
          buttons: [saveButton()]),
      body: interessenInputBox,
    );
  }
}
