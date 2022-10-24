import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeReiseartPage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var oldInput;
  var reiseArtInput;
  var selected;
  var isGerman;

  ChangeReiseartPage({Key key, this.oldInput, this.isGerman})
      : reiseArtInput = CustomDropDownButton(
          items: isGerman
              ? global_variablen.reisearten
              : global_variablen.reiseartenEnglisch,
          selected: oldInput,
        );

  @override
  Widget build(BuildContext context) {
    saveButton() {
      return IconButton(
        icon: const Icon(Icons.done),
        onPressed: () async {
          if (reiseArtInput.getSelected() == null ||
              reiseArtInput.getSelected().isEmpty) {
            customSnackbar(
                context, AppLocalizations.of(context).reiseartAuswaehlen);
          } else if (reiseArtInput.getSelected() != oldInput) {
            await ProfilDatabase().updateProfil(
                "reiseart = '${reiseArtInput.getSelected()}'",
                "WHERE id = '$userId'");
            updateHiveProfil("reiseart", reiseArtInput.getSelected());

            customSnackbar(
                context,
                AppLocalizations.of(context).artDerReise +
                    " " +
                    AppLocalizations.of(context).erfolgreichGeaender,
                color: Colors.green);
            Navigator.pop(context);
          }
        },
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).reiseartAendern,
          buttons: [saveButton()]),
      body: reiseArtInput,
    );
  }
}
