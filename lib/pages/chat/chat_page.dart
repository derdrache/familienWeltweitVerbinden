import 'dart:ui';

import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../services/database.dart';
import '../../widgets/profil_image.dart';
import '../../widgets/search_autocomplete.dart';
import '../../global/variablen.dart' as global_var;
import 'chat_details.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var userName = FirebaseAuth.instance.currentUser.displayName;
  var userEmail = FirebaseAuth.instance.currentUser.email;
  var searchAutocomplete;
  List allName, userFriendlist, dbProfilData, globalChatGroups = [];

  @override
  void initState() {
    checkNewMessageCounter();
    initilizeCreateChatData();

    super.initState();
  }

  initilizeCreateChatData() {
    dynamic userFriendIdList = Hive.box("secureBox").get("ownProfil")["friendlist"];
    dbProfilData =Hive.box("secureBox").get("profils");
    allName = [];
    userFriendlist = [];
    var ownProfil = Hive.box('secureBox').get("ownProfil");


    for (var data in dbProfilData) {
      if(!ownProfil["geblocktVon"].contains(data["id"])) allName.add(data["name"]);

      for (var user in userFriendIdList) {
        if (data["id"] == user && !ownProfil["geblocktVon"].contains(data["id"])) {
          userFriendlist.add(data["name"]);
          break;
        }
      }
    }
  }

  selectChatpartnerWindow() async {
    userFriendlist ??= [];

    return showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            height: 800,
            title: AppLocalizations.of(context).neuenChatEroeffnen,
            children: [
              personenSuchBox(buildContext, allName),
              ...createFriendlistBox(userFriendlist)
            ],
          );
        }
    );

  }

  searchUser() async {
    var chatPartner = searchAutocomplete.getSelected()[0];
    var chatPartnerId =
        await ProfilDatabase().getData("id", "WHERE name = '$chatPartner'");

    validCheckAndOpenChatgroup(chatPartnerID: chatPartnerId, name: chatPartner);
  }

  Widget personenSuchBox(buildContext, allName) {
    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).personSuchen,
      searchableItems: allName,
      onConfirm: () {
        searchUser();
      },
    );

    return Center(child: SizedBox(width: 300, child: searchAutocomplete));
  }

  List<Widget> createFriendlistBox(userFriendlist) {
    List<Widget> friendsBoxen = [];
    for (var friend in userFriendlist) {

      friendsBoxen.add(GestureDetector(
        onTap: () => validCheckAndOpenChatgroup(name: friend),
        child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        width: 1, color: global_var.borderColorGrey))),
            child: Text(friend)),
      ));
    }

    if (userFriendlist.isEmpty) {
      return [
        Center(
            heightFactor: 10,
            child: Text(AppLocalizations.of(context).nochKeineFreundeVorhanden,
                style: const TextStyle(color: Colors.grey)))
      ];
    }

    return friendsBoxen;
  }

  findUserGetId(user) async {
    var foundOnName =
        await ProfilDatabase().getData("id", "WHERE name = '$user'");
    var foundOnEmail =
        await ProfilDatabase().getData("id", "WHERE email = '$user'");

    if (foundOnName != null) return foundOnName;
    if (foundOnEmail != null) return foundOnEmail;

    return null;
  }

  validCheckAndOpenChatgroup({chatPartnerID, name}) async {
    chatPartnerID ??=
        await ProfilDatabase().getData("id", "WHERE name = '$name'");
    var checkAndIndex = checkNewChatGroup(chatPartnerID);

    Navigator.pop(context);

    if (checkAndIndex[0]) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatDetailsPage(
                    chatPartnerId: chatPartnerID,
                    chatPartnerName: name,
                  ))).whenComplete(() => setState(() {}));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatDetailsPage(
                    groupChatData: globalChatGroups[checkAndIndex[1]],
                  ))).whenComplete(() => setState(() {}));
    }
  }

  checkNewChatGroup(chatPartnerId) {
    var check = [true, -1];

    for (var i = 0; i < globalChatGroups.length; i++) {
      var users = globalChatGroups[i]["users"];
      if (users[chatPartnerId] != null) {
        check = [false, i];
      }
    }

    return check;
  }

  checkNewMessageCounter() async {
    var dbNewMessages =
        await ProfilDatabase().getData("newMessages", "WHERE id = '$userId'");
    num realNewMessages = 0;

    for (var group in globalChatGroups) {
      var users = group["users"];
      realNewMessages += users[userId]["newMessages"];
    }

    if (dbNewMessages != realNewMessages) {
      ProfilDatabase().updateProfil("newMessages = '$realNewMessages'", "WHERE id = '$userId'");
    }
  }

  cutMessage(message) {
    if (message.length > 80) message = message.substring(0, 80) + "...";
    var messageList = message.split("\n") ?? [];

    if (messageList.length > 2) {
      message =
          [messageList[0] ?? " " + messageList[1] ?? " "].join("\n") + " ...";
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {

    chatUserList(groupdata) {
      List<Widget> groupContainer = [];
      for (dynamic group in groupdata) {
        String chatPartnerName = "";
        Map chatPartnerProfil;
        String chatPartnerId;
        var users = group["users"];

        users.forEach((key, value) async {
          if (key != userId) {
            chatPartnerId = key;
          }
        });

        for (var profil in dbProfilData) {
          if (profil["id"] == chatPartnerId) {
            chatPartnerName = profil["name"];
            chatPartnerProfil = profil;
            break;
          }
        }

        if (chatPartnerName.isEmpty) chatPartnerName = AppLocalizations.of(context).geloeschterUser;
        chatPartnerProfil ??= {"bild": ["assets/WeltFlugzeug.png"]};

        var lastMessage = cutMessage(group["lastMessage"]);
        var ownChatNewMessages = users[userId]["newMessages"];
        var lastMessageTime =
            DateTime.fromMillisecondsSinceEpoch(group["lastMessageDate"]);

        groupContainer.add(InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatDetailsPage(
                        chatPartnerName: chatPartnerName,
                        groupChatData: group,
                      ))).whenComplete(() => setState(() {})),
          child: Container(
              padding: const EdgeInsets.only(
                  left: 10, right: 10, top: 15, bottom: 15),
              decoration: BoxDecoration(
                  border: Border(
                bottom: BorderSide(width: 1, color: global_var.borderColorGrey),
              )),
              child: Row(
                children: [
                  ProfilImage(chatPartnerProfil),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chatPartnerName,

                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(lastMessage,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]))
                        ]),
                  ),
                  //const Expanded(child: SizedBox.shrink()),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(DateFormat('dd-MM HH:mm').format(lastMessageTime),
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 10),
                        ownChatNewMessages == 0
                            ? const SizedBox(height: 30)
                            : Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    shape: BoxShape.circle),
                                child: Center(
                                  child: FittedBox(
                                    child: Text(
                                      ownChatNewMessages.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ))
                      ])
                ],
              )),
        ));
      }

      return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child: ListView(shrinkWrap: true, children: groupContainer),
        ),
      );
    }

    return Scaffold(
      body: Container(
          padding: const EdgeInsets.only(top: kIsWeb ? 0 : 24),
          child: FutureBuilder(
              future: ChatDatabase().getChatData("*",
                  "WHERE id like '%$userId%' ORDER BY lastMessageDate DESC",
                  returnList: true),
              builder: (context, snapshot) {
                var myChatBox = Hive.box("secureBox");
                dynamic data = myChatBox.get("myChats");

                if (snapshot.hasData) {
                  data = snapshot.data == false ? [] : snapshot.data;
                  myChatBox.put("myChats", data);
                }

                if (data != null && data.isNotEmpty) {

                  var selectedChats = [];
                  var blockedVonList = Hive.box('secureBox').get("ownProfil")["geblocktVon"];

                  for(var chat in data){
                    var isBlocked = false;

                    for(var user in chat["users"].keys){
                      if(user == userId) continue;

                      if(blockedVonList.contains(user)){
                        isBlocked = true;
                      }
                    }
                    if(!isBlocked) selectedChats.add(chat);
                  }

                  return chatUserList(selectedChats);
                }

                return Center(
                    heightFactor: 20,
                    child: Text(
                        AppLocalizations.of(context).nochKeineChatsVorhanden,
                        style:
                            const TextStyle(fontSize: 20, color: Colors.grey)));
              })),
      floatingActionButton: FloatingActionButton(
        heroTag: "newChat",
        child: const Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
