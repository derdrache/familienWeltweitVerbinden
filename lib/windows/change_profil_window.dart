import 'package:flutter/material.dart';


_topBar(context, titel, Function saveFunction){
  return Row(
    children: [
      TextButton(
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                )
            )
        ),
        child: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      Expanded(child: Center(child: Text(titel))),
      TextButton(
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  )
              )
          ),
          child: Icon(Icons.done),
          onPressed: (){
            saveFunction();
          }
      ),
    ],
  );
}

profilChangeWindow(context, String titel, Widget changeWidget, saveFunction){
  return showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          //backgroundColor: Colors.white,
          contentPadding: EdgeInsets.fromLTRB(10, 20, 10, 20),
          content: Container(
            height: 400,
            width: double.maxFinite,
            child: Column(
              children: [
                _topBar(context, titel, saveFunction),
                changeWidget
              ],
            ),
          ),
        );
      }
  );
}
