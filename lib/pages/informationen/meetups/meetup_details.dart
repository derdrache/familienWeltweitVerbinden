import 'package:familien_suche/functions/user_speaks_german.dart';
import 'package:familien_suche/global/global_functions.dart' as global_func;
import 'package:familien_suche/pages/chat/chat_details.dart';
import 'package:familien_suche/pages/informationen/meetups/meetup_page.dart';
import 'package:familien_suche/widgets/layout/ownIconButton.dart';
import 'package:familien_suche/windows/custom_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../global/global_functions.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../services/notification.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/dialogWindow.dart';
import '../../../widgets/layout/custom_dropdownButton.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../../services/database.dart';
import '../../../windows/all_user_select.dart';
import '../../show_profil.dart';
import '../../start_page.dart';
import 'meetup_card_details.dart';

var userId = Hive.box("secureBox").get("ownProfil")["id"];

class MeetupDetailsPage extends StatefulWidget {
  Map meetupData;
  bool fromMeetupPage;

  MeetupDetailsPage({
    Key? key,
    required this.meetupData,
    this.fromMeetupPage = false
  }):super(key: key);

  @override
  State<MeetupDetailsPage> createState() => _MeetupDetailsPageState();
}

class _MeetupDetailsPageState extends State<MeetupDetailsPage> {
  late bool teilnahme;
  late bool absage;
  late bool isCreator;
  late bool isApproved;
  late bool isNotPublic;


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
            title: AppLocalizations.of(context)!.newOwnerIsInitiator,
            actions: [
              TextButton(
                  onPressed: () {
                    newOwnerIsInitsiator = true;
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.ja)
              ),
              TextButton(
                  onPressed: () {
                    newOwnerIsInitsiator = false;
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.nein)
              ),
            ],
            children: const [],
          );
        });

    return newOwnerIsInitsiator;
  }

  takePartDecision(bool confirm) async {
    if (confirm) {

      if (!widget.meetupData["interesse"].contains(userId)) {
        widget.meetupData["interesse"].add(userId);
        MeetupDatabase().update(
            "interesse = JSON_ARRAY_APPEND(interesse, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }

      if(widget.meetupData["absage"].contains(userId)){
        MeetupDatabase().update(
            "absage = JSON_REMOVE(absage, JSON_UNQUOTE(JSON_SEARCH(absage, 'one', '$userId'))),zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }else{
        MeetupDatabase().update(
            "zusage = JSON_ARRAY_APPEND(zusage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }

      teilnahme = true;
      absage = false;
      widget.meetupData["zusage"].add(userId);
      widget.meetupData["absage"].remove(userId);
    } else {
      if(widget.meetupData["zusage"].contains(userId)){
        MeetupDatabase().update(
            "zusage = JSON_REMOVE(zusage, JSON_UNQUOTE(JSON_SEARCH(zusage, 'one', '$userId'))),absage = JSON_ARRAY_APPEND(absage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }else{
        MeetupDatabase().update(
            "absage = JSON_ARRAY_APPEND(absage, '\$', '$userId')",
            "WHERE id = '${widget.meetupData["id"]}'");
      }
      teilnahme = false;
      absage = true;
      widget.meetupData["zusage"].remove(userId);
      widget.meetupData["absage"].add(userId);

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
    MeetupDatabase().delete(widget.meetupData["id"]);

    dbDeleteImage(widget.meetupData["bild"]);

    global_func.changePage(context, StartPage(selectedIndex: 2,));
    global_func.changePage(context, const MeetupPage());
  }

  sendTakePartNotification(meetupData){
    prepareMeetupNotification(
      meetupId: meetupData["id"],
      toId: meetupData["erstelltVon"],
      meetupName: meetupData["name"],
      typ: "takePart"
    );
  }

  openChat(){
    bool isPrivat = widget.meetupData["art"] == "private" || widget.meetupData["art"] == "privat";
    bool hasAccsess = widget.meetupData["erstelltAm"] == userId || widget.meetupData["freigegeben"].contains(userId);

    if(isPrivat && !hasAccsess){
      customSnackbar(context, AppLocalizations.of(context)!.geheimerChatMeldung);
      return;
    }

    global_func.changePage(
      context,
      ChatDetailsPage(
        connectedWith: "</event=${widget.meetupData["id"]}",
        isChatgroup: true,
      ),
    );
  }

  removeUnknownUser(userId){
    //Remove user
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
              title: AppLocalizations.of(context)!.meetupLoeschen,
              height: 90,
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: (){
                    deleteMeetup();

                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
              children: [
                Center(
                    child: Text(
                        AppLocalizations
                            .of(context)!
                            .meetupWirklichLoeschen))
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
                title: AppLocalizations.of(context)!.meetupMelden,
                children: [
                  CustomTextInput(AppLocalizations.of(context)!.meetupMeldenFrage,
                      reportController,
                      moreLines: 10),
                  Container(
                    margin: const EdgeInsets.only(left: 30, top: 10, right: 30),
                    child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.pop(context);
                          ReportsDatabase().add(userId,
                              "Melde Event id: ${widget.meetupData["id"]}",
                              reportController.text);
                        },
                        label: Text(AppLocalizations
                            .of(context)!
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
                .of(context)!
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
                .of(context)!
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
          child: const Row(
            children: [
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
                              .of(context)!
                              .interessierte +
                              meetupInteressierte.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      Text(
                          AppLocalizations
                              .of(context)!
                              .zusagen +
                              meetupZusagen.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      Text(
                          AppLocalizations.of(context)!.absagen +
                              meetupAbsagen.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      Text(
                          AppLocalizations.of(context)!.unsicher
                              + meetupUnsure.toString(),
                          style: TextStyle(fontSize: fontsize)),
                      const SizedBox(height: 10),
                      if (isNotPublic)
                        Text(
                            AppLocalizations
                                .of(context)!
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
              Text(AppLocalizations.of(context)!.meetupOptionen),
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
                            title: AppLocalizations.of(context)!.meetupOptionen,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          AppLocalizations
                                              .of(context)!
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

    changeOrganisatorWindow() async{
      String selectedUserId = await AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context)!.personSuchen,
      ).openWindow();
      bool isInitiator = await isOwnerWindow();
      String selectedUserName = getProfilFromHive(profilId: selectedUserId, getNameOnly: true);

      setState(() {
        widget.meetupData["erstelltVon"] = selectedUserId;
        widget.meetupData["isOwner"] = isInitiator;
      });

      var myOwnMeetups = Hive.box('secureBox').get("myEvents") ?? [];
      myOwnMeetups.remove(widget.meetupData);

      if (context.mounted){
        customSnackbar(
            context,
            AppLocalizations.of(context)!.meetupUebergebenAn1 +
                selectedUserName +
                AppLocalizations.of(context)!.meetupUebergebenAn2,
            color: Colors.green);
      }

      await MeetupDatabase().update(
          "erstelltVon = '$selectedUserId', ownEvent = '$isInitiator'",
          "WHERE id = '${widget.meetupData["id"]}'");
    }

    changeOrganisatorDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.change_circle),
            const SizedBox(width: 10),
            Text(AppLocalizations
                .of(context)!
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

      CustomPopupMenu(context, children: [
        if (isApproved || !isNotPublic) meetupDetailsDialog(),
        if ((isApproved || !isNotPublic) && isRepeating) meetupOptinenDialog(),
        if (!isCreator) reportMeetupDialog(),
        if (isCreator) changeOrganisatorDialog(),
        if (isCreator) const SizedBox(height: 15),
        if (isCreator) deleteMeetupDialog(),
      ]);
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
                .of(context)!
                .immerDabei),
            Switch(
              value: widget.meetupData["immerZusagen"].contains(userId),
              onChanged: (value) {
                changeImmerZusage(value);
                setState(() {});
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
                  onPressed: () {
                    takePartDecision(true);
                    sendTakePartNotification(widget.meetupData);
                  },
                  label: Text(AppLocalizations
                      .of(context)!
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
                    .of(context)!
                    .absage),
                onPressed: () => takePartDecision(false),
              ),
            )
        ],
      );
    }

    userFreischaltenList(windowSetState) async {
      List<Widget> freizugebenListe = [];

      for (var userId in widget.meetupData["freischalten"]) {
        Map? profil = getProfilFromHive(profilId: userId);

        if(profil == null){
          userFreischalten(userId, false, windowSetState);
          continue;
        }

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
                                profil: profil,
                              )),
                      child: Text(profil["name"])),
                ),
                IconButton(
                    onPressed: () => userFreischalten(userId, true, windowSetState),
                    icon: const Icon(Icons.check_circle, size: 27)),
                IconButton(
                    onPressed: () => userFreischalten(userId, false, windowSetState),
                    icon: const Icon(
                      Icons.cancel,
                      size: 27,
                    )),
              ],
            )));
      }

      if (freizugebenListe.isEmpty) {
        freizugebenListe.add(Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(
            child: Text(
              AppLocalizations
                  .of(context)!
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
        Map? profil = getProfilFromHive(profilId: user);

        if(profil == null) continue;

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

      if (freigeschlatetList.isEmpty) {
        freigeschlatetList.add(Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Center(
            child: Text(
              AppLocalizations
                  .of(context)!
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
                                .of(context)!
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
                                .of(context)!
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
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.close,
                            size: 16,
                          ),
                        )),
                  ),
                ]),
              );
            });
          });
    }

    return SelectionArea(
      child: Scaffold(
        appBar: CustomAppBar(title: "", buttons: [
          if (isCreator && isNotPublic)
            FutureBuilder(
                future: MeetupDatabase().getData(
                    "freischalten", "WHERE id = '${widget.meetupData["id"]}'"),
                builder: (context, snap) {
                  String data = "";
                  if(snap.data == null || snap.data == false) {
                    data = "0";
                  } else {
                    List snapData = snap.data as List;
                    data = snapData.length.toString();
                  }

                  if (data == "0") data = "";

                  return OwnIconButton(
                    icon: Icons.event_available,
                    tooltipText: AppLocalizations.of(context)!.tooltipMeetupDetailsVerwaltung,
                    badgeText: data.toString(),
                    onPressed: () => userfreischalteWindow(),
                  );
                }),
          OwnIconButton(
            icon: Icons.link,
            tooltipText: AppLocalizations.of(context)!.tooltipLinkKopieren,
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: "</eventId=${widget.meetupData["id"]}"));

              customSnackbar(context, AppLocalizations
                  .of(context)!
                  .linkWurdekopiert, color: Colors.green);
            },
          ),
          OwnIconButton(
            icon: Icons.message,
            tooltipText: AppLocalizations.of(context)!.tooltipChatErsteller,
            onPressed: () => openChat(),
          ),
          OwnIconButton(
            icon:Icons.more_vert,
            tooltipText: AppLocalizations.of(context)!.tooltipMehrOptionen,
            onPressed: () => moreMenu(),
          )
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

  MeetupArtButton({Key? key, required this.meetupData, required this.isCreator, required this.pageState})
      : super(key: key);

  @override
  State<MeetupArtButton> createState() => _MeetupArtButtonState();
}

class _MeetupArtButtonState extends State<MeetupArtButton> {
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  late bool userSpeakGerman;
  late CustomDropdownButton meetupTypInput;
  late IconData icon;

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
              tooltip: AppLocalizations.of(context)!.tooltipMehrInformationen,
              onPressed: () =>
                  showDialog(
                      context: context,
                      builder: (BuildContext buildContext) {
                        return CustomAlertDialog(
                            height: 500,
                            title: AppLocalizations
                                .of(context)!
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
                                              .of(context)!
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
                                                  .of(context)!
                                                  .halbOeffentlich,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold))),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations
                                              .of(context)!
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
                                          .of(context)!
                                          .oeffentlich,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations
                                              .of(context)!
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
    userSpeakGerman = getUserSpeaksGerman();
    meetupTypInput = CustomDropdownButton(
      items: userSpeakGerman ? global_var.eventArt : global_var.eventArtEnglisch,
      selected: userSpeakGerman
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
      left: -5,
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
                            .of(context)!
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
                                            .of(context)!
                                            .abbrechen,
                                        style: TextStyle(fontSize: fontsize)),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                      child: Text(
                                          AppLocalizations
                                              .of(context)!
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
