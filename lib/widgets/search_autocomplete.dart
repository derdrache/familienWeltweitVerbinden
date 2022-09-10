import 'package:flutter/material.dart';

class SearchAutocomplete extends StatelessWidget {
  List searchableItems = [];
  var filterList = [];
  Function onConfirm;
  String hintText;
  var selected = "";
  Function onRemove;

  SearchAutocomplete(
      {Key key,
      this.searchableItems,
      this.onConfirm,
      this.onRemove,
      this.hintText = ""}) : super(key: key);


  getSelected() {
    if (selected.isEmpty) return [];

    return [selected];
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all()
      ),
      child: Autocomplete(
        optionsBuilder: (TextEditingValue textEditingValue) {
          return textEditingValue.text.isNotEmpty ? searchableItems.where((item) => item.toLowerCase()
              .contains(textEditingValue.text.toLowerCase())) : [];
        },
        optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected onSelected,
            Iterable options
            ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              child: Container(
                width: MediaQuery.of(context).size.width - 21,
                height: 300,
                decoration: const BoxDecoration(
                  border: Border(
                      left: BorderSide(),
                      right: BorderSide(),
                    bottom: BorderSide()
                  )
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    return GestureDetector(
                      onTap: () {
                        onSelected(option);
                        selected = option;
                        onConfirm();
                      },
                      child: ListTile(
                        title: Text(option, style: const TextStyle(color: Colors.black)),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            decoration: InputDecoration(
                hintText: hintText,
              contentPadding: const EdgeInsets.all(10.0),
            ),
            focusNode: focusNode,
            onChanged: (value){
              if(value.isEmpty){
                selected = "";
                if(onRemove != null) onRemove();
              }
            },
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
          );
        },
      ),
    );
  }
}

