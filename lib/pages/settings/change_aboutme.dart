import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';


class ChangeAboutmePage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String oldText;
  TextEditingController textKontroller = TextEditingController();

  ChangeAboutmePage({Key? key,this.oldText = ""}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    textKontroller.text = oldText;

    save(newText){
      updateHiveOwnProfil("aboutme", textKontroller.text);

      newText = newText.replaceAll("'","''");
      ProfilDatabase().updateProfil("aboutme = '$newText'", "WHERE id = '$userId'");
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.ueberMichVeraendern,
      ),
      body: Column(
        children: [
          CustomTextInput(
            AppLocalizations.of(context)!.ueberMich,
            textKontroller,
            moreLines: 10,
            hintText: AppLocalizations.of(context)!.aboutusHintText,
            textInputAction: TextInputAction.newline
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
              label: Text(AppLocalizations.of(context)!.speichern, style: const TextStyle(fontSize: 20),),
              icon: const Icon(Icons.save),
              onPressed: (){
                String newText = textKontroller.text;

                if(newText.isEmpty){
                  customSnackBar(context,
                      AppLocalizations.of(context)!.keineEingabe, color: Colors.red);
                  return;
                }

                save(newText);

                customSnackBar(context,
                    "${AppLocalizations.of(context)!.ueberMich} ${AppLocalizations.of(context)!.erfolgreichGeaender}", color: Colors.green);
                Navigator.pop(context);
              }
          )
        ],

      )
    );
  }
}
