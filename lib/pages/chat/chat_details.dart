import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:familien_suche/global/global_functions.dart' as global_functions;
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';

class ChatDetailsPage extends StatefulWidget {
  var groupChatData;
  bool newChat;

  ChatDetailsPage({Key key,
    this.groupChatData,
    this.newChat = false}) : super(key: key);

  @override
  _ChatDetailsPageState createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  var chatID;
  var chatPartnerID;
  var chatPartnerName;
  List<Widget> messagesList = [];
  var nachrichtController = TextEditingController();
  var userId = FirebaseAuth.instance.currentUser.uid;
  var userName = FirebaseAuth.instance.currentUser.displayName;
  var messageInputHeight = 50.0;
  var messageRows = 0;
  Timer timer;
  var pufferList;

  @override
  void dispose() {
    ProfilDatabase().updateProfil(userId, "activeChat", "");
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    chatID = widget.groupChatData["id"]?? "0";

    getAndSetChatPartnerData();

    writeActiveChat();
    resetNewMessageCounter();

    timer = Timer.periodic(Duration(seconds: 10), (Timer t) => checkNewMessages());

    super.initState();
  }

  checkNewMessages(){
    setState(() {});
  }

  getAndSetChatPartnerData(){
    var users = widget.groupChatData["users"];
    if(users is String ) users = json.decode(users);

    users.forEach((key, value){
      if(key != userId){
        chatPartnerID = key;
        chatPartnerName = value["name"];
      }
    });
  }

  writeActiveChat(){
    ProfilDatabase().updateProfil(userId, "activeChat", chatID);
  }

  resetNewMessageCounter() async {
    var users = widget.groupChatData["users"];
    if(users is String ) users = json.decode(users);

    var usersChatNewMessages = users[userId]["newMessages"];

    if(usersChatNewMessages == 0) return;


    var usersAllNewMessages = await ProfilDatabase().getOneData("newMessages","id",userId);
    usersAllNewMessages = int.parse(usersAllNewMessages["newMessages"]);

    ProfilDatabase().updateProfil(
        userId, "newMessages", usersAllNewMessages - usersChatNewMessages < 0? 0:
        usersAllNewMessages - usersChatNewMessages
    );
    widget.groupChatData["users"] = json.decode(widget.groupChatData["users"]);
    widget.groupChatData["users"][userId]["newMessages"] = 0;


    ChatDatabase().updateChatGroup(
        widget.groupChatData["id"], "users",
        widget.groupChatData["users"]
    );



  }

  messageToDbAndClearMessageInput(message)async {
    var userID = FirebaseAuth.instance.currentUser.uid;

    if(nachrichtController.text == "") return;

    nachrichtController.clear();

    var messageData = {
      "message" :message,
      "von": userID,
      "date": Timestamp.now().seconds,
      "zu": chatPartnerID
    };
    if(widget.newChat){
      widget.groupChatData = await ChatDatabase()
          .addNewChatGroup({userID: userName, chatPartnerID: chatPartnerName}, messageData);

      setState(() {
        chatID = global_functions.getChatID([userID, chatPartnerID]);
      });
    } else {

      await ChatDatabase().addNewMessage(widget.groupChatData, messageData);
      ChatDatabase().updateChatGroup(widget.groupChatData["id"], "lastMessage", messageData["message"]);
      ChatDatabase().updateChatGroup(widget.groupChatData["id"], "lastMessageDate", messageData["date"]);

      setState(() {

      });
    }

  }

  countItemsInList(list, search){
    var count = 0;

    for(var i =0; i<list.length-search.length ;i++){
      if((list[i] + list[i+1] + list[i+1] ).contains(search) ){
        count += 1;
        i += 1;
      }
    }

    return count;
  }

  openProfil() async{
    var chatPartnerProfil = await ProfilDatabase().getProfil("id", chatPartnerID);
    var userFriendlistData = await ProfilDatabase().getOneData("friendlist","id",userId);
    var userFriendlist = json.decode(userFriendlistData["friendlist"]);

    global_functions.changePage(context, ShowProfilPage(
      userName: userName,
      profil: chatPartnerProfil,
      userFriendlist: userFriendlist,
    ));

  }


  @override
  Widget build(BuildContext context) {
    messageList(messages){
      List<Widget> messageBox = [];

      for(var message in messages){
        if(message["message"] == ""){continue;}

        var textAlign = Alignment.centerLeft;
        var boxColor = Colors.white;

        if(message["von"] == userId){
          textAlign = Alignment.centerRight;
          boxColor = Colors.greenAccent;
        }


        messageBox.add(
          Align(
            alignment: textAlign, //right and left
            child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: boxColor,
                  border: Border.all(),
                  borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  alignment: WrapAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top:5, left: 10, bottom: 7, right: 10),
                      child: Text(message["message"] ?? "",
                          style: const TextStyle(fontSize: 16 )
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 5, right: 10),
                      child: Text(
                          global_functions.dbSecondsToTimeString(json.decode(message["date"])),
                          style: TextStyle(color: Colors.grey[600])
                      ),
                    )

                  ],
                )
              ),
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

    showMessages(){

      return FutureBuilder(
          future: ChatDatabase().getAllMessages(chatID),
          builder: (
              BuildContext context,
              AsyncSnapshot snap,
              ){
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

    textEingabe(){
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
            ]
        ),
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

                      if(countItemsInList(value, "\n") != messageRows){
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
                      messageInputHeight = 50;
                    });
                  },
                  icon: Icon(Icons.send, size: 30, color: Theme.of(context).colorScheme.secondary)
              ),
          ],
        ),

      );
    }

    return Scaffold(
      appBar: customAppBar(
        title: chatPartnerName,
        onTap: () => openProfil(),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(child:showMessages()),
          textEingabe(),

        ],
      )
    );
  }
}
