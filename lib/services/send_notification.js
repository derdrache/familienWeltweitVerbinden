var admin = require("firebase-admin");

var firebaseAdminKey = require("C:/Users/Multimedia/AndroidStudioProjects/familien_suche/lib/auth/firebaseAdminKey.json");
C:
admin.initializeApp({
  credential: admin.credential.cert(firebaseAdminKey),
  //databaseURL: "https://praxis-cab-236720-default-rtdb.europe-west1.firebasedatabase.app"
});


var registrationToken = "cA37JCNbQVihquxsoGcU07:APA91bFD88U9HugMRc8GJlvX5mug5PUcwMWDr13N3MFPagMF_xiKTIwpTceAjKm5A6YpyDIFs8NFu_7-lpB0SykNXVPFi2q7QekeEInoEf4Qdipizm1z14UvGxgVL4-wNjRF7xv1yFGx";

var message = {
    notification: {
        title: "Dekar",
        body: "Hi wie geht es"
    },
    token: registrationToken
};


admin.messaging().send(message)
    .then((response) => {
        console.log("Erfolgreich Nachricht gesendet: ", response);
    })
    .catch((error) => {
        console.log("Fehler beim Nachricht senden: ", error);
    });