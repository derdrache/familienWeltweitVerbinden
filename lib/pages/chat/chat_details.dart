import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/pages/show_profil.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../global/custom_widgets.dart';

class ChatDetailsPage extends StatefulWidget {
  var groupChatData;
  bool newChat;

  ChatDetailsPage({Key? key,
    required this.groupChatData,
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
  var userId = FirebaseAuth.instance.currentUser!.uid;
  var userName = FirebaseAuth.instance.currentUser!.displayName;
  var messageInputHeight = 50.0;
  var messageRows = 0;

  @override
  void dispose() {
    ProfilDatabase().updateProfil(userId, {"activeChat": null});
    super.dispose();
  }
  @override
  void initState() {
    chatID = widget.groupChatData["id"]?? "0";

    getAndSetChatPartnerData();

    writeActiveChat();
    resetNewMessageCounter();

    super.initState();
  }

  getAndSetChatPartnerData(){

    widget.groupChatData["users"].forEach((key, value){
      if(key != userId){
        chatPartnerID = key;
        chatPartnerName = value["name"];
      }
    });
  }

  writeActiveChat(){
    ProfilDatabase().updateProfil(userId, {"activeChat": chatID});
  }

  resetNewMessageCounter() async {
    var usersChatNewMessages = widget.groupChatData["users"][userId]["newMessages"];

    if(usersChatNewMessages == 0) return;


    var usersAllNewMessages = await ProfilDatabase().getOneData(userId, "newMessages");


    ChatDatabase().updateNewMessageCounter(chatID, userId, 0);
    ProfilDatabase().updateProfil(
        userId,
        {"newMessages": usersAllNewMessages - usersChatNewMessages < 0? 0:
                        usersAllNewMessages - usersChatNewMessages}
    );

  }

  messageToDbAndClearMessageInput(message)async {
    var userID = FirebaseAuth.instance.currentUser!.uid;

    if(nachrichtController.text == "") return;
    nachrichtController.clear();

    var messageData = {
      "message" :message,
      "from": userID,
      "date": Timestamp.now().seconds,
      "to": chatPartnerID
    };
    if(widget.newChat){
      widget.groupChatData = await ChatDatabase()
          .addNewChatGroup({userID: userName, chatPartnerID: chatPartnerName}, messageData);

      setState(() {
        chatID = widget.groupChatData["id"];
      });
    } else {
      await ChatDatabase().updateChatGroup(
          widget.groupChatData["id"],
          {
            "lastMessage": messageData["message"],
            "lastMessageDate": messageData["date"],
          }
      );
    }

    ChatDatabase().addNewMessage(widget.groupChatData, messageData);

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
    var chatPartnerProfil = await ProfilDatabase().getProfil(chatPartnerID);
    var userFriendlist = await ProfilDatabase().getOneData(userId, "friendlist");

    changePage(context, ShowProfilPage(
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

        if(widget.groupChatData["users"][message["from"]]["name"] == userName){
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
                          dbSecondsToTimeString(message["date"]),
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
      },),
        child: ListView(
            reverse: true,
            children: messageBox.reversed.toList(),
        ),
      );
    }

    showMessages(){

      return StreamBuilder(
          stream: ChatDatabase().getAllMessagesStream(chatID),
          builder: (
              BuildContext context,
              AsyncSnapshot snap,
              ){
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            } else if (snap.data.snapshot.value != null) {
              List<Map> messages = [];

              var messagesMap = snap.data.snapshot.value;

              messagesMap.forEach((key, value) {
                messages.add(value);
              });

              messages.sort((a, b) => (a["date"]).compareTo(b["date"]));

              return messageList(messages);
            }
            return Container();
          });
    }

    textEingabe(){
      var myFocusNode = FocusNode();
      return Container(
        height: messageInputHeight,
        padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
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
              child: TextField(
                maxLines: null,
                focusNode: myFocusNode,
                textInputAction: TextInputAction.newline,
                controller: nachrichtController,
                decoration: InputDecoration.collapsed(
                  hintText: AppLocalizations.of(context)!.nachricht,
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
            IconButton(
                padding: EdgeInsets.zero,
                  onPressed: () => messageToDbAndClearMessageInput(nachrichtController.text),
                  icon: Icon(Icons.send, size: 30, color: Theme.of(context).colorScheme.tertiary)
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
