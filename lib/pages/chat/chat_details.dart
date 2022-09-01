import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:familien_suche/global/global_functions.dart'
    as global_functions;
import 'package:familien_suche/pages/community/community_card.dart';
import 'package:familien_suche/pages/events/eventCard.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/dialogWindow.dart';

class ChatDetailsPage extends StatefulWidget {
  String chatPartnerId;
  String chatPartnerName;
  String chatId;
  var groupChatData;

  ChatDetailsPage({
    Key key,
    this.chatPartnerId,
    this.chatPartnerName,
    this.chatId,
    this.groupChatData,
  }) : super(key: key);

  @override
  _ChatDetailsPageState createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage>
    with WidgetsBindingObserver {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var userName = FirebaseAuth.instance.currentUser.displayName;
  var nachrichtController = TextEditingController();
  Timer timer;
  List<dynamic> messages = [];
  Widget pufferList = const Center(child: CircularProgressIndicator());
  var eventCardList = [];
  var chatPartnerProfil;

  @override
  void dispose() {
    ProfilDatabase().updateProfil("activeChat = '" "'", "WHERE id = '$userId'");
    WidgetsBinding.instance.removeObserver(this);
    timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ProfilDatabase().updateProfil(
          "activeChat = '$widget.chatId'", "WHERE id = '$userId'");
    } else {
      ProfilDatabase()
          .updateProfil("activeChat = '" "'", "WHERE id = '$userId'");
    }
  }

