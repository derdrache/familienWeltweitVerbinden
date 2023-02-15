import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database/database.dart';
import '../../global/variablen.dart' as global_variablen;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeSprachenPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  final List selected;
  final bool isGerman;

  ChangeSprachenPage({Key key, this.selected, this.isGerman})
      : sprachenInputBox = CustomMultiTextForm(
            selected: selected,
            auswahlList: isGerman
                ? global_variablen.sprachenListe
                : global_variablen.sprachenListeEnglisch),
        super(key: key);

  var sprachenInputBox;

  @override
  Widget build(BuildContext context) {
    sprachenInputBox.hintText = AppLocalizations.of(context).spracheAuswaehlen;


    save() {
      if (sprachenInputBox.getSelected() == null ||
          sprachenInputBox.getSelected().isEmpty) {
        return;
      }

      ProfilDatabase().updateProfil(
          "sprachen = '${jsonEncode(sprachenInputBox.getSelected())}'",
          "WHERE id = '$userId'");

      updateHiveOwnProfil("sprachen", sprachenInputBox.getSelected());
    }


    sprachenInputBox.onConfirm = () => save();

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).spracheVeraendern,
      ),
      body: ListView(children: [
        sprachenInputBox,
      ])
    );
  }
}
