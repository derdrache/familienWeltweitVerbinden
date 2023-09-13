import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_dropdown_button.dart';

class ChangeReiseartPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String oldInput;
  CustomDropdownButton reiseArtInput;
  final bool isGerman;

  ChangeReiseartPage({Key? key, required this.oldInput, required this.isGerman})
      : reiseArtInput = CustomDropdownButton(
          items: isGerman
              ? global_variablen.reisearten
              : global_variablen.reiseartenEnglisch,
          selected: oldInput,
        ), super(key: key);

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
          title: AppLocalizations.of(context)!.reiseartAendern
      ),
      body: reiseArtInput
    );
  }
}
