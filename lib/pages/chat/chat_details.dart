import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:familien_suche/global/global_functions.dart';
import 'package:familien_suche/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        {"newMessages": usersAllNewMessages - usersChatNewMessages}
    );

  }

  messageToDbAndClearMessageInput(message)async {
    var userID = FirebaseAuth.instance.currentUser!.uid;

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

    ChatDatabase().addNewMessage(
        widget.groupChatData,
        messageData
    );

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
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: boxColor,
                  border: Border.all(),
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  alignment: WrapAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.only(top:5, left: 10, bottom: 7, right: 10),
                      child: Text(message["message"] == null ? "": message["message"],
                          style: TextStyle(fontSize: 16 )
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: 5, right: 10),
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

      return ListView(
          shrinkWrap: true,
          children: messageBox,
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
              return SizedBox.shrink();
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
      return Container(
        padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),//EdgeInsets.all(10),
        height: 50,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                onSubmitted: (eingabe) async { messageToDbAndClearMessageInput(eingabe); },
                controller: nachrichtController,
                decoration: InputDecoration.collapsed(
                  hintText: "Nachricht"
                ),
              ),
            ),
            IconButton(
                padding: EdgeInsets.zero,
                  onPressed: () => print("test"),
                  icon: Icon(Icons.send, size: 30)
              ),
          ],
        ),

      );
    }



    return Scaffold(
      appBar: customAppBar(
        title: chatPartnerName,
        button: TextButton(
            onPressed: null,
            child: Container()
        )
      ),
      body: Container(
        child: ListView(
          reverse: true,
          children: [
            textEingabe(),
            showMessages(),
          ],
        ),
      )
    );
  }
}