  @override
  void initState() {
    _asyncMethod();

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  _asyncMethod() async {
    await createNewChat();
    await getAndSetChatData();
    writeActiveChat();
    await getChatPartnerProfil();

    if (widget.groupChatData != false) resetNewMessageCounter();

    setState(() {});

    timer = Timer.periodic(
        const Duration(seconds: 10), (Timer t) => checkNewMessages());
  }

  createNewChat() async {
    if (widget.groupChatData["id"] != null) return;

    var userID = FirebaseAuth.instance.currentUser.uid;
    widget.chatPartnerId ??= await ProfilDatabase()
        .getData("id", "WHERE name = '${widget.chatPartnerName}'");
    widget.chatPartnerName ??= await ProfilDatabase()
        .getData("name", "WHERE id = '${widget.chatPartnerId}'");

    var chatUsers = {
      userID: userName,
      widget.chatPartnerId: widget.chatPartnerName
    };

    widget.groupChatData = await ChatDatabase().addNewChatGroup(chatUsers);
  }

  getAndSetChatData() async {
    widget.chatId = widget.groupChatData["id"];
    var groupchatUsers = widget.groupChatData["users"];
    groupchatUsers.forEach((key, value) {
      if (key != userId) {
        widget.chatPartnerId = key;
      }
    });

    widget.chatPartnerName ??= await ProfilDatabase()
        .getData("name", "WHERE id = '${widget.chatPartnerId}'");
  }

  writeActiveChat() {
    ProfilDatabase()
        .updateProfil("activeChat = '$widget.chatId'", "WHERE id = '$userId'");
  }

  getChatPartnerProfil() async {
    chatPartnerProfil = await ProfilDatabase()
        .getData("*", "WHERE id = '${widget.chatPartnerId}'");
  }

  resetNewMessageCounter() async {
    var users = widget.groupChatData["users"];

    var usersChatNewMessages = users[userId]["newMessages"];

    if (usersChatNewMessages == 0) return;

    var usersAllNewMessages =
        await ProfilDatabase().getData("newMessages", "WHERE id = '$userId'");
    usersAllNewMessages = usersAllNewMessages - usersChatNewMessages < 0
        ? 0
        : usersAllNewMessages - usersChatNewMessages;

    ProfilDatabase().updateProfil(
        "newMessages = '$usersAllNewMessages'", "WHERE id ='$userId'");
    widget.groupChatData["users"][userId]["newMessages"] = 0;

    ChatDatabase().updateChatGroup(
        "users = '${json.encode(widget.groupChatData["users"])}'",
        "WHERE id = '${widget.groupChatData["id"]}'");
  }

  checkNewMessages() {
    setState(() {});
  }

  checkChatgroupUsers() {
    var chatUsers = widget.groupChatData["users"];

    if (chatUsers.length == 2) return;

    chatUsers.add({
      userId: {
        "name": widget.chatPartnerName.replaceAll("'", "''"),
        "newMessages": 0
      }
    });

    ChatDatabase().updateChatGroup("users = '${json.encode(chatUsers)}'",
        "WHERE id = '${widget.groupChatData["id"]}'");
  }

  messageToDbAndClearMessageInput(message) async {
    var userID = FirebaseAuth.instance.currentUser.uid;
    var checkMessage = nachrichtController.text.split("\n").join();

    if (checkMessage.isEmpty) return;

    var messageData = {
      "message": message,
      "von": userID,
      "date": DateTime.now().millisecondsSinceEpoch.toString(),
      "zu": widget.chatPartnerId
    };

    setState(() {
      messages.add(messageData);
    });

    await ChatDatabase()
        .addNewMessageAndSendNotification(widget.groupChatData, messageData);

    if (messageData["message"].contains("</eventId=")) {
      messageData["message"] = "<Event Card>";
    }
    if (messageData["message"].contains("</communityId=")) {
      messageData["message"] = "<Community Card>";
    }

    ChatDatabase().updateChatGroup(
        "lastMessage = '${messageData["message"]}' , lastMessageDate = '${messageData["date"]}'",
        "WHERE id = '${widget.chatId}'");
  }

  openProfil() async {
    chatPartnerProfil ??= await ProfilDatabase()
        .getData("*", "WHERE id = '${widget.chatPartnerId}'");

    if (chatPartnerProfil == false) return;

    global_functions.changePage(
        context,
        ShowProfilPage(
          profil: chatPartnerProfil,
        ));
  }

  removeAllNewLineAtTheEnd(message) {
    while (message.endsWith('\n')) {
      message = message.substring(0, message.length - 1);
    }

    return message;
  }

  deleteChat({bothDelete = false}) {
    var chatUsers = widget.groupChatData["users"];
    var chatId = widget.groupChatData["id"];

    if (chatUsers.length <= 1 || bothDelete) {
      ChatDatabase().deleteChat(chatId);
      ChatDatabase().deleteMessages(chatId);
    } else {
      var newChatUsers = [];

      for (var user in chatUsers) {
        if (user.keys[0] != userId) {
          newChatUsers.add(user);
        }
      }

      ChatDatabase().updateChatGroup(
          "users = '${json.encode(chatUsers)}'", "WHERE id ='$chatId'");
    }
  }

  @override
  Widget build(BuildContext context) {
    messageList(messages) {
      List<Widget> messageBox = [];

      for (var i = 0; i < messages.length; i++) {
        var message = messages[i];
        var messageTime =
            DateTime.fromMillisecondsSinceEpoch(int.parse(message["date"]));
        var textAlign = Alignment.centerLeft;
        var boxColor = Colors.white;

        if (message["message"] == "") continue;

        message["message"] = removeAllNewLineAtTheEnd(message["message"]);

        if (message["von"] == userId) {
          textAlign = Alignment.centerRight;
          boxColor = Colors.greenAccent;
        }

        if (message["message"].contains("</eventId=")) {
          messageBox.add(Align(
            alignment: textAlign,
            child: FutureBuilder(
                future: EventDatabase().getData(
                    "*", "WHERE id = '${message["message"].substring(10)}'"),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != false) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      child: Stack(clipBehavior: Clip.none, children: [
                        EventCard(
                          margin: const EdgeInsets.all(15),
                          withInteresse: true,
                          event: snapshot.data,
                          afterPageVisit: () => setState(() {}),
                        ),
                        Positioned(
                          bottom: -15,
                          right: 0,
                          child: Text(
                              DateFormat('dd-MM HH:mm').format(messageTime),
                              style: TextStyle(color: Colors.grey[600])),
                        )
                      ]),
                    );
                  }
                  return const SizedBox.shrink();
                }),
          ));
          continue;
        }
        if (message["message"].contains("</communityId=")) {
          messageBox.add(Align(
            alignment: textAlign,
            child: FutureBuilder(
                future: CommunityDatabase().getData(
                    "*", "WHERE id = '${message["message"].substring(14)}'"),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != false) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      child: Stack(clipBehavior: Clip.none, children: [
                        CommunityCard(
                          margin: const EdgeInsets.all(15),
                          withFavorite: true,
                          community: snapshot.data,
                          afterPageVisit: () => setState(() {}),
                        ),
                        Positioned(
                          bottom: -15,
                          right: 0,
                          child: Text(
                              DateFormat('dd-MM HH:mm').format(messageTime),
                              style: TextStyle(color: Colors.grey[600])),
                        )
                      ]),
                    );
                  }
                  return const SizedBox.shrink();
                }),
          ));
          continue;
        }

        messageBox.add(
          Align(
            alignment: textAlign, //right and left
            child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: boxColor,
                    border: Border.all(),
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  alignment: WrapAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          top: 5, left: 10, bottom: 7, right: 10),
                      child: Text(message["message"] ?? "",
                          style: const TextStyle(fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 5, right: 10),
                      child: Text(DateFormat('dd-MM HH:mm').format(messageTime),
                          style: TextStyle(color: Colors.grey[600])),
                    )
                  ],
                )),
          ),
        );
      }

      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        }),
        child: ListView(
          reverse: true,
          children: messageBox.reversed.toList(),
        ),
      );
    }

    messageAnzeige() {
      return FutureBuilder(
          future: ChatDatabase().getAllMessages(widget.chatId),
          builder: (
            BuildContext context,
            AsyncSnapshot snap,
          ) {
            if (snap.data != null) {
              messages = snap.data;

              if (messages.isEmpty) {
                return Center(
                    child: Text(
                  AppLocalizations.of(context).nochKeineNachrichtVorhanden,
                  style: const TextStyle(fontSize: 20),
                ));
              }

              messages.sort((a, b) => (a["date"]).compareTo(b["date"]));

              pufferList = messageList(messages);
              return pufferList;
            }

            return pufferList;
          });
    }

    textEingabeFeld() {
      var myFocusNode = FocusNode();

      return Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 10, right: 50, bottom: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Colors.grey)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ]),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 60,
                maxHeight: 180.0,
              ),
              child: TextField(
                maxLines: null,
                focusNode: myFocusNode,
                textInputAction: TextInputAction.newline,
                controller: nachrichtController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(0, 15, 0, 5),
                  hintText: AppLocalizations.of(context).nachricht,
                  hintStyle: const TextStyle(fontSize: 20),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 2,
            child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  checkChatgroupUsers();
                  messageToDbAndClearMessageInput(nachrichtController.text);

                  setState(() {
                    nachrichtController.clear();
                  });
                },
                icon: Icon(Icons.send,
                    size: 34, color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      );
    }

    deleteDialog() {
      return SimpleDialogOption(
        child: Row(
          children: [
            const Icon(Icons.delete),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).chatLoeschen),
          ],
        ),
        onPressed: () {
          var bothDelete = false;
          Navigator.pop(context);

          showDialog(
              context: context,
              builder: (BuildContext context) {
                return CustomAlertDialog(
                  title: AppLocalizations.of(context).chatLoeschen,
                  height: 140,
                  children: [
                    Center(
                        child: Text(
                            AppLocalizations.of(context).chatWirklichLoeschen)),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                            value: bothDelete,
                            onChanged: (value) => bothDelete = value),
                        Text(AppLocalizations.of(context).auchBeiLoeschen +
                            widget.chatPartnerName)
                      ],
                    )
                  ],
                  actions: [
                    TextButton(
                      child: Text(AppLocalizations.of(context).loeschen),
                      onPressed: () async {
                        deleteChat(bothDelete: bothDelete);
                      },
                    ),
                    TextButton(
                      child: Text(AppLocalizations.of(context).abbrechen),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                );
              });
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
                  width: 180,
                  child: SimpleDialog(
                    contentPadding: EdgeInsets.zero,
                    insetPadding:
                        const EdgeInsets.only(top: 40, left: 0, right: 10),
                    children: [deleteDialog()],
                  ),
                ),
              ],
            );
          });
    }

    return Scaffold(
        appBar: chatPartnerProfil != false
            ? CustomAppBar(
                title: widget.chatPartnerName ?? "",
                profilBildProfil: chatPartnerProfil,
                onTap: () => openProfil(),
                buttons: [
                  IconButton(
                      onPressed: () => moreMenu(),
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ))
                ],
              )
            : CustomAppBar(
                title: AppLocalizations.of(context).geloeschterUser,
                buttons: [
                    IconButton(
                        onPressed: () => moreMenu(),
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ))
                  ]),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(child: messageAnzeige()),
            textEingabeFeld(),
          ],
        ));
  }
}
