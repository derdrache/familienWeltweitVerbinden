import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';
import '../../global/variablen.dart' as global_variablen;



class ChangeInteressenPage extends StatelessWidget {
  var userId;
  var interessenInputBox = CustomMultiTextForm(
      auswahlList: global_variablen.interessenListe);

  ChangeInteressenPage({Key? key, this.userId}) : super(key: key);





  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: (){

          if(interessenInputBox.getSelected() == null || interessenInputBox.getSelected().isEmpty){
            customSnackbar(context, "neue interessen eingeben");
          } else {
            ProfilDatabase().updateProfil(
                userId, {"interessen": interessenInputBox.getSelected()}
            );
            Navigator.pop(context);
          }


        },
      );
    }

    return Scaffold(
      appBar: customAppBar(title: "Interessen verändern", button: saveButton()),
      body: interessenInputBox,
    );
  }
}
