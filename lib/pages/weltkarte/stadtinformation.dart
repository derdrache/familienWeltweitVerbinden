import 'dart:convert';

import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../global/custom_widgets.dart';

class StadtinformationsPage extends StatefulWidget {
  var ort;

  StadtinformationsPage({this.ort, Key key}) : super(key: key);

  @override
  _StadtinformationsPageState createState() => _StadtinformationsPageState();
}

class _StadtinformationsPageState extends State<StadtinformationsPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var cityInformation = {};
  var usersCityInformation = [];


  setThumb(thumb, index) async{
    var infoId = usersCityInformation[index]["id"];

    if(thumb =="up"){
      if(usersCityInformation[index]["thumbUp"].contains(userId)) return;

      setState(() {
        usersCityInformation[index]["thumbUp"].add(userId);
        usersCityInformation[index]["thumbDown"].remove(userId);
      });

      var dbData = await StadtinfoUserDatabase().getData("thumbUp, thumbDown", "WHERE id ='$infoId'");
      var dbThumbUpList = dbData["thumbUp"];
      var dbThumbDownList = dbData["thumbDown"];

      dbThumbUpList.add(userId);
      dbThumbDownList.remove(userId);

      await StadtinfoUserDatabase()
          .update("thumbUp = '${jsonEncode(dbThumbUpList)}', thumbDown = '${jsonEncode(dbThumbDownList)}'", "WHERE id ='$infoId'");


    }else if(thumb == "down"){
      if(usersCityInformation[index]["thumbDown"].contains(userId)) return;

      setState(() {
        usersCityInformation[index]["thumbDown"].add(userId);
        usersCityInformation[index]["thumbUp"].remove(userId);
      });

      var dbData = await StadtinfoUserDatabase().getData("thumbUp, thumbDown", "WHERE id ='$infoId'");
      var dbThumbUpList = dbData["thumbUp"];
      var dbThumbDownList = dbData["thumbDown"];

      dbThumbDownList.add(userId);
      dbThumbUpList.remove(userId);

      await StadtinfoUserDatabase()
          .update("thumbUp = '${jsonEncode(dbThumbUpList)}', thumbDown = '${jsonEncode(dbThumbDownList)}'", "WHERE id ='$infoId'");


    }
  }

  sortThumb(data){
    data.sort((a, b) => (b["thumbUp"].length - b["thumbDown"].length)
        .compareTo(a["thumbUp"].length - a["thumbDown"].length) as int);
    return data;
  }

  @override
  void initState() {
    var stadtinfoData= Hive.box("stadtinfoBox").get("list");
    var stadtinfoUserData = Hive.box("stadtinfoUserBox").get("list");

    for(var city in stadtinfoData){
      if(city["ort"] == widget.ort["names"].join(" / ")){
        cityInformation = city;
        break;
      }
    }

    for(var city in stadtinfoUserData){
      if(city["ort"] == widget.ort["names"].join(" / ")) usersCityInformation.add(city);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    usersCityInformation = sortThumb(usersCityInformation);

    allgemeineInfoBox() {
      return Container(
            margin: const EdgeInsets.all(10),
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                AppLocalizations.of(context).allgemeineInformation,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.network_check),
                  SizedBox(width: 5),
                  Text("Internet: "),
                  SizedBox(width: 10),
                  Text(cityInformation["internet"].toString() + " Mbps")
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.thermostat),
                  const SizedBox(width: 5),
                  Text(AppLocalizations.of(context).wetter),
                  SizedBox(width: 10),
                  Flexible(child: Container(child: Text(cityInformation["wetter"],overflow: TextOverflow.ellipsis)))
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.family_restroom),
                  const SizedBox(width: 5),
                  Text("Besucht von ${cityInformation["familien"].length} Familien"),
                ],
              ),
            ]),
          );
    }

    insiderInfoBox(information, index) {
      return Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
            border: Border.all(
                width: 2, color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 10),
                Text(information["title"],
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(child: SizedBox()),
                Text((information["thumbUp"].length - information["thumbDown"].length).toString()),
                IconButton(
                    onPressed: () => setThumb("up", index),
                    icon: Icon(
                      Icons.thumb_up,
                      color: information["thumbUp"].contains(userId) ? Colors.green : Colors.grey,
                    )
                ),
                IconButton(
                    onPressed: () => setThumb("down", index),
                    icon: Icon(
                        Icons.thumb_down,
                        color: information["thumbDown"].contains(userId) ? Colors.red : Colors.grey
                    )
                ),
              ],
            ),
            //SizedBox(height: 5),
            Container(
                margin: const EdgeInsets.all(10),
                child: Text(information["information"])
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5, right: 10,left: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  FutureBuilder(
                    future: ProfilDatabase().getData(
                        "name",
                        "WHERE id='${information["erstelltVon"]}'"),
                    builder: (context, snapshot) {
                      var name = snapshot.data;
                      if(!snapshot.hasData) name = "";

                      return Text(
                        name +", 02.05.2022",
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    userInfoBox() {
      return Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).insiderInformation,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (var i = 0; i<usersCityInformation.length; i++) insiderInfoBox(usersCityInformation[i], i),
                    ]
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
        appBar: customAppBar(title: widget.ort["names"].join(" / ")),
        body: Column(
          children: [
            allgemeineInfoBox(),
            const SizedBox(height: 10),
            Expanded(child: userInfoBox())
          ],
        ));
  }
}
