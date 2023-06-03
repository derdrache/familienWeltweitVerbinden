import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../global/custom_widgets.dart';

class NetworkConnectivity {
  final _networkConnectivity = Connectivity();
  final _controller = StreamController.broadcast();
  Stream get myStream => _controller.stream;
  bool _internetStatus = true;
  var context;

  NetworkConnectivity(this.context);

  void _initialise() async {
    ConnectivityResult result = await _networkConnectivity.checkConnectivity();
    _checkStatus(result);
    _networkConnectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }

  checkInternetStatusStream(){
    _initialise();

    myStream.listen((source) {
      var newInternetStatus = source.values.toList()[0];
      source;

      if(newInternetStatus == _internetStatus) return;

      var connectionText = newInternetStatus ? "Online" : "Offline";
      _internetStatus = newInternetStatus;

      if(connectionText.contains("Offline")){
        customSnackbar(context, AppLocalizations.of(context).keineVerbindungInternet,
            duration: const Duration(days: 365));
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        customSnackbar(context, "Online", color: Colors.green,
            duration: const Duration(seconds: 2));
      }
    });
  }

  void _checkStatus(ConnectivityResult result) async {
    bool isOnline = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      isOnline = false;
    }
    _controller.sink.add({result: isOnline});
  }

  void disposeStream() => _controller.close();
}