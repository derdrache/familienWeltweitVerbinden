import 'dart:convert';
import 'dart:ui';

import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:familien_suche/widgets/dialogWindow.dart';
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
  List dbProfilData = Hive.box("secureBox").get("profils");
  List allName, userFriendlist, myChats = [];
  bool changeBarOn = false;
  var changeChatsDict = {};
  var deleteBoth = false;

  @override
  void initState() {
    checkNewMessageCounter();
    initilizeCreateChatData();

    super.initState();
  }

  checkNewMessageCounter() async {
    var dbNewMessages =
        await ProfilDatabase().getData("newMessages", "WHERE id = '$userId'");
    num realNewMessages = 0;

    if (dbNewMessages == false) return;

    for (var group in myChats) {
      var users = group["users"];

      if(users[userId] == null) continue;

      realNewMessages += users[userId]["newMessages"];
    }

    if (dbNewMessages != realNewMessages) {
      ProfilDatabase().updateProfil(
          "newMessages = '$realNewMessages'", "WHERE id = '$userId'");
    }
  }

  initilizeCreateChatData() {
    dynamic userFriendIdList =
        Hive.box("secureBox").get("ownProfil")["friendlist"];
    allName = [];
    userFriendlist = [];
    var ownProfil = Hive.box('secureBox').get("ownProfil");

    for (var data in dbProfilData) {
      if (!ownProfil["geblocktVon"].contains(data["id"]) || data["id"] != "bbGp4rxJvCMywMI7eTahtZMHY2o2") {
        allName.add(data["name"]);
      }

      for (var user in userFriendIdList) {
        if (data["id"] == user &&
            !ownProfil["geblocktVon"].contains(data["id"])) {
          userFriendlist.add(data["name"]);
          break;
        }
      }
    }
  }

  selectChatpartnerWindow() async {
    userFriendlist ??= [];
    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).personSuchen,
      searchableItems: allName,
      onConfirm: () {
        searchUser();
      },
    );

    return showDialog(
        context: context,
        builder: (BuildContext buildContext) {
          return CustomAlertDialog(
            height: 800,
            title: AppLocalizations.of(context).neuenChatEroeffnen,
            children: [
              Center(child: SizedBox(width: 300, child: searchAutocomplete)),
              ...createFriendlistBox(userFriendlist)
            ],
          );
        });
  }

  searchUser() async {
    var chatPartner = searchAutocomplete.getSelected()[0];
    var chatPartnerId =
        await ProfilDatabase().getData("id", "WHERE name = '$chatPartner'");

    checkValidAndOpenChatgroup(chatPartnerID: chatPartnerId, name: chatPartner);
  }

  List<Widget> createFriendlistBox(userFriendlist) {
    List<Widget> friendsBoxen = [];
    for (var friend in userFriendlist) {
      friendsBoxen.add(GestureDetector(
        onTap: () => checkValidAndOpenChatgroup(name: friend),
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

  checkValidAndOpenChatgroup({chatPartnerID, name}) async {
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
                    groupChatData: myChats[checkAndIndex[1]],
                  ))).whenComplete(() => setState(() {}));
    }
  }

  checkNewChatGroup(chatPartnerId) {
    var isNewChat = true;
    var chatIndex = -1;

    for (var i = 0; i < myChats.length; i++) {
      var users = myChats[i]["users"];
      if (users[chatPartnerId] != null) {
        isNewChat = false;
        chatIndex = i;
      }
    }

    return [isNewChat, chatIndex];
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

  removeBlockedChats(chats) {
    var newChatList = [];
    var blockedVonList = Hive.box('secureBox').get("ownProfil")["geblocktVon"];

    for (var chat in chats) {
      var isBlocked = false;

      for (var user in chat["users"].keys) {
        if (user == userId) continue;

        if (blockedVonList.contains(user)) {
          isBlocked = true;
        }
      }
      if (!isBlocked) newChatList.add(chat);
    }

    return newChatList;
  }

  refreshDbProfilData() async {
    dbProfilData = await ProfilDatabase().getData("*", "ORDER BY ort ASC");
    if (dbProfilData == false) dbProfilData = [];

    Hive.box('secureBox').put("profils", dbProfilData);

    setState(() {});
  }

  deleteChat(choosenChatIds, {deleteBoth = false}) async{
    for(var choosenChatId in choosenChatIds){
      var chat = {};

      for(var myChat in myChats){
        if(myChat["id"] == choosenChatId){
          chat = myChat;
        }
      }

      var chatUsers = chat["users"];

      if (chatUsers.length <= 1 || deleteBoth) {
        var removeChat = {};

        for(var myChat in myChats){
          if(myChat["id"] == choosenChatId) removeChat = myChat;
        }

        myChats.remove(removeChat);

        ChatDatabase().deleteChat(choosenChatId);
        ChatDatabase().deleteMessages(choosenChatId);
      } else {
        var newChatUsersData = {};

        chatUsers.forEach((key,value){
          if (key != userId) {
            newChatUsersData = {key: value};
          }
        });

        for(var myChat in myChats){
          if(myChat["id"] == choosenChatId){
            myChat["users"] = newChatUsersData;
          }
        }

        ChatDatabase().updateChatGroup(
            "users = '${json.encode(newChatUsersData)}'", "WHERE id ='$choosenChatId'");
      }
    }

    setState(() {

    });
  }

  deleteChatDialog(chatgroupData){
    var countSelected = 0;
    var choosenChatgroupsId = [];
    var chatPartnerName = "";

    for(var chatId in changeChatsDict.keys){
      if(changeChatsDict[chatId]){
        choosenChatgroupsId.add(chatId);
        countSelected += 1;
      }
    }

    if(choosenChatgroupsId.length == 1){
      var chatId = choosenChatgroupsId[0];
      var chatPartnerId = chatId.replaceAll(userId, "").replaceAll("_", "");

      for(var profil in dbProfilData){
        if(profil["id"] == chatPartnerId){
          chatPartnerName = profil["name"];
          break;
        }
      }
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return CustomAlertDialog(
                title: AppLocalizations.of(context).chatLoeschen,
                height: countSelected == 1 ? 150 : 100,
                children: [
                  Center(
                      child: Text(
                          AppLocalizations.of(context).chatWirklichLoeschen)),
                  if(countSelected == 1) const SizedBox(height: 20),
                  if(countSelected == 1) Row(
                    children: [
                      Checkbox(
                          value: deleteBoth,
                          onChanged: (value) {
                            setState(() {
                              deleteBoth = value;
                            });
                          } ),
                      Expanded(
                        child: Text(AppLocalizations.of(context).auchBeiLoeschen +
                            chatPartnerName),
                      )//widget.chatPartnerName)
                    ],
                  )
                ],
                actions: [
                  TextButton(
                    child: Text(AppLocalizations.of(context).loeschen),
                    onPressed: () async {
                      Navigator.pop(context);
                      changeBarOn = false;
                      changeChatsDict = {};
                      deleteChat(choosenChatgroupsId, deleteBoth: deleteBoth);
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context).abbrechen),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              );
            }
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    createChatGroupContainers(groupdata) {
      List<Widget> chatGroupContainers = [];

      for (dynamic group in groupdata) {
        String chatPartnerName = "";
        Map chatPartnerProfil;
        String chatPartnerId;
        var users = group["users"];

        if(group["lastMessage"].isEmpty || group["users"][userId] == null) continue;

        changeChatsDict[group["id"]] ??= false;

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

        if (chatPartnerName.isEmpty) {
          chatPartnerName = AppLocalizations.of(context).geloeschterUser;
        }
        chatPartnerProfil ??= {
          "bild": ["assets/WeltFlugzeug.png"]
        };

        var lastMessage = cutMessage(group["lastMessage"]);
        var ownChatNewMessages = users[userId]["newMessages"];
        var lastMessageTime =
            DateTime.fromMillisecondsSinceEpoch(group["lastMessageDate"]);

        chatGroupContainers.add(InkWell(
          onTap: () {
            if(changeBarOn){
              var markerOn = false;

              setState(() {
                changeChatsDict[group["id"]] = !changeChatsDict[group["id"]];
                for(var chatId in changeChatsDict.keys){
                  if(changeChatsDict[chatId]) markerOn = true;
                  break;
                }
                changeBarOn = markerOn;
              });
            } else{
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatDetailsPage(
                        chatPartnerName: chatPartnerName,
                        groupChatData: group,
                      ))).whenComplete(() => setState(() {}));
            }
          } ,
          onLongPress: () {
            setState(() {
              changeBarOn = true;
              changeChatsDict[group["id"]] = true;
            });
          },
          child: Container(
              padding: const EdgeInsets.only(
                  left: 10, right: 10, top: 15, bottom: 15),
              decoration: BoxDecoration(
                  border: Border(
                bottom: BorderSide(width: 1, color: global_var.borderColorGrey),
              )),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ProfilImage(chatPartnerProfil),
                      if(changeChatsDict[group["id"]])
                        const Positioned(bottom: 0,right: 0, child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.check_circle, size: 24, color: Colors.green,),
                        ))
                    ],
                  ),
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

      return chatGroupContainers;
    }

    return Scaffold(
      appBar: changeBarOn
          ? CustomAppBar(
              title: "",
              withLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    changeBarOn = false;
                    for(var chatId in changeChatsDict.keys){
                      changeChatsDict[chatId] = false;
                    }
                  });
                },
              ),
        buttons: [
          IconButton(onPressed: () => deleteChatDialog(""), icon: const Icon(Icons.delete))
        ],
      )
          : CustomAppBar(
              title: "",
              withLeading: false,
              buttons: const [IconButton(onPressed: null, icon: Icon(Icons.search))],
            ),
      body: FutureBuilder(
          future: ChatDatabase().getChatData("*",
              "WHERE id like '%$userId%' ORDER BY lastMessageDate DESC",
              returnList: true),
          builder: (context, snapshot) {
            var myChatBox = Hive.box("secureBox");
            myChats = myChatBox.get("myChats");

            if (snapshot.hasData) {
              myChats = snapshot.data == false ? [] : snapshot.data;
              myChatBox.put("myChats", myChats);
            }

            if (dbProfilData.isEmpty) {
              refreshDbProfilData();
              return const Center(child: const CircularProgressIndicator());
            }

            if (myChats != null && myChats.isNotEmpty) {
              myChats = removeBlockedChats(myChats);

              return MediaQuery.removePadding(
                removeTop: true,
                context: context,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  }),
                  child: ListView(
                      shrinkWrap: true,
                      children: createChatGroupContainers(myChats)),
                ),
              );
            }

            return Center(
                heightFactor: 20,
                child: Text(
                    AppLocalizations.of(context).nochKeineChatsVorhanden,
                    style:
                        const TextStyle(fontSize: 20, color: Colors.grey)));
          }),
      floatingActionButton: FloatingActionButton(
        heroTag: "newChat",
        child: const Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
