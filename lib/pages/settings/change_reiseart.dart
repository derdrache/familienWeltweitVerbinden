import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeReiseartPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  String oldInput;
  var reiseArtInput;
  final bool isGerman;

  ChangeReiseartPage({Key key, this.oldInput, this.isGerman})
      : reiseArtInput = CustomDropDownButton(
          items: isGerman
              ? global_variablen.reisearten
              : global_variablen.reiseartenEnglisch,
          selected: oldInput,
        );

  @override
  Widget build(BuildContext context) {

    save() {
      if (reiseArtInput.getSelected() == null ||
          reiseArtInput.getSelected().isEmpty) {
        return;
      } else if (reiseArtInput.getSelected() != oldInput) {
        ProfilDatabase().updateProfil(
            "reiseart = '${reiseArtInput.getSelected()}'",
            "WHERE id = '$userId'");
        updateHiveOwnProfil("reiseart", reiseArtInput.getSelected());
      }
    }

    reiseArtInput.onChange = ()=>save();

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).reiseartAendern
      ),
      body: reiseArtInput
    );
  }
}
