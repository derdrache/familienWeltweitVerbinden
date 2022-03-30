import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:familien_suche/global/global_functions.dart'
    as global_functions;
import 'package:familien_suche/pages/events/eventCard.dart';
import 'package:familien_suche/pages/events/event_card_details.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';
import '../events/event_details.dart';

class ChatDetailsPage extends StatefulWidget {
  var chatPartnerId;
  var chatPartnerName;
  var chatId;
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

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  var userId = FirebaseAuth.instance.currentUser.uid;
  var userName = FirebaseAuth.instance.currentUser.displayName;
  bool newChat = false;
  List<Widget> messagesList = [];
  var nachrichtController = TextEditingController();
  var messageInputHeight = 50.0;
  var messageRows = 0;
  Timer timer;
  var pufferList;
  var eventCardList = [];

  @override
  void dispose() {
    ProfilDatabase().updateProfil(userId, "activeChat", "");
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _asyncMethod();

    super.initState();
  }

  _asyncMethod() async {
    await getAndSetChatData();
    await writeActiveChat();
    if(widget.groupChatData != false) await resetNewMessageCounter();

    setState(() {
      timer = Timer.periodic(
          Duration(seconds: 10), (Timer t) => checkNewMessages());
    });
  }

  Future initialize() async{
    var allMessages = await ChatDatabase().getAllMessages(widget.chatId);

    for(var message in allMessages){
      if(message["message"].contains("</eventId=")){
        var eventId = message["message"].split("=")[1];
        var eventData = await EventDatabase().getEvent(eventId);
        eventCardList.add(eventData);
      }
    }

    return allMessages;
  }

  checkNewMessages() {
    setState(() {});
  }

  getAndSetChatData() async {
    if (widget.groupChatData != null) {
      widget.chatId = widget.groupChatData["id"];
      var groupchatUsers = jsonDecode(widget.groupChatData["users"]);
      groupchatUsers.forEach((key, value) {
        if (key != userId) {
          widget.chatPartnerName = value["name"];
          widget.chatPartnerId = key;
        }
      });

      return;
    }

    widget.chatPartnerId ??=
        await ProfilDatabase().getOneData("id", "name", widget.chatPartnerName);


    widget.chatPartnerName ??=
        await ProfilDatabase().getOneData("name", "id", widget.chatPartnerId);

    widget.chatId ??=
        global_functions.getChatID([userId, widget.chatPartnerId]);

    widget.groupChatData ??= await ChatDatabase().getChat(widget.chatId);

    if (widget.groupChatData == false) {
      newChat = true;
    }
  }

  writeActiveChat() {
    ProfilDatabase().updateProfil(userId, "activeChat", widget.chatId);
  }

  resetNewMessageCounter() async {
    var users = widget.groupChatData["users"];
    if (users is String) users = json.decode(users);

    var usersChatNewMessages = users[userId]["newMessages"];

    if (usersChatNewMessages == 0) return;

    var usersAllNewMessages =
        await ProfilDatabase().getOneData("newMessages", "id", userId);
    usersAllNewMessages = usersAllNewMessages;

    ProfilDatabase().updateProfil(
        userId,
        "newMessages",
        usersAllNewMessages - usersChatNewMessages < 0
            ? 0
            : usersAllNewMessages - usersChatNewMessages);
    widget.groupChatData["users"] = json.decode(widget.groupChatData["users"]);
    widget.groupChatData["users"][userId]["newMessages"] = 0;

    ChatDatabase().updateChatGroup(
        widget.groupChatData["id"], "users", widget.groupChatData["users"]);
  }

