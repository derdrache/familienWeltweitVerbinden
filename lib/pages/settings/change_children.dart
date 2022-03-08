import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangeChildrenPage extends StatelessWidget {
  var userId;
  var childrenBirthdatePickerBox;

  ChangeChildrenPage({Key key,this.userId,this.childrenBirthdatePickerBox}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: () async{
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
                userId, "kinder", childrenBirthdatePickerBox.getDates());
            customSnackbar(context,
                AppLocalizations.of(context).anzahlUndAlterKinder +" "+
                    AppLocalizations.of(context).erfolgreichGeaender, color: Colors.green);
            Navigator.pop(context);
          }
        },

      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context).kinderAendern, buttons: [saveButton()]),
      body: childrenBirthdatePickerBox,
    );
  }
}
