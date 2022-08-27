import 'dart:convert';

import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/events/event_card_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../global/global_functions.dart';
import '../../global/variablen.dart' as global_var;

import '../../services/notification.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';
import '../../widgets/search_autocomplete.dart';
import '../../services/database.dart';
import '../../widgets/badge_icon.dart';
import '../show_profil.dart';
import '../start_page.dart';

class EventDetailsPage extends StatefulWidget {
  var event;
  var teilnahme;
  var absage;

  EventDetailsPage({
    Key key,
    this.event,
  })  : teilnahme =
            event["zusage"] == null ? [] : event["zusage"].contains(userId),
        absage =
            event["absage"] == null ? [] : event["absage"].contains(userId),
        super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var isCreator;
  var isApproved;
  var searchAutocomplete;
  var allName;
  var userFriendlist;
  var eventDetails = {};
  var isNotPublic;
  var isRepeating;

  @override
  void initState() {
    eventDetails = {
      "zusagen":
          widget.event["zusage"] == null ? [] : widget.event["zusage"].length,
      "absagen":
          widget.event["absage"] == null ? [] : widget.event["absage"].length,
      "interessierte": widget.event["interesse"] == null
          ? []
          : widget.event["interesse"].length,
      "freigegeben": widget.event["freigegeben"] == null
          ? []
          : widget.event["freigegeben"].length
    };
    getDatabaseData();

    super.initState();
  }

  getDatabaseData() async {
    allName = await ProfilDatabase().getData("name", "");

    userFriendlist =
        await ProfilDatabase().getData("friendlist", "WHERE id = '$userId'");
  }

  freischalten(user, angenommen, windowState) async {
    var eventId = widget.event["id"];

    widget.event["freischalten"].remove(user);
    widget.event["freigegeben"].add(user);
    windowState(() {});

    var dbDaten = await EventDatabase()
        .getData("freischalten, freigegeben", "WHERE id = '$eventId'");

    var freischaltenList = dbDaten["freischalten"];
    freischaltenList.remove(user);
    await EventDatabase().update(
        "freischalten = '${json.encode(freischaltenList)}'",
        "WHERE id = '$eventId'");

    if (!angenommen) return;

    var freigegebenListe = dbDaten["freigegeben"];
    freigegebenListe.add(user);
    await EventDatabase().update(
        "freigegeben = '${json.encode(freigegebenListe)}'",
        "WHERE id = '$eventId'");

    setState(() {});

    prepareEventNotification(
      toId: user,
      eventId: eventId,
      eventName: widget.event["name"],
    );
  }

  freigegebenEntfernen(user, windowState) async {
    var eventId = widget.event["id"];

    windowState(() {
      widget.event["freigegeben"].remove(user);
    });

    var freigegebenList =
        await EventDatabase().getData("freigegeben", "WHERE id = '$eventId'");
    freigegebenList.remove(user);
    EventDatabase().update("freigegeben = '${json.encode(freigegebenList)}'",
        "WHERE id = '$eventId'");
  }

