import 'package:familien_suche/global/custom_widgets.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../global/global_functions.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../services/notification.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/search_autocomplete.dart';
import '../../../services/database.dart';
import '../../../widgets/badge_icon.dart';
import '../../show_profil.dart';
import '../../start_page.dart';
import 'meetup_card_details.dart';

var userId = FirebaseAuth.instance.currentUser.uid;

class MeetupDetailsPage extends StatefulWidget {
  Map meetupData;
  bool fromMeetupPage;

  MeetupDetailsPage({
    Key key,
    this.meetupData,
    this.fromMeetupPage = false
  }):super(key: key);

  @override
  _MeetupDetailsPageState createState() => _MeetupDetailsPageState();
}

class _MeetupDetailsPageState extends State<MeetupDetailsPage> {
  bool teilnahme;
  bool absage;
  bool isCreator;
  bool isApproved;
  var searchAutocomplete;
  bool isNotPublic;

  @override
  void initState() {
    teilnahme = widget.meetupData["zusage"] == null
        ? false : widget.meetupData["zusage"].contains(userId);
    absage =widget.meetupData["absage"] == null
        ? false : widget.meetupData["absage"].contains(userId);

    super.initState();
  }

  userFreischalten(user, angenommen, windowState) async {
    String meetupId = widget.meetupData["id"];

    widget.meetupData["freischalten"].remove(user);
    widget.meetupData["freigegeben"].add(user);
    windowState(() {});

    await MeetupDatabase().update(
        "freischalten = JSON_REMOVE(freischalten, JSON_UNQUOTE(JSON_SEARCH(freischalten, 'one', '$user')))",
        "WHERE id = '$meetupId'");

    setState(() {});

    if (!angenommen) return;

    await MeetupDatabase().update(
        "freigegeben = JSON_ARRAY_APPEND(freigegeben, '\$', '$user')",
        "WHERE id = '$meetupId'");

    setState(() {});

    prepareMeetupNotification(
      toId: user,
      meetupId: meetupId,
      meetupName: widget.meetupData["name"],
      typ: "freigegeben"
    );
  }

  removeUser(user, windowState) async {
    String meetupId = widget.meetupData["id"];

    windowState(() {
      widget.meetupData["freigegeben"].remove(user);
    });

    MeetupDatabase().update(
        "freigegeben = JSON_REMOVE(freigegeben, JSON_UNQUOTE(JSON_SEARCH(freigegeben, 'one', '$userId')))",
        "WHERE id = '$meetupId'");
  }

