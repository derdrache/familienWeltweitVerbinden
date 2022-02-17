import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangeReiseartPage extends StatelessWidget {
  var userId;
  var oldInput;
  var reiseArtInput = CustomDropDownButton(items: Platform.localeName == "de_DE" ?
  global_variablen.reisearten : global_variablen.reiseartenEnglisch);

  ChangeReiseartPage({Key? key,required this.userId,required this.oldInput}) : super(key: key);



  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: () {
          if(reiseArtInput.getSelected() == null || reiseArtInput.getSelected().isEmpty){
            customSnackbar(context, AppLocalizations.of(context)!.reiseartAuswaehlen);
          } else if(reiseArtInput.getSelected() != oldInput ){
            ProfilDatabase().updateProfil(
                userId, {"reiseart": reiseArtInput.getSelected()}
            );
            Navigator.pop(context);
          }
        },
      );

    }


    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context)!.reiseartAendern, button: saveButton()),
      body: reiseArtInput,
    );
  }
}



