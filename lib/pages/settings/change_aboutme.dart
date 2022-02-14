import 'package:flutter/material.dart';
import '../../global/custom_widgets.dart';
import '../../services/database.dart';


class ChangeAboutmePage extends StatelessWidget {
  var userId;
  var bioTextKontroller;


  ChangeAboutmePage({Key? key,required this.userId,required this.bioTextKontroller}) : super(key: key);

  @override
  Widget build(BuildContext context) {


    saveButton(){
      return TextButton(
        child: Icon(Icons.done),
        onPressed: (){
          ProfilDatabase().updateProfil(
              userId, {"aboutme": bioTextKontroller.text});
          Navigator.pop(context);
        }
      );
    }

    return Scaffold(
      appBar: customAppBar(title: "Über mich verändern", button: saveButton()),
      body:customTextInput("über mich", bioTextKontroller, moreLines: 10)

    );
  }
}