  isOwnerWindow() async {
    bool newOwnerIsInitsiator = false;

    await showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            title: AppLocalizations.of(context).newOwnerIsInitiator,
            children: const [],
            actions: [
              TextButton(
                  onPressed: () {
                    newOwnerIsInitsiator = true;
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).ja)
              ),
              TextButton(
                  onPressed: () {
                    newOwnerIsInitsiator = false;
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).nein)
              ),
            ],
          );
        });

    return newOwnerIsInitsiator;
  }

  changeOrganisatorWindow() {
    TextEditingController inputKontroller = TextEditingController();

    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).benutzerEingeben,
      searchableItems: getAllProfilNames(),
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
                    bool isInitiator = await isOwnerWindow();
                    String selectedUserId = getProfilFromHive(
                        profilName: inputKontroller.text, getIdOnly: true);

                    setState(() {
                      widget.meetupData["erstelltVon"] = selectedUserId;
                      widget.meetupData["isOwner"] = isInitiator;
                    });

                    customSnackbar(
                        context,
                        AppLocalizations.of(context).meetupUebergebenAn1 +
                            inputKontroller.text +
                            AppLocalizations.of(context).meetupUebergebenAn2,
                        color: Colors.green);

                    await MeetupDatabase().update(
                        "erstelltVon = '$selectedUserId', ownEvent = '$isInitiator'",
                        "WHERE id = '${widget.meetupData["id"]}'");
                  },
                )
              ]);
        });
  }

  takePartDecision(bool confirm) async {
    if (confirm) {

      if (!widget.meetupData["interesse"].contains(userId)) {
        widget.meetupData["interesse"].add(userId);
        MeetupDatabase().update(
            "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }

      teilnahme = true;
      absage = false;
      widget.meetupData["zusage"].add(userId);
      widget.meetupData["absage"].remove(userId);

      MeetupDatabase().update(
          "absage = JSON_REMOVE(absage, JSON_UNQUOTE(JSON_SEARCH(absage, 'one', '$userId'))),zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
          "WHERE id = '${widget.meetupData["id"]}'");
    } else {
      teilnahme = false;
      absage = true;
      widget.meetupData["zusage"].remove(userId);
      widget.meetupData["absage"].add(userId);

      MeetupDatabase().update(
          "zusage = JSON_REMOVE(zusage, JSON_UNQUOTE(JSON_SEARCH(zusage, 'one', '$userId'))),absage = JSON_ARRAY_APPEND(absage, '\$', '$userId')",
          "WHERE id = '${widget.meetupData["id"]}'");
    }

    setState(() {});
  }

  changeImmerZusage(bool confirm) {
    if (confirm) {
      widget.meetupData["immerZusagen"].add(userId);
      MeetupDatabase().update(
          "immerZusagen = JSON_ARRAY_APPEND(immerZusagen, '\$', '$userId'), absage = JSON_REMOVE(absage, JSON_UNQUOTE(JSON_SEARCH(absage, 'one', '$userId')))",
          "WHERE id= '${widget.meetupData["id"]}'");

      bool hasZusage = widget.meetupData["zusage"].contains(userId);
      widget.meetupData["absage"].remove(userId);
      teilnahme = true;
      absage = false;

      if (hasZusage) return;

      widget.meetupData["zusage"].add(userId);
      teilnahme = true;
      MeetupDatabase().update(
          "zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
          "WHERE id= '${widget.meetupData["id"]}'");
    } else {
      widget.meetupData["immerZusagen"].remove(userId);
      MeetupDatabase().update(
          "immerZusagen = JSON_REMOVE(immerZusagen, JSON_UNQUOTE(JSON_SEARCH(immerZusagen, 'one', '$userId')))",
          "WHERE id= '${widget.meetupData["id"]}'");
    }
  }

  deleteMeetup(){
    var meetups = Hive.box('secureBox').get("events");
    meetups.removeWhere((meetup) => meetup["id"] == widget.meetupData["id"]);

    MeetupDatabase().delete(widget.meetupData["id"]);

    var chatGroupId = getChatGroupFromHive(
        widget.meetupData["id"])["id"];
    ChatGroupsDatabase().deleteChat(chatGroupId);

    DbDeleteImage(widget.meetupData["bild"]);
  }

  @override
  Widget build(BuildContext context) {
    isCreator = widget.meetupData["erstelltVon"] == userId;
    isApproved = isCreator ? true : widget.meetupData["freigegeben"].contains(userId);
    isNotPublic = widget.meetupData["art"] != "öffentlich" && widget.meetupData["art"] != "public";


    deleteMeetupWindow() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).meetupLoeschen,
              height: 90,
              children: [
                Center(
                    child: Text(
                        AppLocalizations
                            .of(context)
                            .meetupWirklichLoeschen))
              ],
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: (){
                    deleteMeetup();

                    global_func.changePageForever(
                        context,
                        StartPage(selectedIndex: 2, informationPageIndex: 1,));
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

    reportMeetupWindow() {
      TextEditingController reportController = TextEditingController();

      showDialog(
          context: context,
          builder: (BuildContext buildContext) {
            return CustomAlertDialog(
                height: 380,
                title: AppLocalizations.of(context).meetupMelden,
                children: [
                  customTextInput(AppLocalizations.of(context).meetupMeldenFrage,
                      reportController,
                      moreLines: 10),
                  Container(
                    margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                    child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.pop(context);
                          ReportsDatabase().add(userId,
                              "Melde Event id: " + widget.meetupData["id"],
                              reportController.text);
                        },
                        label: Text(AppLocalizations
                            .of(context)
                            .senden)),
                  )
                ]);
          });
    }

    deleteMeetupDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete),
            const SizedBox(width: 10),
            Text(AppLocalizations
                .of(context)
                .meetupLoeschen),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          deleteMeetupWindow();
        },
      );
    }

    reportMeetupDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.report),
            const SizedBox(width: 10),
            Text(AppLocalizations
                .of(context)
                .meetupMelden),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          reportMeetupWindow();
        },
      );
    }

    meetupDetailsDialog() {
      int meetupZusagen = widget.meetupData["zusage"].length;
      int meetupAbsagen = widget.meetupData["absage"].length;
      int meetupInteressierte = widget.meetupData["interesse"].length;
      int meetupFreigegebene = widget.meetupData["freigegeben"].length;
      int meetupUnsure = meetupInteressierte - meetupZusagen - meetupAbsagen;

      return SimpleDialogOption(
          child: Row(
            children: const [
              Icon(Icons.info),
              SizedBox(width: 10),
              Text("Meetup Info"),
            ],
          ),
          onPressed: () =>
              showDialog(
                  context: context,
                  builder: (BuildContext buildContext) {
                    return CustomAlertDialog(
                        title: "Meetup Information", children: [
                      const SizedBox(height: 10),
                      Text(
                          AppLocalizations
                              .of(context)
                              .interessierte +
                              meetupInteressierte.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      Text(
                          AppLocalizations
                              .of(context)
                              .zusagen +
                              meetupZusagen.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      Text(
                          AppLocalizations.of(context).absagen +
                              meetupAbsagen.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      Text(
                          AppLocalizations.of(context).unsicher
                              + meetupUnsure.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      if (isNotPublic)
                        Text(
                            AppLocalizations
                                .of(context)
                                .freigegeben +
                                (meetupFreigegebene + 1).toString(),
                            style: TextStyle(fontSize: fontsize)),
                      if (isNotPublic) const SizedBox(height: 10),
                      const SizedBox(height: 10)
                    ]);
                  }));
    }

    meetupOptinenDialog() {
      return SimpleDialogOption(
          child: Row(
            children: [
              const Icon(Icons.settings),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).meetupOptionen),
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
                            title: AppLocalizations.of(context).meetupOptionen,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          AppLocalizations
                                              .of(context)
                                              .immerDabei)),
                                  Switch(
                                    value: widget.meetupData["immerZusagen"]
                                        .contains(userId),
                                    inactiveThumbColor: Colors.grey[700],
                                    activeColor:
                                    Theme
                                        .of(context)
                                        .colorScheme
                                        .primary,
                                    onChanged: (value) {
                                      changeImmerZusage(value);
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
            Text(AppLocalizations
                .of(context)
                .bestitzerWechseln),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);
          changeOrganisatorWindow();
        },
      );
    }

    moreMenu() {
      bool isRepeating = widget.meetupData["eventInterval"] != global_var.meetupInterval[0] &&
          widget.meetupData["eventInterval"] != global_var.meetupIntervalEnglisch[0];

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
                      if (isApproved || !isNotPublic) meetupDetailsDialog(),
                      if (isApproved || !isNotPublic)
                        if (isRepeating) meetupOptinenDialog(),
                      if (!isCreator) reportMeetupDialog(),
                      if (isCreator) changeOrganisatorDialog(),
                      if (isCreator) const SizedBox(height: 15),
                      if (isCreator) deleteMeetupDialog(),
                    ],
                  ),
                ),
              ],
            );
          });
    }

    teilnahmeButtonBox() {
      bool isRepeating  = global_var.meetupIntervalEnglisch[0] !=
          widget.meetupData["eventInterval"]
          && global_var.meetupInterval[0] != widget.meetupData["eventInterval"];

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if(isRepeating) Column(children: [
            Text(AppLocalizations
                .of(context)
                .immerDabei),
            Switch(
              value: widget.meetupData["immerZusagen"].contains(userId),
              onChanged: (value) {
                changeImmerZusage(value);
                setState(() {});
                print(widget.meetupData);
              },)
          ],),
          if (teilnahme != true)
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              child: FloatingActionButton.extended(
                  heroTag: "teilnehmen",
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  onPressed: () => takePartDecision(true),
                  label: Text(AppLocalizations
                      .of(context)
                      .teilnehmen)),
            ),
          if (absage != true)
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10),
              child: FloatingActionButton.extended(
                heroTag: "Absagen",
                backgroundColor: Theme
                    .of(context)
                    .colorScheme
                    .primary,
                label: Text(AppLocalizations
                    .of(context)
                    .absage),
                onPressed: () => takePartDecision(false),
              ),
            )
        ],
      );
    }

    userFreischaltenList(windowSetState) async {
      List<Widget> freizugebenListe = [];

      for (var user in widget.meetupData["freischalten"]) {
        Map profil = getProfilFromHive(profilId: user);

        freizugebenListe.add(Container(
            margin: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                      onTap: () =>
                          changePage(
                              context,
                              ShowProfilPage(
                                userName: profil["name"],
                                profil: profil,
                              )),
                      child: Text(profil["name"])),
                ),
                IconButton(
                    onPressed: () => userFreischalten(user, true, windowSetState),
                    icon: const Icon(Icons.check_circle, size: 27)),
                IconButton(
                    onPressed: () => userFreischalten(user, false, windowSetState),
                    icon: const Icon(
                      Icons.cancel,
                      size: 27,
                    )),
              ],
            )));
      }

      if (widget.meetupData["freischalten"].length == 0) {
        freizugebenListe.add(Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(
            child: Text(
              AppLocalizations
                  .of(context)
                  .keineFamilienFreigebenVorhanden,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ));
      }

      return ListView(shrinkWrap: true, children: freizugebenListe);
    }

    freigeschalteteUser(windowSetState) async {
      List<Widget> freigeschlatetList = [];

      for (var user in widget.meetupData["freigegeben"]) {
        var profil = getProfilFromHive(profilId: user);

        freigeschlatetList.add(Container(
            margin: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                      onTap: () =>
                          changePage(
                              context,
                              ShowProfilPage(
                                userName: profil["name"],
                                profil: profil,
                              )),
                      child: Text(profil["name"])),
                ),
                const Expanded(child: SizedBox(width: 10)),
                IconButton(
                    onPressed: () => removeUser(user, windowSetState),
                    icon: const Icon(
                      Icons.cancel,
                      size: 27,
                    )),
              ],
            )));
      }

      if (widget.meetupData["freigegeben"].length == 0) {
        freigeschlatetList.add(Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(
            child: Text(
              AppLocalizations
                  .of(context)
                  .keineFamilienFreigebenVorhanden,
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
                            AppLocalizations
                                .of(context)
                                .familienFreigeben,
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
                                return snapshot.data;
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(10),
                          child: Text(
                            AppLocalizations
                                .of(context)
                                .freigegebeneFamilien,
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
                                return snapshot.data;
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

    return SelectionArea(
      child: Scaffold(
        appBar: CustomAppBar(title: "", leading: widget.fromMeetupPage
            ? StartPage(selectedIndex: 2, informationPageIndex: 1)
            : null, buttons: [
          if (isCreator && isNotPublic)
            FutureBuilder(
                future: MeetupDatabase().getData(
                    "freischalten", "WHERE id = '${widget.meetupData["id"]}'"),
                builder: (context, snap) {
                  var data = snap.hasData ? snap.data.length.toString() : "";
                  if (data == "0") data = "";

                  return IconButton(
                      icon: BadgeIcon(
                          icon: Icons.event_available,
                          text: data
                              .toString()),
                      onPressed: () => userfreischalteWindow());
                }),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: "</eventId=" + widget.meetupData["id"]));

              customSnackbar(context, AppLocalizations
                  .of(context)
                  .linkWurdekopiert, color: Colors.green);
            },
          ),
          IconButton(
              icon: const Icon(Icons.message),
              onPressed: () =>
                  global_func.changePage(
                    context,
                    ChatDetailsPage(
                      connectedId: "</event=" + widget.meetupData["id"],
                      isChatgroup: true,
                    ),
                  )),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => moreMenu(),
          ),
        ]),
        body: ListView(
          children: [
            Stack(children: [
              MeetupCardDetails(
                meetupData: widget.meetupData,
                isApproved: isApproved,
              ),
              MeetupArtButton(
                meetupData: widget.meetupData,
                isCreator: isCreator,
                pageState: setState,
              ),
            ]),
            if (isApproved || !isNotPublic) teilnahmeButtonBox(),
          ],
        ),
      ),
    );
  }
}

