import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';

class ChangeChildrenPage extends StatelessWidget {
  var userId;
  var childrenBirthdatePickerBox;

  ChangeChildrenPage({Key? key,required this.userId,required this.childrenBirthdatePickerBox}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: (){
          bool allFilled = true;

          for(var kindAge in childrenBirthdatePickerBox.getDates()){
            if (kindAge == null){
              allFilled = false;
            }
          }

          if(!allFilled || childrenBirthdatePickerBox.getDates().isEmpty){
            customSnackbar(context, "Geburtsdaten eingeben");
          } else{
            ProfilDatabase().updateProfil(
                userId, {"kinder": childrenBirthdatePickerBox.getDates()}
            );
            Navigator.pop(context);
          }
        },

      );
    }

    return Scaffold(
      appBar: customAppBar(title: "Kinder ändern", button: saveButton()),
      body: childrenBirthdatePickerBox,
    );
  }
}
