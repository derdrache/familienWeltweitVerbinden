import 'dart:convert';
import 'dart:ui';

import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:familien_suche/widgets/dialogWindow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../global/global_functions.dart';
import '../../services/database.dart';
import '../../widgets/profil_image.dart';
import '../../widgets/search_autocomplete.dart';
import '../../global/variablen.dart' as global_var;
import '../../widgets/strike_through_icon.dart';
import 'chat_details.dart';

class ChatPage extends StatefulWidget {
  int chatPageSliderIndex;

  ChatPage({Key key, this.chatPageSliderIndex}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var searchAutocomplete;
  List dbProfilData = Hive.box("secureBox").get("profils") ?? [];
  List myChats = Hive.box("secureBox").get("myChats") ?? [];
  List myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  List allName, userFriendlist;
  bool changeBarOn = false;
  var selectedChats = [];
  bool firstSelectedIsPinned = false;
  bool firstSelectedIsMute = false;
  bool bothDelete = false;
  bool isLoaded = false;
  var mainSlider;
  bool activeChatSearch = false;
  var seachSearchInputNode = FocusNode();
  var searchTextKontroller = TextEditingController();
  var searchListMyGroups = [];
  var searchListAllChatgroups = [];

  @override
  void initState() {
    mainSlider = widget.chatPageSliderIndex;
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
    await refreshHiveChats();
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
    var chatPartnerId =
        getProfilFromHive(profilName: chatPartnerName, getIdOnly: true);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatDetailsPage(
                  chatPartnerId: chatPartnerId,
                  chatPartnerName: chatPartnerName,
                backToChatPage: true,
                  chatPageSliderIndex: mainSlider
                ))).whenComplete(() => refreshChatDataFromDb());
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

  getSelectedChatData() {
    if (mainSlider == 0) {
      var bothChats = myChats + myGroupChats;

      bothChats.sort(
          (a, b) => (b['lastMessageDate']).compareTo(a['lastMessageDate']));

      return bothChats;
    } else if (mainSlider == 1) {
      return myChats;
    } else if (mainSlider == 2) {
      return myGroupChats;
    }
  }

  @override
  Widget build(BuildContext context) {
    myChats = Hive.box("secureBox").get("myChats") ?? [];
    myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];

    getChatGroupName(chatConnected, {withPrivateEvents}) {
      if (chatConnected.isEmpty) return AppLocalizations.of(context).weltChat;

      var connectedId = chatConnected.split("=")[1];
      if (chatConnected.contains("event")) {
        var eventData = getEventFromHive(connectedId);
        var isPrivate = ["privat", "private"].contains(eventData["art"]);
        return isPrivate ? "" : eventData["name"];
      }
      if (chatConnected.contains("community")) {
        return getCommunityFromHive(connectedId)["name"];
      }
      if (chatConnected.contains("stadt")) {
        return getCityFromHive(cityId: connectedId, getName: true);
      }
    }

