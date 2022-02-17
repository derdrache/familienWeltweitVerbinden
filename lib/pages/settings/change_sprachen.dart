import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ChangeSprachenPage extends StatelessWidget {
  var userId;
  var sprachenInputBox = CustomMultiTextForm(
      auswahlList: global_variablen.sprachenListe);

  ChangeSprachenPage({Key? key,required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: (){
          if(sprachenInputBox.getSelected() == null || sprachenInputBox.getSelected().isEmpty){
            customSnackbar(context, AppLocalizations.of(context)!.spracheAuswaehlen);
          } else {
            ProfilDatabase().updateProfil(
                userId, {"sprachen": sprachenInputBox.getSelected()}
            );
            Navigator.pop(context);
          }
        },
      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context)!.spracheVeraendern, button: saveButton()),
      body: sprachenInputBox,
    );
  }
}
