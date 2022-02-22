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
    var userFriendlist = await ProfilDatabase().getOneData(userId, "friendlist");

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

  Widget personenSuchBox(buildContext){
    var personenSucheController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: SearchAutocomplete(
        searchableItems: [],
        onConfirm: (){

        },
      )


      /*Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child:

              TextFormField(
                  controller: personenSucheController,
                  decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      border: const OutlineInputBorder(),
                      hintText: AppLocalizations.of(context)!.personSuchen,
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey)
                  )

              ),

            ),
            TextButton(
              child: const Icon(Icons.search),
              onPressed: () async {
                var chatPartner = personenSucheController.text;
                if(chatPartner != "" && chatPartner != userName && chatPartner != userEmail){
                  var chatPartnerId = await findUserGetId(personenSucheController.text);

                  if(chatPartnerId != null){
                    validCheckAndOpenChatgroup(chatPartnerID: chatPartnerId);
                  } else {
                    personenSucheController.clear();
                    customSnackbar(buildContext, AppLocalizations.of(context)!.benutzerNichtGefunden);
                  }
                } else{
                  personenSucheController.text = "";
                }
              },
            )


          ]),

               */
    );
  }

  List<Widget> createFriendlistBox(userFriendlist){
    List<Widget> friendsBoxen = [];
    if(userFriendlist["empty"] == true) {
      userFriendlist= [];
    } else{
      userFriendlist = userFriendlist.keys;
    }

    for(var friend in userFriendlist){

      friendsBoxen.add(
          GestureDetector(
            onTap: () => validCheckAndOpenChatgroup(name: friend),
            child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(width: 1, color: global_var.borderColorGrey))
                ),
                child: Text(friend)
            ),
          )
      );
    }

    return friendsBoxen;
  }


  findUserGetId(user) async {
    var foundOnName = await ProfilDatabase().getProfilId("name", user);
    var foundOnEmail = await ProfilDatabase().getProfilId("email", user);

    if(foundOnName != null) return foundOnName;
    if(foundOnEmail != null) return foundOnEmail;

    return null;
  }

  validCheckAndOpenChatgroup({chatPartnerID, name}) async {
    if(name != null) chatPartnerID = await ProfilDatabase().getProfilId("name", name);
    var checkAndIndex = checkNewChatGroup(chatPartnerID);
    var chatPartnerName = await ProfilDatabase().getOneData(chatPartnerID, "name");

    var userData = {
      "users": {
        chatPartnerID: {"name": chatPartnerName, "newMessages": 0},
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
      if(globalChatGroups[i]["users"][chatPartnerId] != null){
        check = [false,i];
      }
    }

    return check;
  }

  checkNewMessageCounter() async{
    var dbNewMessages = await ProfilDatabase().getOneData(userId, "newMessages");
    num realNewMessages = 0;
    for(var group in globalChatGroups){
      realNewMessages += group["users"][userId]["newMessages"];
    }

    if(dbNewMessages != realNewMessages){
      ProfilDatabase().updateProfil(userId, {"newMessages": realNewMessages});
    }

  }


  @override
  Widget build(BuildContext context){

    chatUserList(groupdata) {
      List<Widget> groupContainer = [];

      for(var group in groupdata){
        var chatPartnerName;


        group["users"].forEach((key, value) async {
          if(key != userId){
            chatPartnerName = value["name"];
          }
        });

        var lastMessage = group["lastMessage"];
        if(lastMessage.length > 80) lastMessage = lastMessage.substring(0,80) +"...";
        var ownChatNewMessages = group["users"][userId]["newMessages"];
        var lastMessageTime = dbSecondsToTimeString(group["lastMessageDate"]);

        groupContainer.add(
          GestureDetector(
            onTap: () =>changePage(context, ChatDetailsPage(
              groupChatData: group,
            )),
            child: Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(width: 1, color: global_var.borderColorGrey),
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
                    children: [
                      Flexible(
                        flex: 3,
                        child: Text(lastMessage,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600])
                        )
                      ),
                      const Expanded(child: SizedBox.shrink()),
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
        child: ListView(
            shrinkWrap: true,
            children: groupContainer,
          ),
      );
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: kIsWeb? 0: 24),
        child:
            StreamBuilder(
              stream: ChatDatabase()
                  .getAllChatgroupsFromUserStream(userId, userName),
                builder: (
                    BuildContext context,
                    AsyncSnapshot snapshot,
                ){
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink(); //const CircularProgressIndicator();
                  } else if (snapshot.data.snapshot.value != null) {
                    var chatGroups = [];
                    var chatgroupsMap = Map<String, dynamic>.from(snapshot.data.snapshot.value);

                    chatgroupsMap.forEach((key, value) {
                      chatGroups.add(value);
                    });

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