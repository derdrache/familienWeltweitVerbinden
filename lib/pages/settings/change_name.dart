import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeNamePage extends StatelessWidget {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var oldName;

  ChangeNamePage({Key key, this.oldName})
      : nameKontroller = TextEditingController(text: oldName);
  var nameKontroller;

  @override
  Widget build(BuildContext context) {
    nameKontroller.text = oldName;

    saveFunction() async {
      if (nameKontroller.text == "") {
        customSnackbar(
            context, AppLocalizations.of(context).neuenNamenEingeben);
      } else {
        var userName = FirebaseAuth.instance.currentUser.displayName;
        var newUserName = nameKontroller.text;
        newUserName = newUserName.replaceAll("'", "\\'");

        var checkUserProfilExist = await ProfilDatabase()
            .getData("id", "WHERE name = '${newUserName}'");
        if (checkUserProfilExist == false) {
          await ProfilDatabase()
              .updateProfilName(userId, userName, newUserName);
          updateHiveOwnProfil("name", newUserName);

          Navigator.pop(context);
        } else if (newUserName.length > 40) {
          customSnackbar(context, AppLocalizations.of(context).usernameZuLang);
        } else {
          customSnackbar(
              context, AppLocalizations.of(context).usernameInVerwendung);
        }
      }
    }

    saveButton() {
      return IconButton(
          icon: const Icon(Icons.done), onPressed: () => saveFunction());
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).nameAendern,
          buttons: [saveButton()]),
      body: Container(
        margin: const EdgeInsets.only(top: 20),
        child: Column(children: [
          customTextInput("Name", nameKontroller,
              onSubmit: () => saveFunction())
        ]),
      ),
    );
  }
}
