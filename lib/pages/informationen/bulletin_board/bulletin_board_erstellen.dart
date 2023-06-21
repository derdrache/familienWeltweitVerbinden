import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

import '../../../global/custom_widgets.dart';
import '../../../widgets/google_autocomplete.dart';

class BulletonBoardCreate extends StatefulWidget {
  const BulletonBoardCreate({Key? key});

  @override
  State<BulletonBoardCreate> createState() => _BulletonBoardCreateState();
}

class _BulletonBoardCreateState extends State<BulletonBoardCreate> {
  bool isCreating = true;
  TextEditingController titleKontroller = TextEditingController();
  TextEditingController descriptionKontroller = TextEditingController();
  var ortAuswahlBox = GoogleAutoComplete(margin:const EdgeInsets.only(top: 5, bottom:5, left:30, right:30));
  TextEditingController costsKontroller = TextEditingController();
  var currencyDropdown = CustomDropDownButton(margin:const EdgeInsets.only(top: 5, bottom:5, left:0, right:10), selected: "€",items: ["€", "\$"], width: 50,);
  List images = [];

  saveNote(){

  }

  uploadImage(){
    print("upload");
  }

  @override
  Widget build(BuildContext context) {
    ortAuswahlBox.hintText = "Ort Eingeben";

    setTitle() {
      return Center(
          child: Container(
              margin: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
              child: customTextInput("Titel einfügen", titleKontroller, maxLength: 45)));
    }

    setLocation() {
      return ortAuswahlBox;
    }

    setCosts() {
      return Container(
        margin: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
        child: Row(
          children: [
            Expanded(child: customTextInput("Preis einfügen", costsKontroller, onlyNumbers: true)),
            currencyDropdown
          ],
        ),
      );
    }

    setDescription() {
      return Center(
          child: Container(
              width: 700,
              margin: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
              child: customTextInput("Beschreibung einfügen", descriptionKontroller, moreLines: 10, maxLength: 650)));
    }

    setImages() {
      List noteImages = [1, 2, 3, 4];

      return Container(
        margin: const EdgeInsets.all(5),
        child: Wrap(
          children: noteImages
              .map<Widget>((image) => InkWell(
                onTap: () => uploadImage(),
                child: Container(
                      margin: const EdgeInsets.all(5),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          border: Border.all(), color: Colors.white),
                      child: Center(child: Icon(Icons.upload)),
                    ),
              ))
              .toList(),
        ),
      );
    }

    showTitle() {
      return Container(
          margin:
              const EdgeInsets.only(top: 10, bottom: 10, right: 20, left: 20),
          child: Text(
            "Titel einfügen",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ));
    }

    showBasicInformation(title, body) {
      return Container(
        margin: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
        child: Row(
          children: [
            Text("$title: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body)
          ],
        ),
      );
    }

    showDescription() {
      return Container(
          margin:
              const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 10),
          child: Text("Beschreibung einfügen"));
    }

    showImages() {
      List noteImages = ["test", "test", "test", "test"];

      return Container(
        margin: const EdgeInsets.all(5),
        child: Wrap(
          children: noteImages
              .map<Widget>((image) => Container(
                    margin: const EdgeInsets.all(5),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        border: Border.all(), color: Colors.white),
                    child: Center(child: Icon(Icons.upload)),
                  ))
              .toList(),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: "Notiz erstellen",
        buttons: [
          IconButton(onPressed: () => saveNote(), icon: Icon(Icons.done, size: 30))
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.yellow[200],
            border: Border.all(),
            borderRadius: BorderRadius.circular(4)),
        child: Column(
          children: isCreating
              ? [
                  setTitle(),
                  setLocation(),
                  setCosts(),
                  setDescription(),
                  const Expanded(child: SizedBox.shrink()),
                  setImages()
                ]
              : [
                  showTitle(),
                  showBasicInformation("Ort: ", "Ort auswählen"),
                  showBasicInformation("Kosten: ", "Kostenart auswählen"),
                  showDescription(),
                  const Expanded(child: SizedBox.shrink()),
                  showImages()
                ],
        ),
      ),
    );
  }
}
