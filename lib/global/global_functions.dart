import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


checkValidatorEmpty(context) {
  return (value){
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).diesesFeldAusfuellen;
    }
    return null;
  };
}

checkValidationEmail(context){
  return (value){

    bool emailHasAT = value.contains("@");
    bool emailHasEnd = false;
    if(emailHasAT) emailHasEnd = value.split("@")[1].contains(".");

    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).emailEingeben;
    } else if(!emailHasAT || !emailHasEnd){
      return AppLocalizations.of(context).gueltigeEmailEingeben;
    }
  };
}

checkValidatorPassword(context, {passwordCheck = ""}){
 return (value){
   if(value == null || value.isEmpty){
     return AppLocalizations.of(context).passwortEingeben;
   } else if(passwordCheck!= "" && value != passwordCheck){
     return AppLocalizations.of(context).passwortStimmtNichtUeberein;
   }
   return null;
 };
}

checkValidationMultiTextForm(context){
  return (value){
    if(value == null || value.isEmpty){
      return AppLocalizations.of(context).ausfuellen;
    }
    return null;
  };
}

changePage(context, page){
  Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page)
  );
}

changePageForever(context, page){
  Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page)
  );
}


class ChangeTimeStamp{
  var timeStamp;

  ChangeTimeStamp(this.timeStamp);



  intoDate(){
    DateTime dateTime = DateTime.parse(timeStamp.split(" ")[0]);
    return dateTime;
  }

  intoString(){
    var dateTimeString = timeStamp.split(" ")[0].toString();
    return dateTimeString.split("-").reversed.join("-");
  }

  intoYears(){
    DateTime dateTime = DateTime.parse(timeStamp.split(" ")[0]);
    return DateTime.now().difference(dateTime).inDays ~/ 365;
  }


}

getChatID(usersList){
  var sortedList = usersList.toList(growable: false)..sort();
  return sortedList.join("_");
}

createDefaultProfileImage(profil){
  var symbols = "@!?()/[]{}&%'\"\\\$§=-_+*#|<>^°`´.:,;€";


  if(profil["bild"]== null){
    var nameToList = profil["name"].split(" ");
    var imageText = "";

    for(var letter in nameToList[0].split("")){
      if(!symbols.contains(letter)){
        imageText = letter;
        break;
      }
    }

    if(nameToList.length > 1){
      for(var letter in nameToList.last.split("")){
        if(!symbols.contains(letter)){
          imageText += letter;
          break;
        }
      }
    }

    if(profil["bildStandardFarbe"] == null){
      var colorList = [Colors.blue, Colors.red, Colors.orange, Colors.green,
        Colors.purple, Colors.pink, Colors.greenAccent];
      var selectColor = (colorList..shuffle()).first.value;
      profil["bildStandardFarbe"] = selectColor;

      ProfilDatabase().updateProfil(profil["id"], "bildStandardFarbe", selectColor);
    }


    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(profil["bildStandardFarbe"])
      ),
      child: Center(
          child: Text(
              imageText.toUpperCase(),
            style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold, color: Colors.white),
          )
      )
    );
  }
}

