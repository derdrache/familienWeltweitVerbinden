class LanguageLocal {

  final isoLangs = {
    "en" : {"nameGer" : "Englisch", "nameEng": "englisch"},
    "de" : {"nameGer" : "Deutsch", "nameEng": "german"},
    "es" : {"nameGer" : "Spanisch", "nameEng": "spanish"},
    "zh" : {"nameGer" : "Chinesisch", "nameEng": "chinese"},
    "fr" : {"nameGer" : "Französisch", "nameEng": "french"},
    "ar" : {"nameGer" : "Arabisch", "nameEng": "arabic"},
    "ru" : {"nameGer" : "Russisch", "nameEng": "russian"},
    "it" : {"nameGer" : "Italienisch", "nameEng": "italian"},
    "pt" : {"nameGer" : "Portugiesisch", "nameEng": "portuguese"},
    "ja" : {"nameGer" : "Japanisch", "nameEng": "japanese"},
    "tr" : {"nameGer" : "Türkisch", "nameEng": "turkish"},
    "pl" : {"nameGer" : "Polnisch", "nameEng": "polish"},
    "nl" : {"nameGer" : "Niederländisch", "nameEng": "dutch"},

  };

  getDisplayLanguage(language) {
    String languageCode = "";

    isoLangs.forEach((key, value) {
      if(value["nameGer"] == language || value["nameEng"] == language){
        languageCode = key;
      }
    });

    return languageCode;
  }
}