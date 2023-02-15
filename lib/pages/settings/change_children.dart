import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/custom_appbar.dart';

class ChangeChildrenPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser.uid;
  var childrenBirthdatePickerBox;

  ChangeChildrenPage({Key key,this.childrenBirthdatePickerBox}) : super(key: key);



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
        customSnackbar(context, AppLocalizations.of(context).geburtsdatumEingeben);
      } else{
        await ProfilDatabase().updateProfil(
            "kinder = '${jsonEncode(childrenBirthdatePickerBox.getDates())}'",
            "WHERE id = '$userId'");

        updateHiveOwnProfil("kinder", childrenBirthdatePickerBox.getDates());


        customSnackbar(context,
            AppLocalizations.of(context).anzahlUndAlterKinder +" "+
                AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
        Navigator.pop(context);
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
          title: AppLocalizations.of(context).kinderAendern,
      ),
      body: Column(children: [
        childrenBirthdatePickerBox,
        const SizedBox(height: 10),
        FloatingActionButton.extended(
            label: Text(
              AppLocalizations.of(context).speichern,
              style: const TextStyle(fontSize: 20),
            ),
            icon: const Icon(Icons.save),
            onPressed: () => save())
      ],)


      ,



    );
  }
}
