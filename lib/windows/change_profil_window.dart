import 'package:flutter/material.dart';
import '../global/style.dart' as global_style;


class ProfilChangeWindow{
  BuildContext context;
  String titel;
  Widget changeWidget;
  Function saveFunction;

  ProfilChangeWindow({required this.context, required this.titel,
    required this.changeWidget, required this.saveFunction});


  _topBar(){
    return Row(
      children: [
        TextButton(
          style: global_style.textButtonStyle(),
          child: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(child: Center(child: Text(titel))),
        TextButton(
            style: global_style.textButtonStyle(),
            child: const Icon(Icons.done),
            onPressed: (){
              saveFunction();
            }
        ),
      ],
    );
  }

  profilChangeWindow(){
    return showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            content: Scaffold(
              body: SizedBox(
                height: 400,
                width: double.maxFinite,
                child: Column(
                  children: [
                    _topBar(),
                    changeWidget
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

}


