import 'dart:convert';

import 'package:familien_suche/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../global/custom_widgets.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';

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

  setThumb(thumb, index) async {
    var infoId = usersCityInformation[index]["id"];

    if (thumb == "up") {
      if (usersCityInformation[index]["thumbUp"].contains(userId)) return;

      setState(() {
        usersCityInformation[index]["thumbUp"].add(userId);
        usersCityInformation[index]["thumbDown"].remove(userId);
      });

      var dbData = await StadtinfoUserDatabase()
          .getData("thumbUp, thumbDown", "WHERE id ='$infoId'");
      var dbThumbUpList = dbData["thumbUp"];
      var dbThumbDownList = dbData["thumbDown"];

      dbThumbUpList.add(userId);
      dbThumbDownList.remove(userId);

      await StadtinfoUserDatabase().update(
          "thumbUp = '${jsonEncode(dbThumbUpList)}', thumbDown = '${jsonEncode(dbThumbDownList)}'",
          "WHERE id ='$infoId'");
    } else if (thumb == "down") {
      if (usersCityInformation[index]["thumbDown"].contains(userId)) return;

      setState(() {
        usersCityInformation[index]["thumbDown"].add(userId);
        usersCityInformation[index]["thumbUp"].remove(userId);
      });

      var dbData = await StadtinfoUserDatabase()
          .getData("thumbUp, thumbDown", "WHERE id ='$infoId'");
      var dbThumbUpList = dbData["thumbUp"];
      var dbThumbDownList = dbData["thumbDown"];

      dbThumbDownList.add(userId);
      dbThumbUpList.remove(userId);

      await StadtinfoUserDatabase().update(
          "thumbUp = '${jsonEncode(dbThumbUpList)}', thumbDown = '${jsonEncode(dbThumbDownList)}'",
          "WHERE id ='$infoId'");
    }
  }

  sortThumb(data) {
    data.sort((a, b) => (b["thumbUp"].length - b["thumbDown"].length)
        .compareTo(a["thumbUp"].length - a["thumbDown"].length) as int);
    return data;
  }

  @override
  void initState() {
    var stadtinfoData = Hive.box("stadtinfoBox").get("list");
    var stadtinfoUserData = Hive.box("stadtinfoUserBox").get("list");

    for (var city in stadtinfoData) {
      if (city["ort"] == widget.ort["names"].join(" / ")) {
        cityInformation = city;
        break;
      }
    }

    for (var city in stadtinfoUserData) {
      if (city["ort"] == widget.ort["names"].join(" / "))
        usersCityInformation.add(city);
    }

    super.initState();
  }

  changeInformation(information){
    var titleTextKontroller = TextEditingController(text: information["title"]);
    var informationTextKontroller = TextEditingController(text: information["information"]);

    Future<void>.delayed(
        const Duration(),
            () => showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return CustomAlertDialog(
                  height: 500,
                  title: AppLocalizations.of(context).informationAendern,
                  children: [
                    customTextInput(AppLocalizations.of(context).titel, titleTextKontroller),
                    const SizedBox(height: 10),
                    customTextInput(
                        AppLocalizations.of(context).beschreibung,
                        informationTextKontroller, moreLines: 10,
                        textInputAction: TextInputAction.newline
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                        child: const Text("speichern"),
                        onPressed: () {
                          if(titleTextKontroller.text.isEmpty){
                            customSnackbar(context, AppLocalizations.of(context).titelStadtinformationEingeben);
                            return;
                          } else if (informationTextKontroller.text.isEmpty){
                            customSnackbar(context, AppLocalizations.of(context).beschreibungStadtinformationEingeben);
                            return;
                          }

                          Navigator.pop(context);

                          setState(() {
                            usersCityInformation[information["index"]]["title"] = titleTextKontroller.text;
                          });

                          StadtinfoUserDatabase().update(
                              "title = '${titleTextKontroller.text}', information = '${informationTextKontroller.text}'",
                              "WHERE id ='${information["id"]}'");

                        },
                      ),
                      TextButton(
                        child: const Text("abbrechen"),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],)
                  ]
              );
            })
    );
  }

  deleteInformation(information) async {
    Future<void>.delayed(
        const Duration(),
        () => showDialog(
            context: context,
            builder: (BuildContext context){
              return CustomAlertDialog(
                title: AppLocalizations.of(context).informationLoeschen,
                height: 90,
                children: [
                  const SizedBox(height: 10),
                  Center(child: Text(AppLocalizations.of(context).informationWirklichLoeschen))
                ],
                actions: [
                  TextButton(
                    child: const Text("Ok"),
                    onPressed: (){
                      StadtinfoUserDatabase().delete(information["id"]);

                      setState(() {
                        usersCityInformation.remove(information);
                      });

                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context).abbrechen),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              );
            }
        )
    );


  }

  reportInformation(information){
    var reportTextKontroller = TextEditingController();

    Future<void>.delayed(
        const Duration(),
            () => showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CustomAlertDialog(
                      height: 500,
                      title: AppLocalizations.of(context).informationMelden,
                      children: [
                        customTextInput("", reportTextKontroller, moreLines: 10, hintText: AppLocalizations.of(context).informationMeldenFrage),
                        Container(
                          margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                          child: FloatingActionButton.extended(
                              onPressed: () {
                                Navigator.pop(context);
                                ReportsDatabase().add(
                                    userId,
                                    "Melde Information id: " + information["id"].toString(),
                                    reportTextKontroller.text
                                );
                              },
                              label: Text(AppLocalizations.of(context).senden)
                          ),
                        )
                      ]
                  );
                })
    );
  }

  @override
  Widget build(BuildContext context) {
    usersCityInformation = sortThumb(usersCityInformation);


    allgemeineInfoBox() {
      String internetSpeedText = cityInformation["internet"] == null ?
      "?" : cityInformation["internet"].toString();

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
              const Icon(Icons.network_check),
              const SizedBox(width: 5),
              const Text("Internet: "),
              const SizedBox(width: 5),
              Text("Ø $internetSpeedText Mbps")
            ],
          ),
          if(cityInformation["wetter"] != null) const SizedBox(height: 10),
          if(cityInformation["wetter"] != null) Row(
            children: [
              const Icon(Icons.thermostat),
              const SizedBox(width: 5),
              Text(AppLocalizations.of(context).wetter),
              const SizedBox(width: 10),
               Flexible(
                  child: InkWell(
                      onTap: () =>  launch(cityInformation["wetter"]),
                      child: Text(cityInformation["wetter"],
                          style: const TextStyle(color: Colors.blue),
                          overflow: TextOverflow.ellipsis)
                  )
               )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.family_restroom),
              const SizedBox(width: 5),
              Text(AppLocalizations.of(context).besuchtVon +
                  cityInformation["familien"].length.toString() +
                  AppLocalizations.of(context).familien),
            ],
          ),
        ]),
      );
    }

    openInformationMenu(positionDetails, information) async {
      double left = positionDetails.globalPosition.dx;
      double top = positionDetails.globalPosition.dy;
      bool canChange = information["erstelltVon"] == userId &&
          DateTime.now().difference(DateTime.parse(information["erstelltAm"])).inDays <= 1 ;

      await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(left, top, 0, 0),
          items: [
            if(canChange) PopupMenuItem(
                child: Text(AppLocalizations.of(context).bearbeiten),
              onTap: () => changeInformation(information),
            ),
            PopupMenuItem(
                child: Text(AppLocalizations.of(context).melden),
              onTap: ()=> reportInformation(information),
            ),
            if(canChange) PopupMenuItem(
              child: Text(AppLocalizations.of(context).loeschen),
              onTap: () {
                deleteInformation(information);
      }
            ),
          ]
      );


    }

    insiderInfoBox(information, index) {
      information["index"] = index;

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
            Container(
              margin: const EdgeInsets.only(top:5, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        information["title"],
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      )),
                  const Expanded(child: const SizedBox()),
                  GestureDetector(
                    onTapDown: (positionDetails) => openInformationMenu(positionDetails, information),
                    child: const Icon(Icons.more_horiz),
                  ),
                  const SizedBox(width:5)
                ],
              ),
            ),
            Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                child: Text(information["information"])),
            Padding(
              padding: const EdgeInsets.all(0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                      onPressed: () => setThumb("up", index),
                      icon: Icon(
                        Icons.thumb_up,
                        color: information["thumbUp"].contains(userId)
                            ? Colors.green
                            : Colors.grey,
                      )),
                  Text((information["thumbUp"].length -
                          information["thumbDown"].length)
                      .toString()),
                  IconButton(
                      //padding: EdgeInsets.all(5),
                      onPressed: () => setThumb("down", index),
                      icon: Icon(Icons.thumb_down,
                          color: information["thumbDown"].contains(userId)
                              ? Colors.red
                              : Colors.grey)),
                  const Expanded(child: SizedBox()),
                  FutureBuilder(
                      future: ProfilDatabase().getData(
                          "name", "WHERE id='${information["erstelltVon"]}'"),
                      builder: (context, snapshot) {
                        var name = snapshot.data;
                        if (!snapshot.hasData || snapshot.data == false) name = "";

                        return Text(
                          name + " 02.05.2022",
                          style: const TextStyle(color: Colors.grey),
                        );
                      }),
                  const SizedBox(width: 5)
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
            const SizedBox(height: 10),
            Expanded(
              child: ListView(shrinkWrap: true, children: [
                for (var i = 0; i < usersCityInformation.length; i++)
                  insiderInfoBox(usersCityInformation[i], i),
              ]),
            )
          ],
        ),
      );
    }

    return Scaffold(
        appBar: CustomAppBar(title: widget.ort["names"].join(" / ")),
        body: Column(
          children: [
            allgemeineInfoBox(),
            const SizedBox(height: 10),
            Expanded(child: userInfoBox())
          ],
        ));
  }
}