class MeetupArtButton extends StatefulWidget {
  Map meetupData;
  bool isCreator;
  Function pageState;

  MeetupArtButton({Key key, this.meetupData, this.isCreator, this.pageState})
      : super(key: key);

  @override
  _MeetupArtButtonState createState() => _MeetupArtButtonState();
}

class _MeetupArtButtonState extends State<MeetupArtButton> {
  var meetupTypInput = CustomDropDownButton();
  IconData icon;

  saveMeetupArt() {
    String select = meetupTypInput.getSelected();

    if (select == widget.meetupData["art"]) return;

    widget.meetupData["art"] = select;

    MeetupDatabase()
        .update("art = '$select'", "WHERE id = '${widget.meetupData["id"]}'");
  }

  meetupArtInformation() {
    return SizedBox(
      height: 20,
      child: Align(
          alignment: Alignment.centerRight,
          child: IconButton(
              icon: const Icon(Icons.help, size: 20),
              onPressed: () =>
                  showDialog(
                      context: context,
                      builder: (BuildContext buildContext) {
                        return CustomAlertDialog(
                            height: 500,
                            title: AppLocalizations
                                .of(context)
                                .informationMeetupArt,
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
                                          AppLocalizations
                                              .of(context)
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
                                              AppLocalizations
                                                  .of(context)
                                                  .halbOeffentlich,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold))),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations
                                              .of(context)
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
                                      Text(AppLocalizations
                                          .of(context)
                                          .oeffentlich,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations
                                              .of(context)
                                              .oeffentlichInformationText,
                                          maxLines: 10,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]),
                              )
                            ]);
                      }))),
    );
  }

  @override
  void initState() {
    meetupTypInput = CustomDropDownButton(
      items: isGerman ? global_var.eventArt : global_var.eventArtEnglisch,
      selected: isGerman
          ? global_func.changeEnglishToGerman(widget.meetupData["art"])
          : global_func.changeGermanToEnglish(widget.meetupData["art"]),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    icon = widget.meetupData["art"] == "öffentlich" ||
        widget.meetupData["art"] == "public"
        ? Icons.lock_open
        : widget.meetupData["art"] == "privat" || widget.meetupData["art"] == "private"
        ? Icons.enhanced_encryption
        : Icons.lock;

    return Positioned(
      top: -5,
      left: -10,
      child: IconButton(
          icon: Icon(icon, color: Theme
              .of(context)
              .colorScheme
              .primary),
          onPressed: !widget.isCreator
              ? null
              : () =>
              showDialog(
                  context: context,
                  builder: (BuildContext buildContext) {
                    return CustomAlertDialog(
                        title: AppLocalizations
                            .of(context)
                            .meetupArtAendern,
                        height: 200,
                        children: [
                          meetupArtInformation(),
                          meetupTypInput,
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    child: Text(
                                        AppLocalizations
                                            .of(context)
                                            .abbrechen,
                                        style: TextStyle(fontSize: fontsize)),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                      child: Text(
                                          AppLocalizations
                                              .of(context)
                                              .speichern,
                                          style: TextStyle(fontSize: fontsize)),
                                      onPressed: () {
                                        saveMeetupArt();
                                        setState(() {});
                                        widget.pageState(() {});
                                        Navigator.pop(context);
                                      }),
                                ]),
                          )
                        ]);
                  })),
    );
  }
}
