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
