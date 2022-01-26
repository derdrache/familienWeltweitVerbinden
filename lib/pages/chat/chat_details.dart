import 'package:familien_suche/services/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart';

class ChatDetailsPage extends StatefulWidget {
  var groupChatData;
  bool newChat;

  ChatDetailsPage({Key? key,required this.groupChatData, this.newChat = false}) : super(key: key);

  @override
  _ChatDetailsPageState createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  List<Widget> messagesList = [];
  var nachrichtController = TextEditingController();
  var userName = FirebaseAuth.instance.currentUser!.displayName;


  @override
  void initState() {
    if(widget.newChat){
      widget.groupChatData = {
        "users" : [userName, widget.groupChatData],
        "lastMessage": "",
        "lastMessageDate": DateTime.now(),
        "docid" : userName!+widget.groupChatData
      };
    }
    super.initState();
  }

  getTitle(){
    var users = widget.groupChatData["users"];

    return users[0] == userName? users[1]: users[0];

  }

  messageToDbAndClearMessageInput(message)async {
    nachrichtController.clear();

    var messageData = {
      "message" :message,
      "from": userName,
      "date": DateTime.now()
    };

    var groupChatData = await dbAddMessage(widget.groupChatData, messageData, newChat: widget.newChat);
    if (widget.newChat){
      Navigator.pop(context);
      changePage(context, ChatDetailsPage(groupChatData: groupChatData));
    }

  }

  getAllMessages() async {
    return dbGetMessagesFromChatgroup(widget.groupChatData);
  }



  @override
  Widget build(BuildContext context) {

    messageList(messages){
      List<Widget> messageBox = [];

      for(var message in messages){
        if(message["message"] == ""){continue;}

        var textAlign = Alignment.centerLeft;
        var boxColor = Colors.grey;

        if(widget.groupChatData["users"][message["from"]] == userName){
          textAlign = Alignment.centerRight;
          boxColor = Colors.blue;
        }


        messageBox.add(
          Align(
            alignment: textAlign, //right and left
            child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: boxColor,
                  border: Border.all(),
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                child: Text(message["message"])
              ),
            ),
        );
      }

      return Expanded(
        child: ListView(
          reverse: true,
          shrinkWrap: true,
          children: messageBox,
        ),
      );
    }

    showMessages(){
      return StreamBuilder(
          stream: chats.doc(widget.groupChatData["docid"])
              .collection("messages")
              .orderBy("date", descending: true).snapshots(),
          builder: (
              BuildContext context,
              AsyncSnapshot snapshot,
              ){
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasData) {
              return messageList(snapshot.data.docs);
            }
            return Container();
          });
    }

    textEingabe(){
      return Container(
        padding: EdgeInsets.all(15),
        height: 50,
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
        child: TextField(
          onSubmitted: (eingabe) async { messageToDbAndClearMessageInput(eingabe); },
          controller: nachrichtController,
          decoration: InputDecoration.collapsed(
            hintText: "Nachricht"
          ),
        ),

      );
    }



    return Scaffold(
      appBar: customAppBar(
        title: getTitle(),
        button: TextButton(
            onPressed: null,
            child: Icon(Icons.more_vert))
      ),
      body: Column(
        children: [
          showMessages(),
          textEingabe()
        ],
      )
    );
  }
}
