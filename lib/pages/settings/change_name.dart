import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_snackbar.dart';
import '../../widgets/layout/custom_text_input.dart';

class ChangeNamePage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String oldName;
  TextEditingController nameKontroller = TextEditingController();

  ChangeNamePage({Key? key, required this.oldName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    nameKontroller.text = oldName;

    save() async {
      if (nameKontroller.text.isEmpty) {
        customSnackBar(
            context, AppLocalizations.of(context)!.neuenNamenEingeben);
        return;
      }

      var newUserName = nameKontroller.text.replaceAll("'", "''");

      if (newUserName.length > 40) {
        customSnackBar(context, AppLocalizations.of(context)!.usernameZuLang);
        return;
      }

      var checkUserProfilExist =
          await ProfilDatabase().getData("id", "WHERE name = '$newUserName'");
      if (checkUserProfilExist != false && context.mounted) {
        customSnackBar(
            context, AppLocalizations.of(context)!.usernameInVerwendung);
        return;
      }

      await ProfilDatabase().updateProfilName(userId, newUserName);
      updateHiveOwnProfil("name", newUserName);

      if(context.mounted) Navigator.pop(context);
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.nameAendern,),
      body: Container(
        margin: const EdgeInsets.only(top: 20),
        child: Column(children: [
          CustomTextInput("Name", nameKontroller,
              onSubmit: () => save()),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
              label: Text(
                AppLocalizations.of(context)!.speichern,
                style: const TextStyle(fontSize: 20),
              ),
              icon: const Icon(Icons.save),
              onPressed: () => save())
        ]),
      ),
    );
  }
}
