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
  var searchAutocomplete;
  List dbProfilData = Hive.box("secureBox").get("profils") ?? [];
  List myChats = Hive.box("secureBox").get("myChats") ?? [];
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  List allName, userFriendlist;
  bool changeBarOn = false;
  var selectedChats = [];
  var firstSelectedIsPinned = false;
  var firstSelectedIsMute = false;
  var bothDelete = false;
  var isLoaded = false;

  @override
  void initState() {
    checkNewMessageCounter();
    initilizeCreateChatData();

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      refreshChatDataFromDb();
    });

    super.initState();
  }

  checkNewMessageCounter() async {
    var dbNewMessages = ownProfil["newMessages"];
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
    dynamic userFriendIdList = ownProfil["friendlist"];
    allName = [];
    userFriendlist = [];


    for (var data in dbProfilData) {
      if (!ownProfil["geblocktVon"].contains(data["id"]) &&
          data["id"] != "bbGp4rxJvCMywMI7eTahtZMHY2o2" &&
          data["id"] != userId) {
        allName.add(data["name"]);
      }

      if (!userFriendIdList.contains(data["id"])) continue;

      for (var user in userFriendIdList) {
        if (data["id"] == user &&
            !ownProfil["geblocktVon"].contains(data["id"])) {
          userFriendlist.add(data["name"]);
        }
      }
    }
  }

  refreshChatDataFromDb() async {
    var newDbData = await ChatDatabase().getChatData(
        "*", "WHERE id like '%$userId%' ORDER BY lastMessageDate DESC",
        returnList: true);
    if (newDbData == false) newDbData = [];

    Hive.box("secureBox").put("myChats", newDbData);
    myChats = newDbData;

    setState(() {
      isLoaded = true;
    });
  }

  selectChatpartnerWindow() async {
    userFriendlist ??= [];
    searchAutocomplete = SearchAutocomplete(
      hintText: AppLocalizations.of(context).personSuchen,
      searchableItems: allName,
      onConfirm: () {
        Navigator.pop(context);
        searchUser(searchAutocomplete.getSelected()[0]);
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

  searchUser(chatPartnerName) async {
    var chatPartnerId = getProfilFromHive(
        profilName: chatPartnerName, getIdOnly: true);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatDetailsPage(
                  chatPartnerId: chatPartnerId,
                  chatPartnerName: chatPartnerName,
                ))).whenComplete(() => setState(() {}));
  }

  List<Widget> createFriendlistBox(userFriendlist) {
    List<Widget> friendsBoxen = [];

    for (var friendName in userFriendlist) {
      friendsBoxen.add(GestureDetector(
        onTap: () => searchUser(friendName),
        child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        width: 1, color: global_var.borderColorGrey))),
            child: Text(friendName)),
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

  deleteChat() async {
    for (var choosenChatId in selectedChats) {
      var chat = {};

      for (var myChat in myChats) {
        if (myChat["id"] == choosenChatId) {
          chat = myChat;
        }
      }

      var chatUsers = chat["users"];

      if (chatUsers.length <= 1 || bothDelete) {
        for (var myChat in myChats) {
          if (myChat["id"] == choosenChatId) {
            myChat["users"] = {};
            myChat["id"] = "";
          }
        }

        ChatDatabase().deleteChat(choosenChatId);
        ChatDatabase().deleteAllMessages(choosenChatId);
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
    var countSelected = selectedChats.length;
    var chatPartnerName = "";

    if (countSelected == 1) {
      var chatId = selectedChats[0];
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
                    child: Text(countSelected == 1
                        ? AppLocalizations.of(context).chatWirklichLoeschen
                        : AppLocalizations.of(context).chatsWirklichLoeschen)),
                if (countSelected == 1) const SizedBox(height: 20),
                if (countSelected == 1)
                  Row(
                    children: [
                      Checkbox(
                          value: bothDelete,
                          onChanged: (value) {
                            setState(() {
                              bothDelete = value;
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
                    deleteChat();
                    selectedChats = [];
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
    var selectedIsPinned;

    for (var choosenChatId in selectedChats) {
      var chat = {};

      for (var myChat in myChats) {
        if (myChat["id"] == choosenChatId) {
          chat = myChat;
          break;
        }
      }

      var chatIsPinned = chat["users"][userId]["pinned"] ?? false;

      chat["users"][userId]["pinned"] = !chatIsPinned;
      selectedIsPinned ??= !chatIsPinned;

      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.pinned', ${!chatIsPinned})",
          "WHERE id = '${chat["id"]}'");
    }

    setState(() {
      firstSelectedIsPinned = selectedIsPinned;
    });
  }

  muteChat() {
    var selectedIsMute;

    for (var choosenChatId in selectedChats) {
      var chat = {};

      for (var myChat in myChats) {
        if (myChat["id"] == choosenChatId) {
          chat = myChat;
        }
      }

      var chatIsMute = chat["users"][userId]["mute"] ?? false;

      chat["users"][userId]["mute"] = !chatIsMute;
      selectedIsMute ??= !chatIsMute;

      ChatDatabase().updateChatGroup(
          "users = JSON_SET(users, '\$.$userId.mute', ${!chatIsMute})",
          "WHERE id = '${chat["id"]}'");
    }

    setState(() {
      firstSelectedIsMute = selectedIsMute;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        return const Center(child: Icon(Icons.push_pin));
      }
    }

    createChatGroupContainers(groupdata) {
      List<Widget> chatGroupContainers = [];

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

        if (chatPartnerName.isEmpty) {
          chatPartnerName = AppLocalizations.of(context).geloeschterUser;
        }

        if(chatPartnerProfil == null) continue;

        var isBlocked = chatPartnerProfil["geblocktVon"].contains(userId);
        if (group["lastMessage"].isEmpty || group["users"][userId] == null || isBlocked) {
          continue;
        }

        var lastMessage = cutMessage(group["lastMessage"]);
        var ownChatNewMessages = users[userId]["newMessages"];

        var isPinned = users[userId]["pinned"] == "true" ||
            users[userId]["pinned"] == true;
        var lastMessageTime =
            DateTime.fromMillisecondsSinceEpoch(group["lastMessageDate"]);
        var sortIndex = chatGroupContainers.length;

        if (isPinned) sortIndex = 0;
        if (lastMessage == "<weiterleitung>") {
          lastMessage = AppLocalizations.of(context).weitergeleitet;
        }

        chatGroupContainers.insert(
            sortIndex,
            InkWell(
              onTap: () {
                if (changeBarOn) {
                  var markerOn = false;

                  setState(() {
                    if (selectedChats.contains(group["id"])) {
                      selectedChats.remove(group["id"]);
                    } else {
                      selectedChats.add(group["id"]);
                    }

                    if (selectedChats.isNotEmpty) markerOn = true;
                    if (selectedChats.isEmpty) {
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
                  firstSelectedIsPinned =
                      group["users"][userId]["pinned"] == "true";
                  firstSelectedIsMute =
                      group["users"][userId]["mute"] == "true";
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
                        ? const Icon(Icons.notifications_active)
                        : const Icon(Icons.notifications_off)),
                IconButton(
                    onPressed: () => pinChat(),
                    icon: selectedChats.length == 1 && firstSelectedIsPinned
                        ? StrikeThroughIcon(child: const Icon(Icons.push_pin))
                        : const Icon(Icons.push_pin)),
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
      body: myChats.isNotEmpty
          ? MediaQuery.removePadding(
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
            )
          : !isLoaded
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  heightFactor: 20,
                  child: Text(
                      AppLocalizations.of(context).nochKeineChatsVorhanden,
                      style:
                          const TextStyle(fontSize: 20, color: Colors.grey))),
      floatingActionButton: FloatingActionButton(
        heroTag: "newChat",
        child: const Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
