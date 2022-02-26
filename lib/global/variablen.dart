import 'package:flutter/material.dart';

List<String> reisearten = ["Fester Standort", "Flugzeug/Unterkünfte",
  "Auto/Unterkünfte", "Wohnmobile/Camping", "Boot"];
List<String> interessenListe = ["Homeschooling", "Freilerner", "Worldschooling"
  "Gemeinsame Aktivitäten", "Weltreise", "Langsam reisen", "Gemeinsam reisen"];
List<String> sprachenListe = ["Deutsch", "Englisch"];

List<String> reiseartenEnglisch = ["fixed location", "airplane/housing", "mobile home/camping", "boat"];
List<String> interessenListeEnglisch = ["homeschooling", "unschooling", "worldschooling"
  "joint activities", "world Travel", "travel slowly", "travel together"];
List<String> sprachenListeEnglisch = ["german", "english"];

Color borderColorGrey = const Color(0xFFDFDDDD);

changeGermanToEnglish(list){
  var englishOutputList = [];
  var checkList = [];
  var englishList = [];

  if(interessenListe.contains(list[0])) {
    checkList = interessenListe;
    englishList = interessenListeEnglisch;
  }
  if(sprachenListe.contains(list[0])){
    checkList = sprachenListe;
    englishList = sprachenListeEnglisch;
  }
  if(list.runtimeType == String && checkList.isEmpty){
    var index = reisearten.indexOf(list);
    if(index == -1) return list;
    return reiseartenEnglisch[index];
  }
  if(checkList.isEmpty) return list;

  for(var i = 0; i < list.length; i++){

    var index = checkList.indexOf(list[i]);

    englishOutputList.add(englishList[index]);
  }

  return englishOutputList;
}

changeEnglishToGerman(list){
  var germanOutputList = [];
  var checkList = [];
  var germanList = [];


  if(interessenListeEnglisch.contains(list[0])) {
    checkList = interessenListeEnglisch;
    germanList = interessenListe;
  }
  if(sprachenListeEnglisch.contains(list[0])){
    checkList = sprachenListeEnglisch;
    germanList = sprachenListe;
  }

  if(list.runtimeType == String && checkList.isEmpty){
    var index = reiseartenEnglisch.indexOf(list);
    if(index == -1) return list;

    return reisearten[index];
  }
  if(checkList.isEmpty) return list;

  for(var i = 0; i < list.length; i++){
    var index = checkList.indexOf(list[i]);
    germanOutputList.add(germanList[index]);
  }

  return germanOutputList;
}