import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/style.dart' as style;
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/layout/custom_snackbar.dart';

class ChangeChildrenPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  var childrenBirthdatePickerBox;

  ChangeChildrenPage({Key? key,this.childrenBirthdatePickerBox}) : super(key: key);



  @override
  Widget build(BuildContext context) {

    save() async {
      bool allFilled = true;

      for(var kindAge in childrenBirthdatePickerBox.getDates()){
        if (kindAge == null){
          allFilled = false;
        }
      }

      if(!allFilled || childrenBirthdatePickerBox.getDates().isEmpty){
        customSnackBar(context, AppLocalizations.of(context)!.geburtsdatumEingeben);
      } else{
        await ProfilDatabase().updateProfil(
            "kinder = '${jsonEncode(childrenBirthdatePickerBox.getDates())}'",
            "WHERE id = '$userId'");

        updateHiveOwnProfil("kinder", childrenBirthdatePickerBox.getDates());

        if (context.mounted){
          customSnackBar(context,
              "${AppLocalizations.of(context)!.anzahlUndAlterKinder} ${AppLocalizations.of(context)!.erfolgreichGeaender}",
              color: Colors.green
          );
          Navigator.pop(context);
        }
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context)!.kinderAendern,
      ),
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(children: [
          childrenBirthdatePickerBox,
          const SizedBox(height: 10),
          FloatingActionButton.extended(
              label: Text(
                AppLocalizations.of(context)!.speichern,
                style: const TextStyle(fontSize: 20),
              ),
              onPressed: () => save())
        ],),
      )


      ,



    );
  }
}
