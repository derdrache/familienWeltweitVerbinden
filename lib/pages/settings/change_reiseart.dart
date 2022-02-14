import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;

class ChangeReiseartPage extends StatelessWidget {
  var userId;
  var oldInput;
  var reiseArtInput = CustomDropDownButton(items: global_variablen.reisearten);

  ChangeReiseartPage({Key? key,required this.userId,required this.oldInput}) : super(key: key);



  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: () {
          if(reiseArtInput.getSelected() == null || reiseArtInput.getSelected().isEmpty){
            customSnackbar(context, "neue Reiseart eingeben");
          } else if(reiseArtInput.getSelected() != oldInput ){
            ProfilDatabase().updateProfil(
                userId, {"reiseart": reiseArtInput.getSelected()}
            );
            Navigator.pop(context);
          }
        },
      );

    }


    return Scaffold(
      appBar: customAppBar(title: "Art der Reise ändern", button: saveButton()),
      body: reiseArtInput,
    );
  }
}



