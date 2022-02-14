import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';

class ChangeNamePage extends StatelessWidget {
  var userId;
  var nameKontroller;

  ChangeNamePage({Key? key,required this.userId,required this.nameKontroller}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: () async{
          if(nameKontroller.text == ""){
            customSnackbar(context, "Neuen Namen eingeben");
          } else{
            var userName = FirebaseAuth.instance.currentUser!.displayName;
            var checkUserProfilExist = await ProfilDatabase().getProfilFromName(nameKontroller.text);

            if(checkUserProfilExist == null){
              ProfilDatabase().updateProfilName(
                  userId, userName, nameKontroller.text
              );
              Navigator.pop(context);
            } else {
              customSnackbar(context, "Name schon vorhanden");
            }
          }
        },
      );
    }

    return Scaffold(
      appBar: customAppBar(title: "Name ändern", button: saveButton()),
      body: customTextInput("Name", nameKontroller),
    );
  }
}
