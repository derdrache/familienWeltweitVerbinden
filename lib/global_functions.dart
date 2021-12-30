import 'package:flutter/material.dart';

checkValidatorEmail(){
  return (value){
    if(value == null || value.isEmpty){
      return "Bitte Email Adresse eingeben";
    }
    else if(!value.contains("@")){
      return "Bitte gültige Email Adresse eingeben";
    }
    return null;
  };
}

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
