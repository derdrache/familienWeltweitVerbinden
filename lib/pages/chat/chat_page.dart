import 'dart:convert';
import 'dart:ui';

import 'package:familien_suche/widgets/windowConfirmCancelBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../global/global_functions.dart';
import '../../global/style.dart';
import '../../services/database.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/profil_image.dart';
import '../../global/style.dart' as style;
import '../../widgets/strike_through_icon.dart';
import '../../windows/all_user_select.dart';
import '../../windows/dialog_window.dart';
import '../start_page.dart';
import 'chat_details.dart';

class ChatPage extends StatefulWidget {
  final int chatPageSliderIndex;

  const ChatPage({Key? key, required this.chatPageSliderIndex}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  var userId = FirebaseAuth.instance.currentUser!.uid;
  List dbProfilData = Hive.box("secureBox").get("profils") ?? [];
  List myChats = Hive.box("secureBox").get("myChats") ?? [];
  List myGroupChats = Hive.box("secureBox").get("myGroupChats") ?? [];
  var ownProfil = Hive.box('secureBox').get("ownProfil");
  List<String>? allName, userFriendlist;
  bool changeBarOn = false;
  var selectedChats = [];
  bool firstSelectedIsPinned = false;
  bool firstSelectedIsMute = false;
  bool bothDelete = false;
  bool isLoaded = false;
  late int mainSlider;
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

    WidgetsBinding.instance
        .addPostFrameCallback((_) async{
      await refreshHiveChats();
      setState(() {});
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
        allName!.add(data["name"]);
      }

      if (!userFriendIdList.contains(data["id"])) continue;

      for (var user in userFriendIdList) {
        if (data["id"] == user &&
            !ownProfil["geblocktVon"].contains(data["id"])) {
          userFriendlist!.add(data["name"]);
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
    String selectedUser = await AllUserSelectWindow(
        context: context,
        title: AppLocalizations.of(context)!.personSuchen,
    ).openWindow();

    if(selectedUser.isEmpty) return;

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatDetailsPage(
                chatPartnerId: selectedUser,
                backToChatPage: true,
                chatPageSliderIndex: mainSlider)))
        .whenComplete(() => changePageForever(
        context,
        StartPage(
          selectedIndex: 3,
        )));
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
      message = "${[messageList[0] ?? "${messageList[1] ?? " "}"].join("\n")} ...";
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
    for (var choosenChat in selectedChats) {
      var selectedChatId = choosenChat["id"];
      var isChatGroup = choosenChat["connected"] != null;

      if(isChatGroup){
        ChatGroupsDatabase().leaveChat(choosenChat["connected"]);
      }else{
        var chatUsers = choosenChat["users"];

        if (chatUsers.length <= 1 || bothDelete) {
          for (var myChat in myChats) {
            if (myChat["id"] == selectedChatId) {
              myChat["users"] = {};
              myChat["id"] = "";
            }
          }

          ChatDatabase().deleteChat(selectedChatId);
          ChatDatabase().deleteAllMessages(selectedChatId);
        } else {
          var newChatUsersData = {};

          chatUsers.forEach((key, value) {
            if (key != userId) {
              newChatUsersData = {key: value};
            }
          });

          for (var myChat in myChats) {
            if (myChat["id"] == selectedChatId) {
              myChat["users"] = newChatUsersData;
            }
          }

          ChatDatabase().updateChatGroup(
              "users = '${json.encode(newChatUsersData)}'",
              "WHERE id ='$selectedChatId'");
        }
      }
    }

    setState(() {});
  }

  deleteChatDialog(chatgroupData) {
    var countSelected = selectedChats.length;
    var chatPartnerName = "";
    late bool isChatGroup;

    if (countSelected == 1) {
      var selectedChatData = selectedChats[0];
      isChatGroup = selectedChatData["connected"] != null;

      if(!isChatGroup){
        var chatId = selectedChats[0]["id"];
        var chatPartnerId = chatId.replaceAll(userId, "").replaceAll("_", "");

        for (var profil in dbProfilData) {
          if (profil["id"] == chatPartnerId) {
            chatPartnerName = profil["name"];
            break;
          }
        }
      }
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return CustomAlertDialog(
              title: AppLocalizations.of(context)!.chatLoeschen,
              height: countSelected == 1 && !isChatGroup ? 150 : 100,
              children: [
                Center(
                    child: Text(countSelected == 1
                        ? AppLocalizations.of(context)!.chatWirklichLoeschen
                        : AppLocalizations.of(context)!.chatsWirklichLoeschen)),
                if (countSelected == 1 && !isChatGroup) const SizedBox(height: 20),
                if (countSelected == 1 && !isChatGroup)
                  Row(
                    children: [
                      Checkbox(
                          value: bothDelete,
                          onChanged: (value) {
                            setState(() {
                              bothDelete = value!;
                            });
                          }),
                      Expanded(
                        child: Text(
                            AppLocalizations.of(context)!.auchBeiLoeschen +
                                chatPartnerName),
                      ) //widget.chatPartnerName)
                    ],
                  ),
                WindowConfirmCancelBar(
                  confirmTitle: AppLocalizations.of(context)!.loeschen,
                  onConfirm: (){
                    changeBarOn = false;
                    deleteChat();
                    selectedChats = [];
                  },
                )
              ],
            );
          });
        });
  }

  pinChat() {
    bool? selectedIsPinned;

    for (var choosenChat in selectedChats) {
      var selectedChatId = choosenChat["id"];
      bool isChatGroup = choosenChat["connected"] != null;
      var chatIsPinned = choosenChat["users"][userId]["pinned"] ?? false;

      choosenChat["users"][userId]["pinned"] = !chatIsPinned;
      selectedIsPinned ??= !chatIsPinned;


      if(isChatGroup){
        ChatGroupsDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinned', ${!chatIsPinned})",
            "WHERE id = '$selectedChatId'");
      }else{
        ChatDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.pinned', ${!chatIsPinned})",
            "WHERE id = '$selectedChatId'");
      }
    }

    setState(() {
      firstSelectedIsPinned = selectedIsPinned!;
    });
  }

  muteChat() {
    bool? selectedIsMute;

    for (var choosenChat in selectedChats) {
      var selectedChatId = choosenChat["id"];
      bool isChatGroup = choosenChat["connected"] != null;
      var chatIsMute = choosenChat["users"][userId]["mute"] ?? false;

      choosenChat["users"][userId]["mute"] = !chatIsMute;
      selectedIsMute ??= !chatIsMute;

      if(isChatGroup){
        ChatGroupsDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.mute', ${!chatIsMute})",
            "WHERE id = '$selectedChatId'");
      }else{
        ChatDatabase().updateChatGroup(
            "users = JSON_SET(users, '\$.$userId.mute', ${!chatIsMute})",
            "WHERE id = '$selectedChatId'");
      }
    }

    setState(() {
      firstSelectedIsMute = selectedIsMute!;
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

    getChatGroupName(chatConnected) {
      if (chatConnected.isEmpty) return AppLocalizations.of(context)!.weltChat;

      var connectedId = chatConnected.split("=")[1];
      if (chatConnected.contains("event")) {
        var eventData = getMeetupFromHive(connectedId);

        if(eventData.isEmpty) return;

        var isPrivate = ["privat", "private"].contains(eventData["art"]);
        var hasAccsess = eventData["freigegeben"].contains(userId)
            || eventData["erstelltVon"] == userId;

        return isPrivate && !hasAccsess ? "" : eventData["name"];
      }
      if (chatConnected.contains("community")) {
        var communityData = getCommunityFromHive(connectedId);

        if(communityData.isEmpty) return;

        bool hasSecretChat = communityData["secretChat"]?.isOdd ?? false;
        bool isMember = communityData["members"].contains(userId)
            || communityData["erstelltVon"] == userId;
        bool hasAccess = !hasSecretChat || isMember;

        return !hasAccess ? "" :getCommunityFromHive(connectedId)["name"];
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
        String? chatName = "";

        if (isChatGroup) {
          chatName = getChatGroupName(chat["connected"]);
          chatName ??= AppLocalizations.of(context)!.weltChat;
        } else {
          var chatUsers = chat["users"].keys.toList();

          if(chatUsers.length == 1) continue;

          var userPartnerId =
              chatUsers[0] != userId ? chatUsers[0] : chatUsers[1];
          chatName =
              getProfilFromHive(profilId: userPartnerId, getNameOnly: true);
        }

        if (chatName == null) continue;

        if (chatName.contains(value) || chatName.contains(firstLetterBig)) {
          searchListMyGroups.add(chat);
        }
      }

      for(var userProfil in dbProfilData){
        String userName = userProfil["name"];
        String chatPartnerId = userProfil["id"];

        var containCondition =
            userName.contains(value) || userName.contains(firstLetterBig);
        bool chatExist = false;

        for(var chat in myChats){
          if(chat["users"][chatPartnerId] != null) chatExist = true;
        }

        if(containCondition && !chatExist){
          searchListAllChatgroups.add(userProfil);
        }
      }

      List allChatGroups = Hive.box("secureBox").get("chatGroups") ?? [];
      for (var chatGroup in allChatGroups) {
        var chatConnected = chatGroup["connected"];
        var chatName = getChatGroupName(chatConnected);
        chatName ??= AppLocalizations.of(context)!.weltChat;

        var containCondition =
            chatName.contains(value) || chatName.contains(firstLetterBig);
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
        String? chatName = "";
        Map? chatPartnerProfil;
        String? chatPartnerId;

        var users = group["users"] ?? {};
        var isChatGroup = group["connected"] != null;
        Map chatData = {};

        if (group["lastMessage"] is int) {
          group["lastMessage"] = group["lastMessage"].toString();
        }

        if(isChatGroup){
          var connectedId = group["connected"].split("=")[1];

          if (group["connected"].contains("event")) {
            chatData = getMeetupFromHive(connectedId);

            chatName = chatData["name"];
          } else if (group["connected"].contains("community")) {
            chatData = getCommunityFromHive(connectedId);
            chatName = chatData["name"];
          } else if (group["connected"].contains("stadt")) {
            chatData = Map.of(getCityFromHive(cityId: connectedId));
            chatName = chatData["ort"];
            var cityImage = chatData["bild"].isEmpty
                ? Hive.box('secureBox').get("allgemein")["cityImage"]
                : chatData["bild"];
            var countryImage = chatData["bild"].isEmpty
                ? "assets/bilder/land.jpg"
                : "assets/bilder/flaggen/${chatData["bild"]}.jpeg";

            chatData["bild"] = chatData["isCity"] == 1 ? cityImage : countryImage;

          } else if (group["connected"].contains("world")) {
            chatName = AppLocalizations.of(context)!.weltChat;
            chatData = {
              "bild": Hive.box('secureBox').get("allgemein")["worldChatImage"]
            };
          } else if(group["connected"].contains("support")){
            chatName = "Support Chat";
            chatData = {
              "bild": Hive.box('secureBox').get("allgemein")["worldChatImage"]
            };
          }

          if(chatName == null) continue;

          bool hasSecretChat = chatData["secretChat"] == 1;
          bool secretChatMember = chatData["members"] != null ?chatData["members"].contains(userId): false;

          if(hasSecretChat && !secretChatMember) continue;
        } else if (users.isNotEmpty){

          chatPartnerId = group["id"].replaceAll(userId, "").replaceAll("_", "");

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

          if (chatName!.isEmpty) {
            chatName = AppLocalizations.of(context)!.geloeschterUser;
          }

          if (chatPartnerProfil == null || users[userId] == null) continue;

          var isBlocked = chatPartnerProfil["geblocktVon"].contains(userId);
          if (group["lastMessage"].isEmpty ||
              group["users"][userId] == null ||
              isBlocked) {
            continue;
          }
        }else{
          chatName = group["name"];
          chatPartnerProfil = group;

          var isBlocked = group["geblocktVon"].contains(userId);
          if(isBlocked) continue;
        }

        var lastMessage = cutMessage(group["lastMessage"] ?? "");
        var ownChatNewMessages =
            users[userId] != null ? users[userId]["newMessages"] : 0;

        var isPinned =
            users[userId] != null ? users[userId]["pinned"] ?? false : false;
        var lastMessageTime =
            DateTime.fromMillisecondsSinceEpoch(group["lastMessageDate"] ?? 0);
        var sortIndex = chatGroupContainers.length;

        if (isPinned) sortIndex = 0;
        if (lastMessage == "<weiterleitung>") {
          lastMessage = AppLocalizations.of(context)!.weitergeleitet;
        } else if (lastMessage == "</neuer Chat") {
          lastMessage = AppLocalizations.of(context)!.neuerChat;
        } else if(lastMessage == "</images"){
          lastMessage = AppLocalizations.of(context)!.bild;
        }

        chatGroupContainers.insert(
            sortIndex,
            InkWell(
              onTap: () {
                if (changeBarOn) {
                  var markerOn = false;

                  setState(() {
                    if (selectedChats.contains(group)) {
                      selectedChats.remove(group);
                    } else {
                      selectedChats.add(group);
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
                                  chatPartnerName: isChatGroup
                                      ? null
                                      : chatPartnerProfil!["name"],
                                  groupChatData: isChatGroup ? group : null,
                                  backToChatPage: true,
                                  chatPageSliderIndex: mainSlider,
                                  isChatgroup: isChatGroup)));
                }
              },
              onLongPress: () {
                setState(() {
                  changeBarOn = true;

                  firstSelectedIsPinned =
                      group["users"][userId]["pinned"] ?? false;

                  firstSelectedIsMute = group["users"][userId]["mute"] ?? false;
                  selectedChats.add(group);
                });
              },
              child: Container(
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 15, bottom: 15),
                  decoration: BoxDecoration(
                      border: Border(
                    bottom:
                        BorderSide(width: 1, color: style.borderColorGrey),
                  )),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          if (chatPartnerProfil != null)
                            ProfilImage(chatPartnerProfil),
                          if (chatData.isNotEmpty) ProfilImage(chatData),
                          if (selectedChats.contains(group))
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
                              Text(chatName!,
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
                            newMessageAndPinnedBox(ownChatNewMessages, isPinned)!
                          ])
                    ],
                  )),
            ));
      }

      if (chatGroupContainers.isEmpty) {
        chatGroupContainers.add(Padding(
          padding: const EdgeInsets.only(top: 300),
          child: Center(
              child: Text(AppLocalizations.of(context)!.nochKeineChatsVorhanden,
                  style: const TextStyle(fontSize: 20, color: Colors.grey))),
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
                  hintText: AppLocalizations.of(context)!.suche,
                  suffixIcon: CloseButton(
                    color: Colors.white,
                    onPressed: () {
                      if(searchTextKontroller.text.isNotEmpty){
                        searchTextKontroller.clear();
                      }else{
                        setState(() {
                          activeChatSearch = false;
                        });
                      }
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
                  AppLocalizations.of(context)!.alle,
                  style: const TextStyle(color: Colors.black),
                ),
                1: Text(AppLocalizations.of(context)!.private,
                    style: const TextStyle(color: Colors.black)),
                2: Text(AppLocalizations.of(context)!.gruppen,
                    style: const TextStyle(color: Colors.black))
              },
              backgroundColor: Colors.transparent,
              groupValue: mainSlider,
              onValueChanged: (int? value) {
                setState(() {
                  mainSlider = value!;
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
                  seachSearchInputNode.requestFocus();
                },
                tooltip: AppLocalizations.of(context)!.tooltipChatPageSuche,
                icon: const Icon(
                  Icons.search,
                  size: iconSizeBig,
                )),
            const SizedBox(
              width: 10,
            )
          ],
        );
      }
    }

    showChatSearchResult(){
      List searchResults = searchListMyGroups + searchListAllChatgroups;

      if(searchResults.isEmpty){
        return Center(
            child: Text(
              AppLocalizations.of(context)!.keineErgebnisse,
              style: const TextStyle(fontSize: 20),
            ));
      }

      return ListView(
        shrinkWrap: true,
        children: createChatGroupContainers(searchResults));
    }

    return Scaffold(
      appBar: showAppBar(),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child: searchTextKontroller.text.isEmpty
              ? ListView(
                  shrinkWrap: true, children: createChatGroupContainers(null))
              : showChatSearchResult(),
        ),
      )),
      floatingActionButton: FloatingActionButton(
        heroTag: "newChat",
        tooltip: AppLocalizations.of(context)!.tooltipCreateNewChat,
        child: const Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
