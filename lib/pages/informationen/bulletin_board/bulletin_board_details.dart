import 'package:familien_suche/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

class BulletinBoardDetails extends StatelessWidget {
  const BulletinBoardDetails({Key? key});

  @override
  Widget build(BuildContext context) {
    showTitle() {
      return Container(
          margin: const EdgeInsets.all(10),
          child: Text(
            "B"*50,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ));
    }

    showBasicInformation(title, body) {
      return Container(
        margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
        child: Row(
          children: [
            Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body)
          ],
        ),
      );
    }

    showDescription() {
      return Container(
          margin: const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 10),
          child: Text("H" * 700));
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
                      color: Colors.red,
                      border: Border.all()
                    ),
                  ))
              .toList(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "test",
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
          children: [
            showTitle(),
            showBasicInformation("Ort", "Weltweit"),
            showBasicInformation("Kosten", "kostenlos"),
            showDescription(),
            const Expanded(child: SizedBox.shrink()),
            showImages()
          ],
        ),
      ),
    );
  }
}