  messageToDbAndClearMessageInput(message) async {
    var userID = FirebaseAuth.instance.currentUser.uid;

    var messageList = nachrichtController.text.split("\n");
    var checkMessage = messageList.join();

    if (checkMessage == "") return;

    var messageData = {
      "message": message,
      "von": userID,
      "date": DateTime.now().millisecondsSinceEpoch * 1000,
      "zu": widget.chatPartnerId
    };
    if (newChat) {
      widget.groupChatData = await ChatDatabase().addNewChatGroup(
          {userID: userName, widget.chatPartnerId: widget.chatPartnerName},
          messageData);

      setState(() {
        newChat = false;
      });
    } else {
      await ChatDatabase()
          .addNewMessageAndSendNotification(widget.groupChatData, messageData);

      if(messageData["message"].contains("</eventId=")){
        messageData["message"] = "<Event Card>";
      }
      ChatDatabase().updateChatGroup(
          widget.chatId, "lastMessage", messageData["message"]);
      ChatDatabase().updateChatGroup(
          widget.chatId, "lastMessageDate", messageData["date"]);

      setState(() {});
    }
  }

  countItemsInList(list, search) {
    var count = 0;

    for (var i = 0; i < list.length - search.length; i++) {
      if ((list[i] + list[i + 1] + list[i + 1]).contains(search)) {
        count += 1;
        i += 1;
      }
    }

    return count;
  }

  openProfil() async {
    var chatPartnerProfil =
        await ProfilDatabase().getProfil("id", widget.chatPartnerId);

    global_functions.changePage(
        context,
        ShowProfilPage(
          userName: userName,
          profil: chatPartnerProfil,
        ));
  }


  @override
  Widget build(BuildContext context) {

    messageList(messages){
      List<Widget> messageBox = [];
      var eventCardCounter = 0;

      for (var i = 0; i< messages.length; i++) {
        var message = messages[i];
        var textAlign = Alignment.centerLeft;
        var boxColor = Colors.white;

        if (message["von"] == userId) {
          textAlign = Alignment.centerRight;
          boxColor = Colors.greenAccent;
        }

        if (message["message"] == "") {
          continue;
        }

        if(message["message"].contains("</eventId=")){
          if (eventCardList[eventCardCounter] != false){
            messageBox.add(
                Align(
                  alignment: textAlign,
                  child: EventCard(
                    withInteresse: true,
                    event: eventCardList[eventCardCounter],
                    afterPageVisit: () => setState((){}),
                    /*
                    changePage: () => global_functions.changePage(context,
                        EventDetailsPage(event: eventCardList[eventCardCounter])),

                     */
                  ),
                )
            );
            eventCardCounter += 1;
            continue;
          }
          eventCardCounter += 1;
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
                      child: Text(
                          global_functions.dbSecondsToTimeString(
                              json.decode(message["date"])),
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

    showMessages() {
      return FutureBuilder(
          future: initialize(),
          builder: (
            BuildContext context,
            AsyncSnapshot snap,
          ) {
            if (snap.connectionState == ConnectionState.waiting) {
              return pufferList ?? const SizedBox.shrink();
            } else if (snap.data != null) {
              List<dynamic> messages = snap.data;

              messages.sort((a, b) => (a["date"]).compareTo(b["date"]));
              pufferList = messageList(messages);
              return pufferList;
            }
            return Container();
          });
    }

    textEingabe() {
      var myFocusNode = FocusNode();
      return Container(
        height: messageInputHeight,
        padding: const EdgeInsets.only(left: 10),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                child: TextField(
                  maxLines: null,
                  focusNode: myFocusNode,
                  textInputAction: TextInputAction.newline,
                  controller: nachrichtController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).nachricht,
                  ),
                  onChanged: (value) {
                    var newLineCounts = countItemsInList(value, "\n");

                    if (countItemsInList(value, "\n") != messageRows) {
                      setState(() {
                        messageInputHeight = 50.0 + newLineCounts * 15.0;
                        messageRows = newLineCounts;
                      });
                    }
                  },
                ),
              ),
            ),
            IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  messageToDbAndClearMessageInput(nachrichtController.text);

                  setState(() {
                    nachrichtController.clear();
                    messageInputHeight = 50;
                  });
                },
                icon: Icon(Icons.send,
                    size: 30, color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      );
    }

    return Scaffold(
        appBar: customAppBar(
          title: widget.chatPartnerName ?? "",
          onTap: () => openProfil(),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(child: showMessages()),
            textEingabe(),
          ],
        ));
  }
}
