import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/database.dart';
import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart';
import 'chat_details.dart';

class ChatPage extends StatefulWidget{
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  var userEmail = FirebaseAuth.instance.currentUser!.email;
  var globalChatGroups = [];

  getAllDbDataAndSetChatGroups() async {
    var chatGroups = await dbGetAllUsersChats(userEmail);

    globalChatGroups = chatGroups;

    return chatGroups;
  }

  openThisChat(groupChatData){
    changePage(context, ChatDetailsPage(groupChatData: groupChatData));
  }

  checkUserExist(user) async {
    var check = false;
    var userProfil = await dbGetProfil(user);

    if(userProfil != null){
      check = true;
    }

    return check;
  }

  selectChatpartnerWindow() async {
    var personenSucheController = TextEditingController();
    var userProfil = await dbGetProfil(userEmail);
    var userFriendlist = userProfil["friendlist"];

    return showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            content: Container(
              height: 400,
              child: Column(
                children: [
                  Row(
                      children: [
                        Container(width: 200,child: customTextfield("Person suchen", personenSucheController)),
                        FloatingActionButton(
                          mini: true,
                          child: Icon(Icons.search),
                          onPressed: () async {
                            bool userExist = await checkUserExist(personenSucheController.text);

                            if(userExist){
                              validCheckAndOpenChatgroup(personenSucheController.text);
                            } else {
                              //suche input leer machen
                              customSnackbar(context, "Benutzer existiert nicht");
                            }

                          },
                        )
                      ]),
                  SizedBox(height: 15),
                  Align(alignment: Alignment.centerLeft, child: Text("Friendlist: ")),
                  SizedBox(height: 15),
                  createFriendlistBox(userFriendlist)
                ]
              )
            ),
          );
   });
  }

  Widget createFriendlistBox(userFriendlist) {
    List<Widget> friendsBoxen = [];

    for(var friend in userFriendlist){
      friendsBoxen.add(
        GestureDetector(
          onTap: () => validCheckAndOpenChatgroup(friend),
          child: Container(
            child: Text(friend)
          ),
        )
      );
    }

    return Container(
      width: double.maxFinite,
      height: 250,
      padding: EdgeInsets.all(10),
      child: ListView(
          children: friendsBoxen
      ),
    );

  }

  validCheckAndOpenChatgroup(chatPartner) async {
    var checkAndIndex = checkNewChatGroup(chatPartner);


    // prüfen ob user existiert

    Navigator.pop(context);

    if(checkAndIndex[0]){
      var chatGroupData = await dbAddNewChatGroup([userEmail, chatPartner]);
      openThisChat(chatGroupData);
    } else{
      openThisChat(globalChatGroups[checkAndIndex[1]]);
    }

  }

  checkNewChatGroup(chatPartner){
    var check = [true, -1];

    for(var i = 0;i < globalChatGroups.length; i++){

      if(globalChatGroups[i]["users"].contains(chatPartner)){
        check = [false,i];
      }
    }

    return check;
  }


  Widget build(BuildContext context){

    chatUserList(groupdata){
      List<Widget> groupContainer = [];

      for(var group in groupdata){
        var chatpartner = group["users"][0] == "dominik.mast.11@gmail.com" ?
                          group["users"][1] : group["users"][0];
        var lastMessage = group["lastMessage"];

        groupContainer.add(
          GestureDetector(
            onTap: () => openThisChat(group),
            child: Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(),
                    )
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chatpartner,style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(lastMessage)
                ],
              )
            ),
          )
        );
      }

      return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(
          shrinkWrap: true,
          children: groupContainer,
        ),
      );
    }



    return Scaffold(
      appBar: customAppBar(
        title: "Chat",
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: getAllDbDataAndSetChatGroups(),
              builder: (
                  BuildContext context,
                  AsyncSnapshot snapshot,
              ){
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.connectionState == ConnectionState.done) {
                  return chatUserList(snapshot.data);
                }
                return Container();
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}