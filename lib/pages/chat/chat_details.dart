import 'dart:async';
import 'dart:ui';
import 'package:familien_suche/global/global_functions.dart'
    as global_functions;
import 'package:familien_suche/pages/events/eventCard.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../global/custom_widgets.dart';

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

class _ChatDetailsPageState extends State<ChatDetailsPage> with WidgetsBindingObserver{
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
  var chatPartnerProfil;

  @override
  void dispose() {
    ProfilDatabase().updateProfil(userId, "activeChat", "");
    WidgetsBinding.instance.removeObserver(this);
    timer.cancel();
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed){
      ProfilDatabase().updateProfil(userId, "activeChat", widget.chatId);
    }else{
      ProfilDatabase().updateProfil(userId, "activeChat", "");
    }
  }

  @override
  void initState() {
    _asyncMethod();

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  _asyncMethod() async {
    await getAndSetChatData();
    writeActiveChat();
    getChatPartnerProfil();

    if(widget.groupChatData != false) resetNewMessageCounter();

    setState(() {

    });

    timer = Timer.periodic(
        Duration(seconds: 10), (Timer t) => checkNewMessages());
  }

  checkNewMessages() {
    setState(() {});
  }

  getAndSetChatData() async {
    if (widget.groupChatData != null) {
      if(widget.groupChatData["id"] == null) newChat = true;

      widget.chatId = widget.groupChatData["id"];
      var groupchatUsers = widget.groupChatData["users"];
      groupchatUsers.forEach((key, value) {
        if (key != userId) {
          widget.chatPartnerId = key;
        }
      });

      widget.chatPartnerName ??= await ProfilDatabase()
          .getData("name", "WHERE id = '${widget.chatPartnerId}'");

      return;
    }


    widget.chatPartnerId ??= await ProfilDatabase()
        .getData("id", "WHERE name = '${widget.chatPartnerName}'");


    widget.chatPartnerName ??= await ProfilDatabase()
        .getData("name", "WHERE id = '${widget.chatPartnerId}'");


    widget.chatId ??=
        global_functions.getChatID([userId, widget.chatPartnerId]);

    widget.groupChatData ??= await ChatDatabase().getChatData("*", "WHERE id = '$widget.chatId'");

    if (widget.groupChatData == false) {
      newChat = true;
    }
  }

  writeActiveChat() {
    ProfilDatabase().updateProfil(userId, "activeChat", widget.chatId);
  }

  getChatPartnerProfil() async{
    chatPartnerProfil = await ProfilDatabase()
        .getData("*", "WHERE id = '${widget.chatPartnerId}'");
  }

  resetNewMessageCounter() async {
    var users = widget.groupChatData["users"];

    var usersChatNewMessages = users[userId]["newMessages"];

    if (usersChatNewMessages == 0) return;

    var usersAllNewMessages = await ProfilDatabase()
        .getData("newMessages", "WHERE id = '${userId}'");
    usersAllNewMessages = usersAllNewMessages;

    ProfilDatabase().updateProfil(
        userId,
        "newMessages",
        usersAllNewMessages - usersChatNewMessages < 0
            ? 0
            : usersAllNewMessages - usersChatNewMessages);
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
      "date": DateTime.now().millisecondsSinceEpoch,
      "zu": widget.chatPartnerId
    };
    if (newChat) {

      widget.groupChatData = await ChatDatabase().addNewChatGroup(
          {userID: userName, widget.chatPartnerId: widget.chatPartnerName},
          messageData);

      setState(() {
        widget.chatId = widget.groupChatData["id"];
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
    chatPartnerProfil ??= await ProfilDatabase()
          .getData("*", "WHERE id = '${widget.chatPartnerId}'");


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

      for (var i = 0; i< messages.length; i++) {
        var message = messages[i];
        var messageTime = DateTime.fromMillisecondsSinceEpoch(int.parse(message["date"]));
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
            messageBox.add(
                Align(
                  alignment: textAlign,
                  child: FutureBuilder(
                    future: EventDatabase()
                        .getData("*", "WHERE id = '${message["message"].substring(10)}'"),
                    builder: (context, snapshot) {
                      if(snapshot.hasData && snapshot.data != false) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 25),
                          child: Stack(
                            clipBehavior: Clip.none, children: [
                            EventCard(
                              margin: EdgeInsets.all(15),
                              withInteresse: true,
                              event: snapshot.data,
                              afterPageVisit: () => setState((){}),
                            ),
                            Positioned(
                              bottom: -15,
                              right: 0,
                              child: Text(
                                  DateFormat('dd-MM HH:mm').format(messageTime),
                                  style: TextStyle(color: Colors.grey[600])
                              ),
                            )
                            ]
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    }
                  ),
                )
            );
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
                      child: Text(
                          DateFormat('dd-MM HH:mm').format(messageTime),
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
          future: ChatDatabase().getAllMessages(widget.chatId),
          builder: (
            BuildContext context,
            AsyncSnapshot snap,
          ) {
            if (snap.connectionState == ConnectionState.waiting) {
              return pufferList ?? Center(child: CircularProgressIndicator());
            } else if (snap.data != null) {
              List<dynamic> messages = snap.data;

              messages.sort((a, b) => (a["date"]).compareTo(b["date"]));
              pufferList = messageList(messages);
              return pufferList;
            }
            return Container();
          });
    }

    textEingabe(){
      var myFocusNode = FocusNode();

      return Stack(
        children: [
          Container(
            padding: EdgeInsets.only(left: 10, right: 50),
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
                constraints: BoxConstraints(
                  maxHeight: 300.0,
                ),
                child: TextField(
                  maxLines: null,
                  focusNode: myFocusNode,
                  textInputAction: TextInputAction.newline,
                  controller: nachrichtController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).nachricht,
                  ),
                ),
              ),
          ),
          Positioned(
            bottom: 0,
            right: 2,
            child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  messageToDbAndClearMessageInput(nachrichtController.text);

                  setState(() {
                    nachrichtController.clear();
                  });
                },
                icon: Icon(Icons.send,
                    size: 30, color: Theme.of(context).colorScheme.secondary)
            ),
          ),
        ],
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
