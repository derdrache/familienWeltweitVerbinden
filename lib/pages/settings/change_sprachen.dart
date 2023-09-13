import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/profil_sprachen.dart';
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_multi_select.dart';

class ChangeSprachenPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final List selected;
  final bool isGerman;

  ChangeSprachenPage({Key? key, required this.selected, required this.isGerman})
      : sprachenInputBox = CustomMultiTextForm(
            selected: selected,
            auswahlList: isGerman
                ? ProfilSprachen().getAllGermanLanguages()
                : ProfilSprachen().getAllEnglishLanguages()),
        super(key: key);

  CustomMultiTextForm sprachenInputBox;

  @override
  Widget build(BuildContext context) {
    sprachenInputBox.hintText = AppLocalizations.of(context)!.spracheAuswaehlen;


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
          title: AppLocalizations.of(context)!.spracheVeraendern,
      ),
      body: ListView(children: [
        sprachenInputBox,
      ])
    );
  }
}