  newOrganisatorIsOwnerWindow() async {
    var newOwnerIsInitsiator = false;

    await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).newOwnerIsInitiator,
            children: [],
            actions: [
              TextButton(
                  onPressed: () {
                    newOwnerIsInitsiator = true;
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).ja)),
              TextButton(
                  onPressed: () {
                    newOwnerIsInitsiator = false;
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).nein)),
            ],
          );
        });

    return newOwnerIsInitsiator;
  }

  changeOrganisatorWindow() {
    var inputKontroller = TextEditingController();

    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).benutzerEingeben,
      searchableItems: allName,
      onConfirm: () {
        inputKontroller.text = searchAutocomplete.getSelected()[0];
      },
    );

    showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
              height: 250,
              title: AppLocalizations.of(context).organisatorAbgeben,
              children: [
                searchAutocomplete,
                const SizedBox(height: 40),
                FloatingActionButton.extended(
                  label: Text(AppLocalizations.of(context).uebertragen),
                  onPressed: () async {
                    Navigator.pop(context);
                    var isInitiator = await newOrganisatorIsOwnerWindow();

                    var selectedUserId = await ProfilDatabase().getData(
                        "id", "WHERE name = '${inputKontroller.text}'");

                    setState(() {
                      widget.event["erstelltVon"] = selectedUserId;
                      widget.event["isOwner"] = isInitiator;
                    });

                    customSnackbar(
                        context,
                        AppLocalizations.of(context).eventUebergebenAn1 +
                            inputKontroller.text +
                            AppLocalizations.of(context).eventUebergebenAn2,
                        color: Colors.green);

                    await EventDatabase().update(
                        "erstelltVon = '$selectedUserId', ownEvent = '$isInitiator'",
                        "WHERE id = '${widget.event["id"]}'");
                  },
                )
              ]);
        });
  }

  confirmEvent(bool confirm) async {
    if (confirm) {
      var onInteresseList = widget.event["interesse"].contains(userId);

      if (!onInteresseList) {
        widget.event["interesse"].add(userId);
      }

      setState(() {
        widget.teilnahme = true;
        widget.absage = false;
        widget.event["zusage"].add(userId);
        widget.event["absage"].remove(userId);
      });
    } else {
      setState(() {
        widget.teilnahme = false;
        widget.absage = true;
        widget.event["zusage"].remove(userId);
        widget.event["absage"].add(userId);
      });
    }

    var dbData = await EventDatabase().getData(
        "absage, zusage, interesse", "WHERE id = '${widget.event["id"]}'");

    var zusageList = dbData["zusage"];
    var absageList = dbData["absage"];
    var interessenList = dbData["interesse"];

    if (confirm) {
      if (!interessenList.contains(userId)) interessenList.add(userId);
      zusageList.add(userId);
      absageList.remove(userId);
    } else {
      zusageList.remove(userId);
      absageList.add(userId);
    }

    EventDatabase().update(
        "absage = '${json.encode(absageList)}', "
            "zusage = '${json.encode(zusageList)}', interesse = '${json.encode(interessenList)}'",
        "WHERE id = '${widget.event["id"]}'");
  }

  @override
  Widget build(BuildContext context) {
    isCreator = widget.event["erstelltVon"] == userId;
    isApproved =
        isCreator ? true : widget.event["freigegeben"].contains(userId);
    isNotPublic =
        widget.event["art"] != "öffentlich" && widget.event["art"] != "public";
    eventDetails = {
      "zusagen":
          widget.event["zusage"] == null ? [] : widget.event["zusage"].length,
      "absagen":
          widget.event["absage"] == null ? [] : widget.event["absage"].length,
      "interessierte": widget.event["interesse"] == null
          ? []
          : widget.event["interesse"].length,
      "freigegeben": widget.event["freigegeben"] == null
          ? []
          : widget.event["freigegeben"].length
    };
    isRepeating = widget.event["eventInterval"] !=
            global_var.eventInterval[0] &&
        widget.event["eventInterval"] != global_var.eventIntervalEnglisch[0];

    deleteEventWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).eventLoeschen,
              height: 90,
              children: [
                Center(
                    child: Text(
                        AppLocalizations.of(context).eventWirklichLoeschen))
              ],
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    EventDatabase().delete(widget.event["id"]);
                    dbDeleteImage(widget.event["bild"]);
                    global_func.changePageForever(
                        context, StartPage(selectedIndex: 2));
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context).abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          });
    }

    reportEventWindow() {
      var reportController = TextEditingController();

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                height: 500,
                title: AppLocalizations.of(context).eventMelden,
                children: [
                  customTextInput(AppLocalizations.of(context).eventMeldenFrage,
                      reportController,
                      moreLines: 10),
                  Container(
                    margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                    child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.pop(context);
                          ReportsDatabase().add(
                              userId,
                              "Melde Event id: " + widget.event["id"],
                              reportController.text);
                        },
                        label: Text(AppLocalizations.of(context).senden)),
                  )
                ]);
          });
    }

    deleteEventDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).eventLoeschen),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          deleteEventWindow();
        },
      );
    }

    reportEventDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.report),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).eventMelden),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          reportEventWindow();
        },
      );
    }

    eventDetailsDialog() {
      return SimpleDialogOption(
          child: Row(
            children: const [
              Icon(Icons.info),
              SizedBox(width: 10),
              Text("Event Info"),
            ],
          ),
          onPressed: () => showDialog(
              context: context,
              builder: (BuildContext buildContext) {
                return CustomAlertDialog(title: "Event Information", children: [
                  const SizedBox(height: 10),
                  Text(
                      AppLocalizations.of(context).interessierte +
                          eventDetails["interessierte"].toString(),
                      style: TextStyle(fontSize: fontsize)),
                  const SizedBox(height: 10),
                  Text(
                      AppLocalizations.of(context).zusagen +
                          eventDetails["zusagen"].toString(),
                      style: TextStyle(fontSize: fontsize)),
                  const SizedBox(height: 10),
                  Text(
                      AppLocalizations.of(context).absagen +
                          eventDetails["absagen"].toString(),
                      style: TextStyle(fontSize: fontsize)),
                  const SizedBox(height: 10),
                  Text(
                      AppLocalizations.of(context).unsicher +
                          (eventDetails["interessierte"] -
                                  eventDetails["zusagen"] -
                                  eventDetails["absagen"])
                              .toString(),
                      style: TextStyle(fontSize: fontsize)),
                  const SizedBox(height: 10),
                  if (isNotPublic)
                    Text(
                        AppLocalizations.of(context).freigegeben +
                            (eventDetails["freigegeben"] + 1).toString(),
                        style: TextStyle(fontSize: fontsize)),
                  if (isNotPublic) const SizedBox(height: 10),
                  const SizedBox(height: 10)
                ]);
              }));
    }

    eventOptinenDialog() {
      return SimpleDialogOption(
          child: Row(
            children: [
              const Icon(Icons.settings),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).eventOptionen),
            ],
          ),
          onPressed: () {
            Navigator.pop(context);

            showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return StatefulBuilder(
                      builder: (buildContext, dialogSetState) {
                    return CustomAlertDialog(
                        title: AppLocalizations.of(context).eventOptionen,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      AppLocalizations.of(context).immerDabei)),
                              Switch(
                                value: widget.event["immerZusagen"]
                                    .contains(userId),
                                inactiveThumbColor: Colors.grey[700],
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                                onChanged: (value) {
                                  var zusage =
                                      widget.event["zusage"].contains(userId);
                                  if (value) {
                                    widget.event["immerZusagen"].add(userId);
                                    EventDatabase().update(
                                        "immerZusagen = JSON_ARRAY_APPEND(immerZusagen, '\$', '$userId')",
                                        "WHERE id= '${widget.event["id"]}'");

                                    if (!zusage) {
                                      widget.event["zusage"].add(userId);
                                      widget.teilnahme = true;
                                      EventDatabase().update(
                                          "zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
                                          "WHERE id= '${widget.event["id"]}'");
                                    }
                                  } else {
                                    widget.event["immerZusagen"].remove(userId);
                                    EventDatabase().update(
                                        "immerZusagen = JSON_REMOVE(immerZusagen, JSON_UNQUOTE(JSON_SEARCH(immerZusagen, 'one', '$userId')))",
                                        "WHERE id= '${widget.event["id"]}'");
                                  }

                                  dialogSetState(() {});

                                  setState(() {});
                                },
                              )
                            ],
                          )
                        ]);
                  });
                });
          });
    }

    changeOrganisatorDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.change_circle),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).bestitzerWechseln),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          changeOrganisatorWindow();
        },
      );
    }

    moreMenu() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 250,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding:
                        const EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [
                      if (isApproved || !isNotPublic) eventDetailsDialog(),
                      if (isApproved || !isNotPublic)
                        if (isRepeating) eventOptinenDialog(),
                      if (!isCreator) reportEventDialog(),
                      if (isCreator) changeOrganisatorDialog(),
                      if (isCreator) const SizedBox(height: 15),
                      if (isCreator) deleteEventDialog(),
                    ],
                  ),
                ),
              ],
            );
          });
    }

    teilnahmeButtonBox() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.teilnahme != true)
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              child: FloatingActionButton.extended(
                  heroTag: "teilnehmen",
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () => confirmEvent(true),
                  label: Text(AppLocalizations.of(context).teilnehmen)),
            ),
          if (widget.absage != true)
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              child: FloatingActionButton.extended(
                heroTag: "Absagen",
                backgroundColor: Theme.of(context).colorScheme.primary,
                label: Text(AppLocalizations.of(context).absage),
                onPressed: () => confirmEvent(false),
              ),
            )
        ],
      );
    }

    userFreischaltenList(windowSetState) async {
      List<Widget> freizugebenListe = [];

      for (var user in widget.event["freischalten"]) {
        var profil = await ProfilDatabase().getData("*", "WHERE id = '$user'");

        freizugebenListe.add(Container(
            margin: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                      onTap: () => changePage(
                          context,
                          ShowProfilPage(
                            userName: profil["name"],
                            profil: profil,
                          )),
                      child: Text(profil["name"])),
                ),
                IconButton(
                    onPressed: () => freischalten(user, true, windowSetState),
                    icon: const Icon(Icons.check_circle, size: 27)),
                IconButton(
                    onPressed: () => freischalten(user, false, windowSetState),
                    icon: const Icon(
                      Icons.cancel,
                      size: 27,
                    )),
              ],
            )));
      }

      if (widget.event["freischalten"].length == 0) {
        freizugebenListe.add(Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(
            child: Text(
              AppLocalizations.of(context).keineFamilienFreigebenVorhanden,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ));
      }

      return ListView(shrinkWrap: true, children: freizugebenListe);
    }

    freigeschalteteUser(windowSetState) async {
      List<Widget> freigeschlatetList = [];

      for (var user in widget.event["freigegeben"]) {
        var profil = await ProfilDatabase().getData("*", "WHERE id = '$user'");

        freigeschlatetList.add(Container(
            margin: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                      onTap: () => changePage(
                          context,
                          ShowProfilPage(
                            userName: profil["name"],
                            profil: profil,
                          )),
                      child: Text(profil["name"])),
                ),
                const Expanded(child: SizedBox(width: 10)),
                IconButton(
                    onPressed: () => freigegebenEntfernen(user, windowSetState),
                    icon: const Icon(
                      Icons.cancel,
                      size: 27,
                    )),
              ],
            )));
      }

      if (widget.event["freigegeben"].length == 0) {
        freigeschlatetList.add(Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(
            child: Text(
              AppLocalizations.of(context).keineFamilienFreigebenVorhanden,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ));
      }

      return ListView(shrinkWrap: true, children: freigeschlatetList);
    }

    userfreischalteWindow() async {
      StateSetter windowSetState;

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(builder: (context, setState) {
              windowSetState = setState;
              return AlertDialog(
                contentPadding: EdgeInsets.zero,
                content: Stack(clipBehavior: Clip.none, children: [
                  SizedBox(
                      height: 600,
                      width: 600,
                      child: Column(children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          child: Text(
                            AppLocalizations.of(context).familienFreigeben,
                            style: TextStyle(
                                fontSize: fontsize,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder(
                            future: userFreischaltenList(windowSetState),
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              if (snapshot.hasData) {
                                return Column(
                                  children: [
                                    snapshot.data,
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(10),
                          child: Text(
                            AppLocalizations.of(context).freigegebeneFamilien,
                            style: TextStyle(
                                fontSize: fontsize,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder(
                            future: freigeschalteteUser(windowSetState),
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              if (snapshot.hasData) {
                                return Column(
                                  children: [
                                    snapshot.data,
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        )
                      ])),
                  Positioned(
                    height: 30,
                    right: -13,
                    top: -7,
                    child: InkResponse(
                        onTap: () => Navigator.pop(context),
                        child: const CircleAvatar(
                          child: Icon(
                            Icons.close,
                            size: 16,
                          ),
                          backgroundColor: Colors.red,
                        )),
                  ),
                ]),
              );
            });
          });
    }

    linkTeilenWindow() async {
      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(title: "Event link", children: [
              Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all()),
                  child: Text("</eventId=" + widget.event["id"])),
              Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    Clipboard.setData(
                        ClipboardData(text: "</eventId=" + widget.event["id"]));

                    await showDialog(
                        context: context,
                        builder: (context) {
                          Future.delayed(const Duration(seconds: 1), () {
                            Navigator.of(context).pop(true);
                          });
                          return AlertDialog(
                            content: Text(
                                AppLocalizations.of(context).linkWurdekopiert),
                          );
                        });
                    Navigator.pop(context);
                  },
                  label: Text(AppLocalizations.of(context).linkKopieren),
                  icon: const Icon(Icons.copy),
                ),
              ),
              const SizedBox(height: 10)
            ]);
          });
    }

    return Scaffold(
      appBar: CustomAppBar(title: "", buttons: [
        if (isCreator && isNotPublic)
          FutureBuilder(
              future: EventDatabase().getData(
                  "freischalten", "WHERE id = '${widget.event["id"]}'"),
              builder: (context, snap) {
                var data = snap.hasData ? snap.data.length.toString() : "";
                if (data == "0") data = "";

                return IconButton(
                    icon: BadgeIcon(
                        icon: Icons.event_available,
                        text: data
                            .toString()), //const Icon(Icons.event_available),
                    onPressed: () => userfreischalteWindow());
              }),
        IconButton(
          icon: const Icon(Icons.link),
          onPressed: () => linkTeilenWindow(),
        ),
        if (!isCreator)
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => global_func.changePage(context,
                ChatDetailsPage(chatPartnerId: widget.event["erstelltVon"])),
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => moreMenu(),
        ),
      ]),
      body: ListView(
        children: [
          Stack(children: [
            EventCardDetails(
              event: widget.event,
              isApproved: isApproved,
            ),
            EventArtButton(
              event: widget.event,
              isCreator: isCreator,
              pageState: setState,
            ),
          ]),
          if (isApproved || !isNotPublic) teilnahmeButtonBox(),
        ],
      ),
    );
  }
}

