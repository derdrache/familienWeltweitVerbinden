import 'package:flutter/material.dart';


checkValidatorEmpty(){
  return (value){
    if(value == null || value.isEmpty){
      return "Bitte Passwort eingeben";
    }
    return null;
  };
}

checkValidatorPassword(password){
 return (value){
   if(value == null || value.isEmpty){
     return "Bitte Passwort eingeben";
   } else if(value != password){
     return "Passwort stimmt nicht überein";
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

timeStampToAllDict(timestamp){
  DateTime dateTime = timestamp.toDate();
  String dateTimeString = dateTime.toString();

  dateTime = DateTime.parse(dateTimeString.split(" ")[0]);
  dateTimeString = dateTimeString.split(" ")[0].toString();

  var yearsFromDateTime = DateTime.now().difference(dateTime).inDays ~/ 365;

  return {
    "date": dateTime,
    "string": dateTimeString.split("-").reversed.join("-"),
    "years": yearsFromDateTime
  };
}

getAgeFromDateTime(dateTime){

}

