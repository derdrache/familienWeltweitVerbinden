import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';


class ChangeAboutmePage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  final String oldText;
  TextEditingController textKontroller = TextEditingController();

  ChangeAboutmePage({Key key,this.oldText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    textKontroller.text = oldText;

    save() async{
      String text = textKontroller.text;

      updateHiveOwnProfil("aboutme", textKontroller.text);

      text = text.replaceAll("'","''");
      await ProfilDatabase().updateProfil("aboutme = '$text'", "WHERE id = '$userId'");


      customSnackbar(context,
          AppLocalizations.of(context).ueberMich + " "+
              AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
      Navigator.pop(context);
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).ueberMichVeraendern,
      ),
      body: Column(
        children: [
          customTextInput(
            AppLocalizations.of(context).ueberMich,
            textKontroller,
            moreLines: 10,
            hintText: AppLocalizations.of(context).aboutusHintText,
            textInputAction: TextInputAction.newline
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
              label: Text(AppLocalizations.of(context).speichern, style: const TextStyle(fontSize: 20),),
              icon: const Icon(Icons.save),
              onPressed: () => save()
          )
        ],

      )
    );
  }
}
