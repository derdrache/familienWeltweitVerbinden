import 'package:http/http.dart' as http;
import 'dart:convert';

import '../auth/secrets.dart';
import '../services/database.dart';

addAdminMessage(title, message, user) {
  var url = Uri.parse(databaseUrl + databasePathNewAdminMessage);
  http.post(url, body: json.encode({"message": message, "user": user}));

  var userName = getProfilFromHive(profilId: user, getNameOnly: true);

  url = Uri.parse("${databaseUrl}services/sendEmail.php");
  http.post(url,
      body: json.encode({
        "to": adminEmail,
        "title": title,
        "inhalt": message + "\n\n von: $userName"
      }));
}