import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


checkValidatorEmpty(){
  return (value){
    if(value == null || value.isEmpty){
      return "Dieses Feld bitte ausfüllen";
    }
    return null;
  };
}

checkValidationEmail(){
  return (value){
    bool emailIsValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(value);

    if(value == null || value.isEmpty){
      return "Bitte Email eingeben";
    } else if(!emailIsValid){
      return "Bitte gültige Email eingeben";
    }
  };
}

checkValidatorPassword({passwordCheck = ""}){
 return (value){
   if(value == null || value.isEmpty){
     return "Bitte Passwort eingeben";
   } else if(passwordCheck!= "" && value != passwordCheck){
     return "Passwort stimmt nicht überein";
   }
   return null;
 };
}

checkValidationMultiTextForm(){
  return (value){
    if(value == null || value.isEmpty){
      return "Bitte auswählen";
    }
    return null;
  };
}



changePage(context, page){
  Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page)
  );
}

timeStampToAllDict(dateTimeString){
  DateTime dateTime = DateTime.parse(dateTimeString.split(" ")[0]);
  dateTimeString = dateTimeString.split(" ")[0].toString();

  var yearsFromDateTime = DateTime.now().difference(dateTime).inDays ~/ 365;

  return {
    "date": dateTime,
    "string": dateTimeString.split("-").reversed.join("-"),
    "years": yearsFromDateTime
  };
}

dbSecondsToTimeString(seconds){
  DateTime secondsToDateTime = DateTime.fromMillisecondsSinceEpoch(seconds*1000);
  var dateTimeToTime = DateFormat.Hm().format(secondsToDateTime);

  return dateTimeToTime;
}

