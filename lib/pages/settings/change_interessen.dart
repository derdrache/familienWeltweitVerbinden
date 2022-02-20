import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';

import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;



class ChangeInteressenPage extends StatelessWidget {
  var userId;
  var selected;
  var interessenInputBox;

  ChangeInteressenPage({
    Key? key,
    required this.userId,
    required this.selected
  }) :
        interessenInputBox = CustomMultiTextForm(
            auswahlList: Platform.localeName == "de_DE" ?
            global_variablen.interessenListe : global_variablen.interessenListeEnglisch,
            selected: selected,
        );


  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: (){

          if(interessenInputBox.getSelected() == null || interessenInputBox.getSelected().isEmpty){
            customSnackbar(context, AppLocalizations.of(context)!.interessenAuswaehlen);
          } else {
            ProfilDatabase().updateProfil(
                userId, {"interessen": interessenInputBox.getSelected()}
            );
            Navigator.pop(context);
          }


        },
      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context)!.interessenVeraendern, buttons: [saveButton()]),
      body: interessenInputBox,
    );
  }
}
