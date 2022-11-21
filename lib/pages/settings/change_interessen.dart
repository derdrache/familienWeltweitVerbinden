import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import '../../widgets/custom_appbar.dart';

class ChangeInteressenPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  List selected;
  var interessenInputBox;
  final bool isGerman;

  ChangeInteressenPage({Key key, this.selected, this.isGerman})
      : interessenInputBox = CustomMultiTextForm(
          auswahlList: isGerman
              ? global_variablen.interessenListe
              : global_variablen.interessenListeEnglisch,
          selected: selected,
        ), super(key: key);

  @override
  Widget build(BuildContext context) {

    save(){
      if (interessenInputBox.getSelected() == null ||
          interessenInputBox.getSelected().isEmpty) {
        customSnackbar(
            context, AppLocalizations.of(context).interessenAuswaehlen);
        return;
      }

      ProfilDatabase().updateProfil(
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

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).interessenVeraendern,
          buttons: [
            IconButton(
                icon: const Icon(Icons.done),
                onPressed: () => save()
            )
          ]
      ),
      body: interessenInputBox,
    );
  }
}
