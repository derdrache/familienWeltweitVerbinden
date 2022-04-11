import 'package:flutter/material.dart';

Color borderColorGrey = const Color(0xFFDFDDDD);

List<String> reisearten = ["Fester Standort", "Flugzeug/Unterkünfte",
  "Auto/Unterkünfte", "Wohnmobile/Camping", "Boot"];
List<String> interessenListe = ["Homeschooling", "Freilerner", "Worldschooling",
  "Gemeinsame Aktivitäten", "Weltreise", "Langsam reisen", "Gemeinsam reisen"];
List<String> sprachenListe = ["Deutsch", "Englisch"];
List<String> eventInterval = ["einmalig", "täglich","wöchentlich", "monatlich"];
List<String> eventTyp = ["offline", "online"];
List<String> eventArt = ["privat", "halb-öffentlich", "öffentlich"];
List<String> eventZeitzonen = ["+12", "+11", "+10", "+9", "+8", "+7", "+6", "+5"
  "+4", "+3", "+2", "+1", "0", "-1","-2", "-3", "-4", "-5", "-6", "-7", "-8", "-9"
  "-10", "-11", "-12"];

List<String> reiseartenEnglisch = ["fixed location", "airplane/housing",
  "car/housing","mobile home/camping", "boat"];
List<String> interessenListeEnglisch = ["homeschooling", "unschooling", "worldschooling",
  "joint activities", "world Travel", "travel slowly", "travel together"];
List<String> sprachenListeEnglisch = ["german", "english"];
List<String> eventIntervalEnglisch = ["once", "daily", "weekly", "monthly"];
List<String> eventTypEnglisch = ["offline", "online"];
List<String> eventArtEnglisch = ["private", "semi-public", "public"];


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
    var reiseartenIndex = reisearten.indexOf(list);
    var eventIntervalIndex = eventInterval.indexOf(list);
    var eventArtIndex = eventArt.indexOf(list);

    if(reiseartenIndex > -1) return reiseartenEnglisch[reiseartenIndex];
    if(eventIntervalIndex > -1) return eventIntervalEnglisch[eventIntervalIndex];
    if(eventArtIndex > -1) return eventArtEnglisch[eventArtIndex];


    return list;
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
    var reiseartenIndex = reiseartenEnglisch.indexOf(list);
    var eventIntervalIndex = eventIntervalEnglisch.indexOf(list);
    var eventArtIndex = eventArtEnglisch.indexOf(list);

    if(reiseartenIndex > -1) return reisearten[reiseartenIndex];
    if(eventIntervalIndex > -1) return eventInterval[eventIntervalIndex];
    if(eventArtIndex > -1) return eventArt[eventArtIndex];

    return list;
  }
  if(checkList.isEmpty) return list;

  for(var i = 0; i < list.length; i++){
    var index = checkList.indexOf(list[i]);
    germanOutputList.add(germanList[index]);
  }

  return germanOutputList;
}