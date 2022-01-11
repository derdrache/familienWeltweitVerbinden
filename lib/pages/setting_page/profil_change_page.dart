import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../custom_widgets.dart';
import '../../global_functions.dart' as globalFunctions;
import '../../database.dart';
import '../start_page.dart';
import 'locationsService.dart';


class ProfilChangePage extends StatefulWidget {
  var newProfil;

  ProfilChangePage({this.newProfil});

  State<ProfilChangePage> createState() => _ProfilChangePageState();
}

class _ProfilChangePageState extends State<ProfilChangePage>{
  int dropdownValue = 5;
  int childrenCount = 1;
  final nameController = TextEditingController();
  final ortController = TextEditingController();
  List ageDatePickerList = [];
  var searchMultiForm = CustomMultiTextForm(auswahlList: []);
  var childrenAgeList = [];

  void initState (){
    super.initState();

    ageDatePickerList.add(
        CustomDatePicker(
          hintText: "Geburtstag vom Kind eingeben",
          deleteFunction: ageDatePickerDeleteFunction(0),
        )
    );

    if (!widget.newProfil){
      getDataFromDB();
    }

  }

  void getDataFromDB() async {
    try{
      var userProfil = await getProfilFromDatabase();

      setState(() {
        nameController.text = userProfil["name"];
        ortController.text = userProfil["ort"];
        searchMultiForm = CustomMultiTextForm(auswahlList: userProfil["interessen"]);
        childrenAgeList = userProfil["kinder"];
        childrenCount = childrenAgeList.length;
        ageDatePickerList = [];

        for(var i = 0; i < childrenCount; i++){
          ageDatePickerList.add(CustomDatePicker(
            hintText: globalFunctions.timeStampToDateTimeDict(childrenAgeList[i])["string"],
            pickedDate: globalFunctions.timeStampToDateTimeDict(childrenAgeList[i])["date"],
            deleteFunction: ageDatePickerDeleteFunction(i),
          ));
        }
      });
    } catch (error){
      print("Problem mit dem User finden");
    }

  }

  Widget nameContainer(title){
    return Container(
        margin: EdgeInsets.only(top: 15, bottom: 15),
        child:Center(
            child:Text(
                title,
                style: TextStyle(fontSize: 21)
            )
        )
    );
  }

  Widget addChildrenButton(){
    return Container(
      margin: EdgeInsets.only(right: 20, bottom: 10),
      child: FloatingActionButton(
        heroTag: 1,
        mini: true,
        child: Icon(Icons.add),
        onPressed: (){
          setState((){
            childrenCount += 1;
            ageDatePickerList.add(CustomDatePicker(hintText: "Geburtstag vom Kind eingeben"));
          });
        },
      ),
    );
  }

  void transferDataToDatabase(data) async {
    if(widget.newProfil == false){
      var docID = await dbGetProfilDocumentID("dominik.mast.11@gmail.com");
      dbChangeProfil(docID, data);

    } else {
      FirebaseAuth.instance.currentUser!.updateDisplayName(nameController.text);
      dbAddNewProfil(data);
    }
  }

  getChildrenAgeData(){
    List brithDataList = [];

    ageDatePickerList.forEach((datePicker) {
      brithDataList.add(datePicker.getPickedDate());
    });

    return brithDataList;
  }

  Widget saveButton(){

    saveButtonFunction() async{
      var locationData = await LocationService().getLocationMapDataGoogle(ortController.text);

      if(locationData != null){
        var data = {
          "email": FirebaseAuth.instance.currentUser!.email,
          "name": nameController.text,
          "ort": locationData["city"],
          "interessen": searchMultiForm.auswahlList,
          "kinder": getChildrenAgeData(),
          "land": locationData["countryname"],
          "longt": locationData["longt"],
          "latt":  locationData["latt"]
        };

        transferDataToDatabase(data);
        globalFunctions.changePage(context, StartPage());
      }else{
        customSnackbar(context, "Stadt nicht gefunden");
      }
    }

    return FloatingActionButton.extended(
      heroTag: "speichern",
      label: Text("speichern"),
      icon: Icon(Icons.save),
      onPressed: () => saveButtonFunction(),
    );
  }

  getProfilFromDatabase() async {
    var userEmail = FirebaseAuth.instance.currentUser!.email;
    var docID = await dbGetProfilDocumentID(userEmail);
    var profil = await dbGetProfil(docID);

    return profil;
  }

  List<Widget> createProfilChangeWidgets(){
    List<Widget> containerList = [
      nameContainer("Benutztername"),
      customTextfield("Benutzername eingeben", nameController),
      nameContainer("Aktuelle Stadt"),
      customTextfield("Stadt eingeben", ortController),
      nameContainer("Interessen"),
      searchMultiForm,
      nameContainer("Alter der Kinder"),
    ];

    for(var i = 0 ; i < childrenCount; i++ ) {
      containerList.add(ageDatePickerList[i]);
    }

    containerList.add(addChildrenButton());
    containerList.add(saveButton());

    return containerList;
  }

  ageDatePickerDeleteFunction(id){
    return (){
      setState(() {
        childrenCount -= 1;
        ageDatePickerList.removeAt(id);
      });
    };


  }


  Widget build(BuildContext context) {
    String pageName = widget.newProfil == false? "Profil bearbeiten" : "Profil Anlegen";
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: widget.newProfil == false ? CustomAppbar(pageName, StartPage(selectedIndex: 4)): null,
        body: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              width: screenWidth,
              child: ListView(
                  children: createProfilChangeWidgets()
              )
          )
    );
  }
}
