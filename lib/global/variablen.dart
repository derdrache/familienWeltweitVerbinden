List<String> reisearten = ["Fester Standort", "Flugzeug/Unterkünfte", "Wohnmobile/Camping", "Boot"];
List<String> interessenListe = ["Homeschooling", "Freilerner",
  "Gemeinsame Aktivitäten", "Weltreise", "Langsam reisen", "Gemeinsam reisen"];
List<String> sprachenListe = ["Deutsch", "Englisch"];

List<String> reiseartenEnglisch = ["Fixed location", "Airplane/Housing", "Mobile home/Camping", "Boat"];
List<String> interessenListeEnglisch = ["Homeschooling", "Unschooling",
  "Joint activities", "World Travel", "Travel slowly", "Travel together"];
List<String> sprachenListeEnglisch = ["German", "English"];

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
    print(checkList);
    print(list[i]);
    var index = checkList.indexOf(list[i]);
    germanOutputList.add(germanList[index]);
  }

  return germanOutputList;
}