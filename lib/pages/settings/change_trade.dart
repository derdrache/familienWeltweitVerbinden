import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeTradePage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String oldText;
  TextEditingController textKontroller = TextEditingController();

  ChangeTradePage({Key? key, required this.oldText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    textKontroller.text = oldText;

    save() {
      String text = textKontroller.text;

      updateHiveOwnProfil("tradeNotize", text);

      text = text.replaceAll("'", "''");

      ProfilDatabase().updateProfil(
          "tradeNotize = '$text'", "WHERE id = '$userId'");



      customSnackbar(
          context,
          AppLocalizations.of(context)!.verkaufenTauschenSchenken +
              " " +
              AppLocalizations.of(context)!.erfolgreichGeaender,
          color: Colors.green);

      Navigator.pop(context);
    }

    return Scaffold(
        appBar:
            CustomAppBar(title: AppLocalizations.of(context)!.tradeVeraendern),
        body: Column(
          children: [
            customTextInput(
                AppLocalizations.of(context)!.verkaufenTauschenSchenken,
                textKontroller,
                moreLines: 15,
                textInputAction: TextInputAction.newline,
                hintText: AppLocalizations.of(context)!.tradeHintText),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
                label: Text(
                  AppLocalizations.of(context)!.speichern,
                  style: const TextStyle(fontSize: 20),
                ),
                icon: const Icon(Icons.save),
                onPressed: () => save())
          ],
        ));
  }
}