class EventArtButton extends StatefulWidget {
  var event;
  var isCreator;
  var pageState;

  EventArtButton({Key key, this.event, this.isCreator, this.pageState})
      : super(key: key);

  @override
  _EventArtButtonState createState() => _EventArtButtonState();
}

class _EventArtButtonState extends State<EventArtButton> {
  var eventTypInput = CustomDropDownButton();
  var icon;

  eventArtSave() {
    var auswahl = eventTypInput.getSelected();
    if (auswahl == widget.event["art"]) return;

    widget.event["art"] = auswahl;
    setState(() {});
    widget.pageState(() {});

    EventDatabase()
        .update("art = '$auswahl'", "WHERE id = '${widget.event["id"]}'");

    Navigator.pop(context);
  }

  eventArtInformation() {
    return Positioned(
        top: -15,
        left: 10,
        child: IconButton(
            icon: const Icon(Icons.help, size: 15),
            onPressed: () => showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CustomAlertDialog(
                      height: 500,
                      title: AppLocalizations.of(context).informationEventArt,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.only(left: 5, right: 5),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("privat       ",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .privatInformationText,
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ]),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.only(left: 5, right: 5),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 70,
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .halbOeffentlich,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold))),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .halbOeffentlichInformationText,
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ]),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.only(left: 5, right: 5),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context).oeffentlich,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .oeffentlichInformationText,
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                        )
                      ]);
                })));
  }

  @override
  void initState() {
    eventTypInput = CustomDropDownButton(
      items: isGerman ? global_var.eventArt : global_var.eventArtEnglisch,
      selected: isGerman
          ? global_func.changeEnglishToGerman(widget.event["art"])
          : global_func.changeGermanToEnglish(widget.event["art"]),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    icon = widget.event["art"] == "öffentlich" ||
            widget.event["art"] == "public"
        ? Icons.lock_open
        : widget.event["art"] == "privat" || widget.event["art"] == "private"
            ? Icons.enhanced_encryption
            : Icons.lock;

    return Positioned(
      top: -5,
      left: -10,
      child: IconButton(
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          onPressed: !widget.isCreator
              ? null
              : () => showDialog(
                  context: context,
                  builder: (BuildContext buildContext) {
                    return CustomAlertDialog(
                        title: AppLocalizations.of(context).eventArtAendern,
                        height: 180,
                        children: [
                          eventTypInput,
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    child: Text(
                                        AppLocalizations.of(context).abbrechen,
                                        style: TextStyle(fontSize: fontsize)),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                      child: Text(
                                          AppLocalizations.of(context)
                                              .speichern,
                                          style: TextStyle(fontSize: fontsize)),
                                      onPressed: () => eventArtSave()),
                                ]),
                          )
                        ]);
                  })),
    );
  }
}
