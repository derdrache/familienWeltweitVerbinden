import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthPickerBox extends StatefulWidget {
  String hintText;
  DateTime selectedDate;

  MonthPickerBox({Key key, this.hintText}) : super(key: key);

  getDate() {
    return selectedDate;
  }

  deleteInput() {
    selectedDate = null;
  }

  @override
  State<MonthPickerBox> createState() => _MonthPickerBoxState();
}

class _MonthPickerBoxState extends State<MonthPickerBox> {
  createText() {
    if (widget.selectedDate == null) return widget.hintText;

    return widget.selectedDate.month.toString() +
        "." +
        widget.selectedDate.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        widget.selectedDate = await showMonthPicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(DateTime.now().year + 5, DateTime.now().month));

        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        width: 80,
        height: 50,
        decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: const BorderRadius.all(Radius.circular(5.0))),
        child: Center(
            child: Text(
          createText(),
          style: TextStyle(
              color: widget.selectedDate == null ? Colors.grey : Colors.black),
        )),
      ),
    );
  }
}

Future<DateTime> showMonthPicker({
  @required BuildContext context,
  @required DateTime initialDate,
  DateTime firstDate,
  DateTime lastDate,
}) async {
  assert(context != null);
  assert(initialDate != null);
  return await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
          ));
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate, firstDate, lastDate;

  const _MonthPickerDialog({
    Key key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  _MonthPickerDialogState createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  PageController pageController;
  DateTime selectedDate;
  int displayedPage;
  bool isYearSelection = false;

  DateTime _firstDate;
  DateTime _lastDate;

  @override
  void initState() {
    _firstDate = widget.firstDate;
    _lastDate = widget.lastDate;

    super.initState();
    selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    if (widget.firstDate != null) {
      _firstDate = DateTime(widget.firstDate.year, widget.firstDate.month);
    }
    if (widget.lastDate != null) {
      _lastDate = DateTime(widget.lastDate.year, widget.lastDate.month);
    }
    displayedPage = selectedDate.year;
    pageController = PageController(initialPage: displayedPage);
  }

  String _locale(BuildContext context) {
    var locale = Localizations.localeOf(context);
    if (locale == null) {
      return Intl.systemLocale;
    }

    return '${locale.languageCode}_${locale.countryCode}';
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var localizations = MaterialLocalizations.of(context);
    var locale = _locale(context);
    var header = buildHeader(theme, locale);
    var pager = buildPager(theme, locale);
    var content = Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [pager, buildButtonBar(context, localizations)],
      ),
      color: theme.dialogBackgroundColor,
    );
    return Theme(
        data: Theme.of(context)
            .copyWith(dialogBackgroundColor: Colors.transparent),
        child: Dialog(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Builder(builder: (context) {
            if (MediaQuery.of(context).orientation == Orientation.portrait) {
              return IntrinsicWidth(
                child: Column(children: [header, content]),
              );
            }
            return IntrinsicHeight(
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header, content]),
            );
          })
        ])));
  }

  Widget buildButtonBar(
    BuildContext context,
    MaterialLocalizations localizations,
  ) {
    return ButtonTheme(
        child: ButtonBar(children: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context, null),
        child: Text(localizations.cancelButtonLabel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, selectedDate),
        child: Text(localizations.okButtonLabel),
      )
    ]));
  }

  Widget buildHeader(ThemeData theme, String locale) {
    return Material(
        color: theme.colorScheme.primary,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    DateFormat.yMMM(locale).format(selectedDate),
                    style: theme.primaryTextTheme.subtitle1,
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        if (!isYearSelection)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isYearSelection = true;
                              });
                              //pageController.jumpToPage(displayedPage ~/ 12);
                            },
                            child: Text(
                              DateFormat.y(locale).format(DateTime(displayedPage)),
                              style: theme.primaryTextTheme.headline2,
                            ),
                          ),
                        if (isYearSelection)
                          Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  DateFormat.y(locale).format(DateTime(displayedPage)),
                                  style: theme.primaryTextTheme.headline4,
                                ),
                                Text(
                                  '-',
                                  style: theme.primaryTextTheme.headline3,
                                ),
                                Text(
                                  DateFormat.y(locale).format(DateTime(displayedPage + 11)),
                                  style: theme.primaryTextTheme.headline4,
                                )
                              ]),
                        Row(children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_up,
                              color: theme.primaryIconTheme.color,
                            ),
                            onPressed: () => pageController.animateToPage(
                                isYearSelection
                                    ? displayedPage + 11
                                    : displayedPage + 1,
                                duration: const Duration(milliseconds: 10),
                                curve: Curves.easeInOut),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: theme.primaryIconTheme.color,
                            ),
                            onPressed: () => pageController.animateToPage(
                                isYearSelection
                                    ? displayedPage - 11
                                    : displayedPage - 1,
                                duration: const Duration(milliseconds: 10),
                                curve: Curves.easeInOut),
                          )
                        ])
                      ])
                ])));
  }

  Widget buildPager(ThemeData theme, String locale) {
    return SizedBox(
        height: 220.0,
        width: 300.0,
        child: Theme(
            data: theme.copyWith(
              buttonTheme: const ButtonThemeData(
                padding: EdgeInsets.all(2.0),
                shape: CircleBorder(),
                minWidth: 4.0,
              ),
            ),
            child: PageView.builder(
                controller: pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  setState(() {
                    displayedPage = index;
                  });
                },
                itemBuilder: (context, page) {
                  return GridView.count(
                    padding: const EdgeInsets.all(8.0),
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    children: isYearSelection
                        ? List<int>.generate(12, (i) => page + i)
                            .map(
                              (year) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: _getYearButton(year, theme, locale),
                              ),
                            )
                            .toList()
                        : List<int>.generate(12, (i) => i + 1)
                            .map((month) => DateTime(page, month))
                            .map(
                              (date) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: _getMonthButton(date, theme, locale),
                              ),
                            )
                            .toList(),
                  );
                })));
  }

  Widget _getMonthButton(
      final DateTime date, final ThemeData theme, final String locale) {
    VoidCallback callback;
    if (_firstDate == null && _lastDate == null) {
      callback =
          () => setState(() => selectedDate = DateTime(date.year, date.month));
    } else if (_firstDate != null &&
        _lastDate != null &&
        _firstDate.compareTo(date) <= 0 &&
        _lastDate.compareTo(date) >= 0) {
      callback =
          () => setState(() => selectedDate = DateTime(date.year, date.month));
    } else if (_firstDate != null &&
        _lastDate == null &&
        _firstDate.compareTo(date) <= 0) {
      callback =
          () => setState(() => selectedDate = DateTime(date.year, date.month));
    } else if (_firstDate == null &&
        _lastDate != null &&
        _lastDate.compareTo(date) >= 0) {
      callback =
          () => setState(() => selectedDate = DateTime(date.year, date.month));
    } else {
      callback = () => null;
    }
    return TextButton(
      onPressed: callback,
      style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
            Radius.circular(30),
          )),
          backgroundColor:
              date.month == selectedDate.month && date.year == selectedDate.year
                  ? theme.colorScheme.secondary
                  : null),
      child: Text(
        DateFormat.MMM(locale).format(date),
        style: TextStyle(
            color: date.month == selectedDate.month &&
                    date.year == selectedDate.year
                ? Colors.white
                : date.month == DateTime.now().month &&
                        date.year == DateTime.now().year
                    ? theme.colorScheme.secondary
                    : null),
      ),
    );
  }

  Widget _getYearButton(int year, ThemeData theme, String locale) {
    return TextButton(
      onPressed: () {
        pageController.jumpToPage(year);
        setState(() {
          isYearSelection = false;
        });
      },
      style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
            Radius.circular(30),
          )),
          backgroundColor:
              year == selectedDate.year ? theme.colorScheme.secondary : null),
      child: Text(
        DateFormat.y(locale).format(
          DateTime(year),
        ),
        style: TextStyle(
            color: year == selectedDate.year
                ? Colors.white
                : year == DateTime.now().year
                    ? Colors.red
                    : null),
      ),
    );
  }
}
