import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/database.dart';
import '../../global/custom_widgets.dart';
import '../../global/global_functions.dart';
import '../../global/search_autocomplete.dart';
import '../../global/variablen.dart' as global_var;
import 'chat_details.dart';

class ChatPage extends StatefulWidget{
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  var userId = FirebaseAuth.instance.currentUser.uid;
  var userName = FirebaseAuth.instance.currentUser.displayName;
  var userEmail = FirebaseAuth.instance.currentUser.email;
  var globalChatGroups = [];
  var testWindow;


  selectChatpartnerWindow() async {
    dynamic userFriendlist = await ProfilDatabase().getOneData("friendlist", "id", userId);

    userFriendlist = userFriendlist["friendlist"];
    if(userFriendlist is String) userFriendlist = jsonDecode(userFriendlist);

    userFriendlist??= [];

    return showDialog(
        context: context,
        builder: (BuildContext buildContext){
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Scaffold(
              body: Container(
                    height: double.maxFinite,
                    width: double.maxFinite,
                    child: Stack(
                      overflow: Overflow.visible,
                      children: [
                        ListView(
                          children: [
                            WindowTopbar(title: AppLocalizations.of(context).neuenChatEroeffnen),
                            const SizedBox(height: 10),
                            personenSuchBox(buildContext),
                            const SizedBox(height: 10),
                            ...createFriendlistBox(userFriendlist)
                          ]
                        ),
                        Positioned(
                          height: 30,
                          right: -13,
                          top: -7,
                          child: InkResponse(
                              onTap: () => Navigator.pop(context),
                              child: const CircleAvatar(
                                child: Icon(Icons.close, size: 16,),
                                backgroundColor: Colors.red,
                              )
                          ),
                        ),
                      ] ,
                    ),
                  ),
            ),

          );
        }
    );
  }

  searchUser(eingabe, buildContext) async {
    var chatPartner = eingabe;
    if(chatPartner != "" && chatPartner != userName && chatPartner != userEmail){
      var chatPartnerId = await findUserGetId(eingabe);
      chatPartnerId = chatPartnerId["id"];

      if(chatPartnerId != null){
        validCheckAndOpenChatgroup(chatPartnerID: chatPartnerId);
      } else {
        customSnackbar(buildContext, AppLocalizations.of(context).benutzerNichtGefunden);
      }
    }
  }

  Widget personenSuchBox(buildContext){
    var personenSucheController = TextEditingController();

    return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 50,
              width: 200,
              child: TextField(
                  controller: personenSucheController,
                  decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      border: const OutlineInputBorder(),
                      hintText: AppLocalizations.of(context).personSuchen,
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                  onSubmitted: (eingabe){
                    searchUser(eingabe, buildContext);
                  },
              ),

            ),
            TextButton(
              child: const Icon(Icons.search),
              onPressed: () async {
                var chatPartner = personenSucheController.text;
                searchUser(chatPartner, buildContext);
                personenSucheController.text = "";
              },
            )


          ]);
  }

  List<Widget> createFriendlistBox(userFriendlist){
    List<Widget> friendsBoxen = [];

    for(var friend in userFriendlist){

      friendsBoxen.add(
          GestureDetector(
            onTap: () => validCheckAndOpenChatgroup(name: friend),
            child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(width: 1, color: global_var.borderColorGrey))
                ),
                child: Text(friend)
            ),
          )
      );
    }

    return friendsBoxen;
  }


  findUserGetId(user) async {
    var foundOnName = await ProfilDatabase().getOneData("id", "name", user);
    var foundOnEmail = await ProfilDatabase().getOneData("id", "email", user);

    if(foundOnName != null) return foundOnName;
    if(foundOnEmail != null) return foundOnEmail;

    return null;
  }

  validCheckAndOpenChatgroup({chatPartnerID, name}) async {
    if(name != null){
      chatPartnerID = await ProfilDatabase().getOneData("id", "name", name);
      chatPartnerID = chatPartnerID["id"];
    }
    var checkAndIndex = checkNewChatGroup(chatPartnerID);
    var chatPartnerName = await ProfilDatabase().getOneData("name", "id", chatPartnerID);
    var userData = {
      "users": {
        chatPartnerID: {"name": chatPartnerName["name"], "newMessages": 0},
        userId: {"name": userName, "newMessages": 0},
      }
    };

    Navigator.pop(context);

    if(checkAndIndex[0]){
      changePage(context, ChatDetailsPage(
          groupChatData: userData,
          newChat: true
      ));
    } else{
      changePage(context, ChatDetailsPage(
        groupChatData: globalChatGroups[checkAndIndex[1]],
      ));
    }

  }

  checkNewChatGroup(chatPartnerId){
    var check = [true, -1];

    for(var i = 0;i < globalChatGroups.length; i++){
      var users = json.decode(globalChatGroups[i]["users"]);
      if(users[chatPartnerId] != null){
        check = [false,i];
      }
    }

    return check;
  }

  checkNewMessageCounter() async{
    var dbNewMessages = await ProfilDatabase().getOneData("newMessages", "id", userId);
    num realNewMessages = 0;

    for(var group in globalChatGroups){
      var users = json.decode(group["users"]);
      realNewMessages += users[userId]["newMessages"];
    }

    if(dbNewMessages != realNewMessages){
      ProfilDatabase().updateProfil(userId, "newMessages", realNewMessages);
    }

  }


  @override
  Widget build(BuildContext context){

    chatUserList(groupdata) {
      List<Widget> groupContainer = [];

      for(dynamic group in groupdata){
        var chatPartnerName;
        var users = json.decode(group["users"]);

        users.forEach((key, value) async {
          if(key != userId){
            chatPartnerName = value["name"];
          }
        });

        var lastMessage = group["lastMessage"];
        if(lastMessage.length > 80) lastMessage = lastMessage.substring(0,80) +"...";

        var ownChatNewMessages = users[userId]["newMessages"];
        var lastMessageTime = dbSecondsToTimeString(json.decode(group["lastMessageDate"]));

        groupContainer.add(
          GestureDetector(
            onTap: () =>Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatDetailsPage(
                  groupChatData: group,
                ))
            ).then((value) => setState((){})),
            child: Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: global_var.borderColorGrey),
                    )
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(chatPartnerName,style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Expanded(child: SizedBox.shrink()),
                      Text(lastMessageTime, style: TextStyle(color: Colors.grey[600]))
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Text(lastMessage,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600])
                        )
                      ),
                      ownChatNewMessages== 0? const SizedBox.shrink(): Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                              color:Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle
                          ),
                          child: Center(
                            child: FittedBox(
                              child: Text(
                                ownChatNewMessages.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          )
                      )
                    ],
                  )

                ],
              )
            ),
          )
        );
      }

      return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          }),
          child: ListView(
              shrinkWrap: true,
              children: groupContainer,
            ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
        child:
            FutureBuilder(
              future: ChatDatabase().getAllChatgroupsFromUser(userId),
                builder: (
                    BuildContext context,
                    AsyncSnapshot snapshot,
                ){
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink(); //const CircularProgressIndicator();
                  } else if (snapshot.data != null) {
                    var chatGroups = snapshot.data;

                    checkNewMessageCounter();

                    globalChatGroups = chatGroups;
                    return chatUserList(chatGroups);
                  }
                  return Container();
                }
            )
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "newChat",
        child: const Icon(Icons.create),
        onPressed: () => selectChatpartnerWindow(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}