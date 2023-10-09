import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

import '../../../functions/user_speaks_german.dart';
import '../../../global/global_functions.dart';
import '../../../global/variablen.dart' as global_var;
import '../../../global/global_functions.dart' as global_func;
import '../../../services/notification.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/layout/ownIconButton.dart';
import '../../../widgets/windowConfirmCancelBar.dart';
import '../../../windows/custom_popup_menu.dart';
import '../../../windows/dialog_window.dart';
import '../../../widgets/layout/custom_dropdown_button.dart';
import '../../../widgets/layout/custom_snackbar.dart';
import '../../../widgets/layout/custom_text_input.dart';
import '../../../services/database.dart';
import '../../../windows/all_user_select.dart';
import '../../chat/chat_details.dart';
import '../../show_profil.dart';
import '../../start_page.dart';
import 'meetup_card_details.dart';
import 'meetup_page.dart';

var userId = Hive.box("secureBox").get("ownProfil")["id"];

class MeetupDetailsPage extends StatefulWidget {
  final Map meetupData;
  final bool fromMeetupPage;
  final bool toMainPage;

  const MeetupDetailsPage({
    Key? key,
    required this.meetupData,
    this.fromMeetupPage = false,
    this.toMainPage = false
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
      customSnackBar(context, AppLocalizations.of(context)!.geheimerChatMeldung);
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
              children: [
                Center(
                    child: Text(
                        AppLocalizations
                            .of(context)!
                            .meetupWirklichLoeschen)),
                WindowConfirmCancelBar(
                  confirmTitle: AppLocalizations.of(context)!.loeschen,
                  onConfirm: (){
                    deleteMeetup();
                  },
                ),
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
      List interestedCleaned = widget.meetupData["interesse"];

      for(var user in widget.meetupData["zusage"] + widget.meetupData["absage"]){
        interestedCleaned.remove(user);
      }

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
                              + interestedCleaned.length.toString(),
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
        customSnackBar(
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
        appBar: CustomAppBar(title: "",
            leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if(widget.toMainPage){
                global_func.changePage(context, const MeetupPage());
              } else{
                Navigator.of(context).pop();
              }
            }
        ),buttons: [
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
            icon: Icons.message,
            tooltipText: AppLocalizations.of(context)!.tooltipChatErsteller,
            onPressed: () => openChat(),
          ),
          OwnIconButton(
            icon: Icons.link,
            tooltipText: AppLocalizations.of(context)!.tooltipLinkKopieren,
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: "</eventId=${widget.meetupData["id"]}"));

              customSnackBar(context, AppLocalizations
                  .of(context)!
                  .linkWurdekopiert, color: Colors.green);
            },
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
            ]),
            if (isApproved || !isNotPublic) teilnahmeButtonBox(),
          ],
        ),
      ),
    );
  }
}