    searchChats(value) {
      searchListMyGroups = [];
      searchListAllChatgroups = [];

      if (value.isEmpty) {
        return;
      }

      var firstLetterBig = value[0].toUpperCase();
      if (value.length > 1) firstLetterBig += value.substring(1);

      List allMyChats = myChats + myGroupChats;
      for (var chat in allMyChats) {
        bool isChatGroup = chat["connected"] != null;
        var chatName = "";

        if (isChatGroup) {
          chatName = getChatGroupName(chat["connected"]);
          chatName ??= AppLocalizations.of(context).weltChat;
        } else {
          var chatUsers = chat["users"].keys.toList();
          var userPartnerId =
          chatUsers[0] != userId ? chatUsers[0] : chatUsers[1];
          chatName = getProfilFromHive(
              profilId: userPartnerId, getNameOnly: true);
        }

        if(chatName == null) continue;

        if (chatName.contains(value) ||
            chatName.contains(firstLetterBig)) {
          searchListMyGroups.add(chat);
        }
      }

      List allChatGroups =
          Hive.box("secureBox").get("chatGroups") ?? [];
      for (var chatGroup in allChatGroups) {
        var chatConnected = chatGroup["connected"];
        var chatName = getChatGroupName(chatConnected);
        chatName ??= AppLocalizations.of(context).weltChat;

        var containCondition = chatName.contains(value) ||
            chatName.contains(firstLetterBig);
        var memberOfItCondition = chatGroup["users"][userId] != null;

        if (containCondition && !memberOfItCondition) {
          searchListAllChatgroups.add(chatGroup);
        }
      }
      setState(() {});
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
        return const Center(child: Icon(Icons.push_pin));
      }
    }

    createChatGroupContainers(spezialData) {
      List<Widget> chatGroupContainers = [];

      var chatData = spezialData ?? getSelectedChatData();

      for (dynamic group in chatData) {
        String chatName = "";
        Map chatPartnerProfil;
        String chatPartnerId;

        var users = group["users"];
        var isNotChatGroup = group["connected"] == null;
        var chatData;

        if (group["lastMessage"] is int) {
          group["lastMessage"] = group["lastMessage"].toString();
        }

        if (isNotChatGroup) {
          users.forEach((key, value) async {
            if (key != userId) {
              chatPartnerId = key;
            }
          });

          for (var profil in dbProfilData) {
            if (profil["id"] == chatPartnerId) {
              chatName = profil["name"];
              chatPartnerProfil = profil;
              break;
            }
          }

          if (chatName.isEmpty) {
            chatName = AppLocalizations.of(context).geloeschterUser;
          }

          if (chatPartnerProfil == null || users[userId] == null) continue;

          var isBlocked = chatPartnerProfil["geblocktVon"].contains(userId);
          if (group["lastMessage"].isEmpty ||
              group["users"][userId] == null ||
              isBlocked) {
            continue;
          }
        } else if (group["connected"].isNotEmpty) {
          var connectedId = group["connected"].split("=")[1];

          if (group["connected"].contains("event")) {
            chatData = getEventFromHive(connectedId);
            chatName = chatData["name"];
          } else if (group["connected"].contains("community")) {
            chatData = getCommunityFromHive(connectedId);
            chatName = chatData["name"];
          } else if (group["connected"].contains("stadt")) {
            chatName = getCityFromHive(cityId: connectedId, getName: true);
            chatData = {
              "bild": Hive.box('secureBox').get("allgemein")["cityImage"]
            };
          } else if (group["connected"].contains("world")) {
            chatName = AppLocalizations.of(context).weltChat;
            chatData = {
              "bild": Hive.box('secureBox').get("allgemein")["worldChatImage"]
            };
          }
        }

        if(chatName == null) continue;

        var lastMessage = cutMessage(group["lastMessage"]);
        var ownChatNewMessages =
            users[userId] != null ? users[userId]["newMessages"] : 0;

        var isPinned =
            users[userId] != null ? users[userId]["pinned"] ?? false : false;
        var lastMessageTime =
            DateTime.fromMillisecondsSinceEpoch(group["lastMessageDate"]);
        var sortIndex = chatGroupContainers.length;

        if (isPinned) sortIndex = 0;
        if (lastMessage == "<weiterleitung>") {
          lastMessage = AppLocalizations.of(context).weitergeleitet;
        } else if (lastMessage == "</neuer Chat") {
          lastMessage = AppLocalizations.of(context).neuerChat;
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
                  changePage(context, ChatDetailsPage(
                      chatPartnerName: isNotChatGroup
                          ? chatPartnerProfil["name"]
                          : null,
                      groupChatData: group,
                      backToChatPage: true,
                      chatPageSliderIndex: mainSlider,
                      isChatgroup: !isNotChatGroup));
                }
              },
              onLongPress: () {
                setState(() {
                  changeBarOn = true;

                  firstSelectedIsPinned =
                      group["users"][userId]["pinned"] ?? false;

                  firstSelectedIsMute = group["users"][userId]["mute"] ?? false;
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
                          if (chatPartnerProfil != null)
                            ProfilImage(chatPartnerProfil),
                          if (chatData != null) ProfilImage(chatData),
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
                              Text(chatName,
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

    showAppBar() {
      if (activeChatSearch) {
        return CustomAppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: TextField(
              cursorColor: Colors.black,
              focusNode: seachSearchInputNode,
              controller: searchTextKontroller,
              textInputAction: TextInputAction.search,
              maxLines: 1,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: AppLocalizations.of(context).suche,
                  suffixIcon: CloseButton(
                    color: Colors.white,
                    onPressed: () {
                      searchTextKontroller.clear();
                    },
                  )),
              onChanged: (value) => searchChats(value),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_sharp),
              color: Colors.black,
              onPressed: () {
                setState(() {
                  searchTextKontroller.text = "";
                  activeChatSearch = false;
                });
              },
            ));
      } else if (changeBarOn) {
        return CustomAppBar(
          title: "",
          withLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
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
        );
      } else {
        return CustomAppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Center(
            child: CupertinoSlidingSegmentedControl(
              children: {
                0: Text(
                  AppLocalizations.of(context).alle,
                  style: const TextStyle(color: Colors.black),
                ),
                1: Text(AppLocalizations.of(context).private,
                    style: const TextStyle(color: Colors.black)),
                2: Text(AppLocalizations.of(context).gruppen,
                    style: const TextStyle(color: Colors.black))
              },
              backgroundColor: Colors.transparent,
              groupValue: mainSlider,
              onValueChanged: (value) {
                setState(() {
                  mainSlider = value;
                });
              },
            ),
          ),
          withLeading: false,
          buttons: [
            IconButton(
                onPressed: () {
                  setState(() {
                    activeChatSearch = true;
                  });
                },
                icon: const Icon(
                  Icons.search,
                  size: 30,
                )),
            const SizedBox(
              width: 10,
            )
          ],
        );
      }
    }

    return Scaffold(
      appBar: showAppBar(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: myChats.isNotEmpty
              ? MediaQuery.removePadding(
                  removeTop: true,
                  context: context,
                  child: ScrollConfiguration(
                    behavior:
                        ScrollConfiguration.of(context).copyWith(dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    }),
                    child: searchTextKontroller.text.isEmpty
                        ? ListView(
                            shrinkWrap: true,
                            children: createChatGroupContainers(null))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                      border: Border(top: BorderSide())),
                                  padding: const EdgeInsets.all(10),
                                  child: const Text("Chats",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20))),
                              Expanded(
                                child: searchListMyGroups.isNotEmpty
                                    ? ListView(
                                        shrinkWrap: true,
                                        children: createChatGroupContainers(
                                            searchListMyGroups),
                                      )
                                    : Center(
                                        child: Text(
                                        AppLocalizations.of(context)
                                            .keineErgebnisse,
                                        style: TextStyle(fontSize: 20),
                                      )),
                              ),
                              Container(
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                      border: Border(top: BorderSide())),
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                      AppLocalizations.of(context).globaleSuche,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20))),
                              Expanded(
                                child: searchListAllChatgroups.isNotEmpty
                                    ? ListView(
                                        shrinkWrap: true,
                                        children: createChatGroupContainers(
                                            searchListAllChatgroups),
                                      )
                                    : Center(
                                        child: Text(
                                            AppLocalizations.of(context)
                                                .keineErgebnisse,
                                            style: TextStyle(fontSize: 20))),
                              ),
                            ],
                          ),
                  ),
                )
              : !isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      heightFactor: 20,
                      child: Text(
                          AppLocalizations.of(context).nochKeineChatsVorhanden,
                          style: const TextStyle(
                              fontSize: 20, color: Colors.grey)))),
      floatingActionButton: FloatingActionButton(
        heroTag: "newChat",
        child: const Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
