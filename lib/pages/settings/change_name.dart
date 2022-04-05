import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangeNamePage extends StatelessWidget {
  var userId;
  var oldName;

  ChangeNamePage({Key key,this.userId,this.oldName}) : nameKontroller = TextEditingController(text:oldName);
  var nameKontroller;



  @override
  Widget build(BuildContext context) {
    nameKontroller.text = oldName;

    saveFunction() async{
      if(nameKontroller.text == ""){
        customSnackbar(context, AppLocalizations.of(context).neuenNamenEingeben);
      } else{

        var userName = FirebaseAuth.instance.currentUser.displayName;
        var newUserName = nameKontroller.text;
        newUserName = newUserName.replaceAll("'" , "\\'");

        var checkUserProfilExist = await ProfilDatabase()
            .getData("id", "WHERE name = '${newUserName}'");
        if(checkUserProfilExist == false){

          await ProfilDatabase().updateProfilName(
              userId, userName, newUserName
          );

          Navigator.pop(context);
        } else if(newUserName.length > 40){
          customSnackbar(context, AppLocalizations.of(context).usernameZuLang);
        } else {
          customSnackbar(context, AppLocalizations.of(context).usernameInVerwendung);
        }
      }
    }

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: () => saveFunction()
      );
    }

    return Scaffold(
      appBar: customAppBar(title: AppLocalizations.of(context).nameAendern, buttons: [saveButton()]),
      body: Column(
          children: [
          customTextInput(
          "Name", nameKontroller,
          onSubmit: () =>saveFunction())
          ]) ,
    );
  }
}
