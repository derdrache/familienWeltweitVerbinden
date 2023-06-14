import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import '../../widgets/custom_appbar.dart';

class ChangeInteressenPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List selected;
  var interessenInputBox;
  final bool isGerman;

  ChangeInteressenPage({Key? key, required this.selected, required this.isGerman})
      : interessenInputBox = CustomMultiTextForm(
          auswahlList: isGerman
              ? global_variablen.interessenListe
              : global_variablen.interessenListeEnglisch,
          selected: selected,
        ), super(key: key);

  @override
  Widget build(BuildContext context) {
    interessenInputBox.hintText = AppLocalizations.of(context)!.interessenAuswaehlen;

    save(){
      if (interessenInputBox.getSelected() == null ||
          interessenInputBox.getSelected().isEmpty) {
        return;
      }

      ProfilDatabase().updateProfil(
          "interessen = '${jsonEncode(interessenInputBox.getSelected())}'",
          "WHERE id = '$userId'");
      updateHiveOwnProfil("interessen", interessenInputBox.getSelected());
    }

    interessenInputBox.onConfirm = () => save();

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.interessenVeraendern,
      ),
      body: ListView(
        children: [
          interessenInputBox,
        ],
      )
    );
  }
}
