import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


Future<DateTime> showYearPicker({
  BuildContext context,
  DateTime initialDate,
  DateTime firstDate,
  DateTime lastDate,
}) async {
  assert(context != null);
  assert(initialDate != null);
  return await showDialog<DateTime>(
      context: context,
      builder: (context) => _YearPickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      )
  );
}

class _YearPickerDialog extends StatefulWidget {
  final DateTime initialDate, firstDate, lastDate;

  const _YearPickerDialog({
    Key key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  _YearPickerDialogState createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  PageController pageController;
  DateTime selectedDate;
  int displayedPage;
  bool isYearSelection = false;

  var _firstDate;
  var _lastDate;

  @override
  void initState() {
    _firstDate = DateTime(widget.firstDate.year, 1);
    _lastDate = DateTime(widget.lastDate.year, 1);

    super.initState();
    selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    if (widget.firstDate != null)
      _firstDate = DateTime(widget.firstDate.year, widget.firstDate.month);
    if (widget.lastDate != null)
      _lastDate = DateTime(widget.lastDate.year, widget.lastDate.month);
    displayedPage = selectedDate.year - 11;
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
          FlatButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(localizations.cancelButtonLabel),
          ),
          FlatButton(
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
                    //'${DateFormat.yMMM(locale).format(selectedDate)}',
                    '',
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
                              '${DateFormat.y(locale).format(selectedDate)}',
                              style: theme.primaryTextTheme.headline2,
                            ),
                          ),
                        if (isYearSelection)
                          Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${DateFormat.y(locale).format(DateTime(displayedPage))}',
                                  style: theme.primaryTextTheme.headline4,
                                ),
                                Text(
                                  '-',
                                  style: theme.primaryTextTheme.headline3,
                                ),
                                Text(
                                  '${DateFormat.y(locale).format(DateTime(displayedPage+11))}',
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
                                displayedPage -22,
                                duration: Duration(milliseconds: 10),
                                curve: Curves.easeInOut),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: theme.primaryIconTheme.color,
                            ),
                            onPressed: () => pageController.animateToPage(
                                displayedPage + 11,
                                duration: Duration(milliseconds: 10),
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
              buttonTheme: ButtonThemeData(
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
                    padding: EdgeInsets.all(8.0),
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    children: List<int>.generate(12, (i) => page + i)
                        .map(
                          (year) => Padding(
                        padding: EdgeInsets.all(4.0),
                        child: _getYearButton(year, theme, locale),
                      ),
                    ).toList()
                  );
                })));
  }

  Widget _getMonthButton(
      final DateTime date, final ThemeData theme, final String locale) {
    VoidCallback callback;
    if (_firstDate == null && _lastDate == null)
      callback =
          () => setState(() => selectedDate = DateTime(date.year, date.month));
    else if (_firstDate != null &&
        _lastDate != null &&
        _firstDate.compareTo(date) <= 0 &&
        _lastDate.compareTo(date) >= 0)
      callback =
          () => setState(() => selectedDate = DateTime(date.year, date.month));
    else if (_firstDate != null &&
        _lastDate == null &&
        _firstDate.compareTo(date) <= 0)
      callback =
          () => setState(() => selectedDate = DateTime(date.year, date.month));
    else if (_firstDate == null && _lastDate != null &&
        _lastDate.compareTo(date) >= 0)
      callback = () => setState(() =>
          selectedDate = DateTime(date.year, date.month));
    else
      callback = () => null;
    return FlatButton(
      onPressed: callback,
      color: date.month == selectedDate.month && date.year == selectedDate.year
          ? theme.colorScheme.secondary
          : null,
      textColor:
      date.month == selectedDate.month && date.year == selectedDate.year
          ? theme.accentTextTheme.button.color
          : date.month == DateTime.now().month &&
          date.year == DateTime.now().year
          ? theme.colorScheme.secondary
          : null,
      child: Text(
        DateFormat.MMM(locale).format(date),
      ),
    );
  }

  Widget _getYearButton(int year, ThemeData theme, String locale) {
    VoidCallback callback;
    var dateTimeYear = DateTime(year, 1);
    if (_firstDate == null && _lastDate == null)
      callback =
          () => setState(() => selectedDate = DateTime(year, 1));
    else if (_firstDate != null &&
        _lastDate != null &&
        _firstDate.compareTo(dateTimeYear) <= 0 &&
        _lastDate.compareTo(dateTimeYear) >= 0)
      callback =
          () => setState(() => selectedDate = DateTime(year, 1));
    else if (_firstDate != null &&
        _lastDate == null &&
        _firstDate.compareTo(dateTimeYear) <= 0)
      callback =
          () => setState(() => selectedDate = DateTime(year, 1));
    else if (_firstDate == null && _lastDate != null &&
        _lastDate.compareTo(dateTimeYear) >= 0)
      callback = () => setState(() =>
      selectedDate = DateTime(year, 1));
    else
      callback = () => null;


    return FlatButton(
      onPressed: callback,
      color: year == selectedDate.year ? theme.colorScheme.secondary : null,
      textColor: year == selectedDate.year
          ? theme.accentTextTheme.button.color
          : year == DateTime.now().year ? theme.accentColor : null,
      child: Text(
        DateFormat.y(locale).format(DateTime(year)),
      ),
    );
  }
}