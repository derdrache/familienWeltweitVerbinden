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
import '../../widgets/strike_through_icon.dart';
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
  var selectedChats = [];
  var firstSelectedIsPinned = false;
  var firstSelectedIsMute = false;
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

      if (users[userId] == null) continue;

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
      if (!ownProfil["geblocktVon"].contains(data["id"]) &&
          data["id"] != "bbGp4rxJvCMywMI7eTahtZMHY2o2" &&
          data["id"] != userId) {
        allName.add(data["name"]);
      }

      for (var user in userFriendIdList) {
        if (data["name"] == user &&
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

  deleteChat(choosenChatIds, {deleteBoth = false}) async {
    for (var choosenChatId in choosenChatIds) {
      var chat = {};

      for (var myChat in myChats) {
        if (myChat["id"] == choosenChatId) {
          chat = myChat;
        }
      }

      var chatUsers = chat["users"];

      if (chatUsers.length <= 1 || deleteBoth) {
        var removeChat = {};

        for (var myChat in myChats) {
          if (myChat["id"] == choosenChatId) removeChat = myChat;
        }

        myChats.remove(removeChat);

        ChatDatabase().deleteChat(choosenChatId);
        ChatDatabase().deleteMessages(choosenChatId);
      } else {
        var newChatUsersData = {};

        chatUsers.forEach((key, value) {
          if (key != userId) {
            newChatUsersData = {key: value};
          }
        });

        for (var myChat in myChats) {
          if (myChat["id"] == choosenChatId) {
            myChat["users"] = newChatUsersData;
          }
        }

        ChatDatabase().updateChatGroup(
            "users = '${json.encode(newChatUsersData)}'",
            "WHERE id ='$choosenChatId'");
      }
    }

    setState(() {});
  }

  deleteChatDialog(chatgroupData) {
    var countSelected = 0;
    var choosenChatgroupsId = [];
    var chatPartnerName = "";

    if (selectedChats.length == 1) {
      var chatId = choosenChatgroupsId[0];
      var chatPartnerId = chatId.replaceAll(userId, "").replaceAll("_", "");

      for (var profil in dbProfilData) {
        if (profil["id"] == chatPartnerId) {
          chatPartnerName = profil["name"];
          break;
        }
      }
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context).chatLoeschen,
              height: countSelected == 1 ? 150 : 100,
              children: [
                Center(
                    child: Text(
                        AppLocalizations.of(context).chatWirklichLoeschen)),
                if (countSelected == 1) const SizedBox(height: 20),
                if (countSelected == 1)
                  Row(
                    children: [
                      Checkbox(
                          value: deleteBoth,
                          onChanged: (value) {
                            setState(() {
                              deleteBoth = value;
                            });
                          }),
                      Expanded(
                        child: Text(
                            AppLocalizations.of(context).auchBeiLoeschen +
                                chatPartnerName),
                      ) //widget.chatPartnerName)
                    ],
                  )
              ],
              actions: [
                TextButton(
                  child: Text(AppLocalizations.of(context).loeschen),
                  onPressed: () async {
                    Navigator.pop(context);
                    changeBarOn = false;
                    selectedChats = [];
                    deleteChat(choosenChatgroupsId, deleteBoth: deleteBoth);
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context).abbrechen),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          });
        });
  }

  pinChat() {
    for (var choosenChatId in selectedChats) {
      var chat = {};

      for (var myChat in myChats) {
        if (myChat["id"] == choosenChatId) {
          chat = myChat;
        }
      }

      var chatIsPinned = chat["users"][userId]["pinned"] ?? false;
      chatIsPinned = chatIsPinned == "true";

      chat["users"][userId]["pinned"] = !chatIsPinned;

      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinned', '${!chatIsPinned}')",
          "WHERE id = '${chat["id"]}'");
    }

    setState(() {});
  }

  muteChat(){
    for (var choosenChatId in selectedChats) {
      var chat = {};

      for (var myChat in myChats) {
        if (myChat["id"] == choosenChatId) {
          chat = myChat;
        }
      }

      var chatIsMute = chat["users"][userId]["mute"] ?? false;
      chatIsMute = chatIsMute == "true";

      chat["users"][userId]["mute"] = !chatIsMute;

      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.mute', '${!chatIsMute}')",
          "WHERE id = '${chat["id"]}'");
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    muteDialog(chatGroupData) {
      var chatIsMute = chatGroupData["users"][userId]["mute"] ?? false;
      chatIsMute = chatIsMute == "true";

      return SimpleDialogOption(
        child: Row(
          children: [
            Icon(chatIsMute
                ? Icons.notifications_active
                : Icons.notifications_off),
            const SizedBox(width: 10),
            Text(chatIsMute
                ? AppLocalizations.of(context).stummEin
                : AppLocalizations.of(context).stummAus),
          ],
        ),
        onPressed: () {
          Navigator.pop(context);

          setState(() {
            chatGroupData["users"][userId]["mute"] = !chatIsMute;
          });

          ChatDatabase().updateChatGroup(
              "users = JSON_SET(users, '\$.$userId.mute', '${!chatIsMute}')",
              "WHERE id = '${chatGroupData["id"]}'");
        },
      );
    }

    newMessageAndPinnedBox(newMessages, isPinned) {
      if (newMessages == 0 && !isPinned) return const SizedBox(height: 30);

      if (newMessages > 0) {
        return Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle),
            child: Center(
              child: FittedBox(
                child: Text(
                  newMessages.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ));
      } else if (isPinned) {
        return Center(child: Icon(Icons.push_pin));
      }
    }

    createChatGroupContainers(groupdata) {
      List<Widget> chatGroupContainers = [];

      for (dynamic group in groupdata) {
        String chatPartnerName = "";
        Map chatPartnerProfil;
        String chatPartnerId;
        var users = group["users"];

        if (group["lastMessage"].isEmpty || group["users"][userId] == null)
          continue;

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
        var isPinned = users[userId]["pinned"] == "true";
        var lastMessageTime =
            DateTime.fromMillisecondsSinceEpoch(group["lastMessageDate"]);
        var sortIndex = chatGroupContainers.length;

        if (isPinned) sortIndex = 0;
        if (lastMessage == "<weiterleitung>")
          lastMessage = AppLocalizations.of(context).weitergeleitet;

        chatGroupContainers.insert(
            sortIndex,
            InkWell(
              onTap: () {
                if (changeBarOn) {
                  var markerOn = false;

                  setState(() {
                    if(selectedChats.contains(group["id"])){
                      selectedChats.remove(group["id"]);
                    }else{
                      selectedChats.add(group["id"]);
                    }

                    if(selectedChats.length > 0) markerOn = true;
                    if(selectedChats.length == 0){
                      firstSelectedIsMute = false;
                      firstSelectedIsPinned = false;
                    }


                    changeBarOn = markerOn;
                  });
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatDetailsPage(
                                chatPartnerName: chatPartnerName,
                                groupChatData: group,
                              ))).whenComplete(() => setState(() {}));
                }
              },
              onLongPress: () {
                setState(() {
                  changeBarOn = true;
                  firstSelectedIsPinned = group["users"][userId]["pinned"] == "true";
                  firstSelectedIsMute = group["users"][userId]["mute"] == "true";
                  selectedChats.add(group["id"]);
                });
              },
              child: Container(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 15, bottom: 15),
                  decoration: BoxDecoration(
                      border: Border(
                    bottom:
                        BorderSide(width: 1, color: global_var.borderColorGrey),
                  )),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          ProfilImage(chatPartnerProfil),
                          if (selectedChats.contains(group["id"]))
                            const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 24,
                                    color: Colors.green,
                                  ),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
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
                            Text(
                                DateFormat('dd-MM HH:mm')
                                    .format(lastMessageTime),
                                style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 10),
                            newMessageAndPinnedBox(ownChatNewMessages, isPinned)
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
                    selectedChats = [];
                  });
                },
              ),
              buttons: [
                IconButton(
                    onPressed: () => muteChat(),
                    icon: selectedChats.length == 1 && firstSelectedIsMute
                        ? Icon(Icons.notifications_active)
                        : Icon(Icons.notifications_off)),
                IconButton(
                    onPressed: () => pinChat(),
                    icon: selectedChats.length == 1 && firstSelectedIsPinned
                        ? StrikeThroughIcon(child: Icon(Icons.push_pin))
                        : Icon(Icons.push_pin)),
                IconButton(
                    onPressed: () => deleteChatDialog(""),
                    icon: const Icon(Icons.delete))
              ],
            )
          : CustomAppBar(
              title: "",
              withLeading: false,
              buttons: const [
                IconButton(onPressed: null, icon: Icon(Icons.search))
              ],
            ),
      body: FutureBuilder(
          future: ChatDatabase().getChatData(
              "*", "WHERE id like '%$userId%' ORDER BY lastMessageDate DESC",
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
                  behavior:
                      ScrollConfiguration.of(context).copyWith(dragDevices: {
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
                    style: const TextStyle(fontSize: 20, color: Colors.grey)));
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
