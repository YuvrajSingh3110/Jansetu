import 'package:jansetu/features/onboarding/domain/models/app_language.dart';

class HealthLanguageService {
  static const Map<String, Map<String, String>> _symptomLabels = {
    'en': {
      'fever': 'Fever',
      'cough': 'Cough',
      'breathlessness': 'Breathlessness',
      'diarrhoea': 'Diarrhoea',
      'vomiting': 'Vomiting',
      'rash': 'Rash',
      'headache': 'Headache',
      'bodyache': 'Body ache',
      'sore_throat': 'Sore throat',
      'runny_nose': 'Runny nose',
      'malnutrition': 'Malnutrition',
      'jaundice': 'Jaundice',
      'conjunctivitis': 'Conjunctivitis',
      'seizure': 'Seizure',
      'unconscious': 'Unconscious',
      'bleeding': 'Bleeding',
    },
    'hi': {
      'fever': 'बुखार',
      'cough': 'खांसी',
      'breathlessness': 'सांस फूलना',
      'diarrhoea': 'दस्त',
      'vomiting': 'उल्टी',
      'rash': 'चकत्ते',
      'headache': 'सिरदर्द',
      'bodyache': 'शरीर दर्द',
      'sore_throat': 'गले में दर्द',
      'runny_nose': 'नाक बहना',
      'malnutrition': 'कुपोषण',
      'jaundice': 'पीलिया',
      'conjunctivitis': 'आंख लाल होना',
      'seizure': 'दौरा',
      'unconscious': 'बेहोशी',
      'bleeding': 'खून बहना',
    },
    'bho': {
      'fever': 'बुखार',
      'cough': 'खांसी',
      'breathlessness': 'साँस फूलेल',
      'diarrhoea': 'दस्त',
      'vomiting': 'उल्टी',
      'rash': 'दाने',
      'headache': 'सिरदर्द',
      'bodyache': 'देह दर्द',
      'sore_throat': 'गला दर्द',
      'runny_nose': 'नाक बहे',
      'malnutrition': 'कुपोषण',
      'jaundice': 'पीलिया',
      'conjunctivitis': 'आंख लाल',
      'seizure': 'दौरा',
      'unconscious': 'बेहोशी',
      'bleeding': 'खून बहे',
    },
    'bn': {
      'fever': 'জ্বর',
      'cough': 'কাশি',
      'breathlessness': 'শ্বাসকষ্ট',
      'diarrhoea': 'ডায়রিয়া',
      'vomiting': 'বমি',
      'rash': 'ফুসকুড়ি',
      'headache': 'মাথাব্যথা',
      'bodyache': 'শরীর ব্যথা',
      'sore_throat': 'গলা ব্যথা',
      'runny_nose': 'নাক দিয়ে পানি পড়া',
      'malnutrition': 'অপুষ্টি',
      'jaundice': 'জন্ডিস',
      'conjunctivitis': 'চোখ লাল',
      'seizure': 'খিঁচুনি',
      'unconscious': 'অচেতন',
      'bleeding': 'রক্তপাত',
    },
    'pa': {
      'fever': 'ਬੁਖਾਰ',
      'cough': 'ਖੰਘ',
      'breathlessness': 'ਸਾਹ ਫੁੱਲਣਾ',
      'diarrhoea': 'ਦਸਤ',
      'vomiting': 'ਉਲਟੀ',
      'rash': 'ਦਾਣੇ',
      'headache': 'ਸਿਰ ਦਰਦ',
      'bodyache': 'ਸਰੀਰ ਦਰਦ',
      'sore_throat': 'ਗਲਾ ਦਰਦ',
      'runny_nose': 'ਨੱਕ ਵਗਣਾ',
      'malnutrition': 'ਕੁਪੋਸ਼ਣ',
      'jaundice': 'ਪੀਲੀਆ',
      'conjunctivitis': 'ਅੱਖ ਲਾਲ',
      'seizure': 'ਦੌਰਾ',
      'unconscious': 'ਬੇਹੋਸ਼ੀ',
      'bleeding': 'ਖੂਨ ਵਗਣਾ',
    },
    'or': {
      'fever': 'ଜ୍ୱର',
      'cough': 'କାଶ',
      'breathlessness': 'ଶ୍ୱାସକଷ୍ଟ',
      'diarrhoea': 'ଡାୟାରିଆ',
      'vomiting': 'ବାନ୍ତି',
      'rash': 'ଚର୍ମ ଦାଗ',
      'headache': 'ମୁଣ୍ଡ ବେଦନା',
      'bodyache': 'ଶରୀର ବେଦନା',
      'sore_throat': 'ଗଳା ବେଦନା',
      'runny_nose': 'ନାକୁ ପାଣି',
      'malnutrition': 'କୁପୋଷଣ',
      'jaundice': 'ପୀତଜ୍ୱର ଲକ୍ଷଣ',
      'conjunctivitis': 'ଆଖି ଲାଲ',
      'seizure': 'ଖିଚୁଣି',
      'unconscious': 'ଅଚେତନ',
      'bleeding': 'ରକ୍ତସ୍ରାବ',
    },
  };

  static const Map<String, String> _speakLabels = {
    'en': 'Hear suggestion',
    'hi': 'सलाह सुनें',
    'bho': 'सलाह सुनीं',
    'bn': 'পরামর্শ শুনুন',
    'pa': 'ਸਲਾਹ ਸੁਣੋ',
    'or': 'ପରାମର୍ଶ ଶୁଣନ୍ତୁ',
  };

  static const Map<String, String> _languageNamesForPrompt = {
    'en': 'English',
    'hi': 'Hindi',
    'bho': 'Bhojpuri',
    'bn': 'Bengali',
    'pa': 'Punjabi',
    'or': 'Odia',
  };

  static String languageNameForPrompt(AppLanguage? language) {
    final localeCode = language?.localeCode ?? 'en';
    return _languageNamesForPrompt[localeCode] ?? 'English';
  }

  static String localizedSymptom(String code, String localeCode) {
    final labels = _symptomLabels[localeCode] ?? _symptomLabels['en']!;
    return labels[code] ?? _symptomLabels['en']![code] ?? code;
  }

  static List<String> localizedSymptoms(List<String> codes, String localeCode) {
    return codes.map((code) => localizedSymptom(code, localeCode)).toList();
  }

  static String hearSuggestionLabel(String localeCode) {
    return _speakLabels[localeCode] ?? _speakLabels['en']!;
  }

  static bool prefersFallbackForLocale(String localeCode, String? text) {
    if (localeCode == 'en' || text == null) {
      return false;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    return RegExp("^[\\x00-\\x7F\\s.,;:!?()'\"-]+\$").hasMatch(trimmed);
  }

  static String promptLanguageInstruction(AppLanguage? language) {
    return switch (language?.localeCode ?? 'en') {
      'hi' => 'Hindi in Devanagari script',
      'bho' => 'Bhojpuri in Devanagari script',
      'bn' => 'Bengali in Bengali script',
      'pa' => 'Punjabi in Gurmukhi script',
      'or' => 'Odia in Odia script',
      _ => 'English',
    };
  }

  static String fallbackSummary(String localeCode, List<String> symptoms) {
    final symptomText = _localizedSymptomSentence(localeCode, symptoms);
    return switch (localeCode) {
      'hi' =>
        symptomText.isEmpty
            ? 'रिपोर्ट तैयार है। विवरण की समीक्षा करें।'
            : 'मुख्य लक्षण: $symptomText।',
      'bho' =>
        symptomText.isEmpty
            ? 'रिपोर्ट तैयार बा। विवरण देख लीं।'
            : 'मुख्य लच्छन: $symptomText।',
      'bn' =>
        symptomText.isEmpty
            ? 'রিপোর্ট প্রস্তুত। বিবরণ দেখে নিন।'
            : 'প্রধান উপসর্গ: $symptomText।',
      'pa' =>
        symptomText.isEmpty
            ? 'ਰਿਪੋਰਟ ਤਿਆਰ ਹੈ। ਵੇਰਵਾ ਵੇਖੋ।'
            : 'ਮੁੱਖ ਲੱਛਣ: $symptomText।',
      'or' =>
        symptomText.isEmpty
            ? 'ରିପୋର୍ଟ ପ୍ରସ୍ତୁତ। ବିବରଣୀ ଯାଞ୍ଚ କରନ୍ତୁ।'
            : 'ମୁଖ୍ୟ ଲକ୍ଷଣ: $symptomText।',
      _ =>
        symptomText.isEmpty
            ? 'Assessment is ready for review.'
            : 'Main symptoms noted: $symptomText.',
    };
  }

  static String fallbackSuggestion(
    String localeCode,
    List<String> symptoms, {
    bool urgent = false,
  }) {
    final hasBreathlessness = symptoms.contains('breathlessness');
    final hasFever = symptoms.contains('fever');
    final hasCough = symptoms.contains('cough');
    final hasDiarrhoea = symptoms.contains('diarrhoea');
    final needsReferral = urgent || hasBreathlessness;

    return switch (localeCode) {
      'hi' =>
        needsReferral
            ? 'सांस फूलने या गंभीर हालत हो तो मरीज को आज ही पीएचसी या अस्पताल भेजें।'
            : hasFever && hasCough
            ? 'आराम, पानी और निगरानी की सलाह दें। मरीज को भीड़ से दूर रखें और जरूरत हो तो पीएचसी भेजें।'
            : hasDiarrhoea
            ? 'ओआरएस, साफ पानी और निर्जलीकरण की निगरानी की सलाह दें। जरूरत हो तो पीएचसी भेजें।'
            : 'लक्षणों की निगरानी करें, आराम की सलाह दें और हालत बिगड़े तो पीएचसी रेफरल करें।',
      'bho' =>
        needsReferral
            ? 'साँस फूलेला या हालत गंभीर होखे त मरीज के आजे पीएचसी या अस्पताल भेजीं।'
            : hasFever && hasCough
            ? 'आराम, पानी आ निगरानी के सलाह दीं। मरीज के भीड़ से दूर राखीं आ जरूरत पर पीएचसी भेजीं।'
            : hasDiarrhoea
            ? 'ओआरएस, साफ पानी आ निर्जलीकरण पर नजर रखे के सलाह दीं। जरूरत पर पीएचसी भेजीं।'
            : 'लच्छन पर नजर राखीं, आराम बताईं आ हालत बिगड़े त पीएचसी रेफरल करीं।',
      'bn' =>
        needsReferral
            ? 'শ্বাসকষ্ট বা অবস্থা গুরুতর হলে রোগীকে আজই পিএইচসি বা হাসপাতালে পাঠান।'
            : hasFever && hasCough
            ? 'বিশ্রাম, পানি এবং পর্যবেক্ষণের পরামর্শ দিন। রোগীকে ভিড় থেকে দূরে রাখুন এবং দরকার হলে পিএইচসি পাঠান।'
            : hasDiarrhoea
            ? 'ওআরএস, পরিষ্কার পানি এবং পানিশূন্যতার নজরদারির পরামর্শ দিন। দরকার হলে পিএইচসি পাঠান।'
            : 'উপসর্গ পর্যবেক্ষণ করুন, বিশ্রামের পরামর্শ দিন এবং অবস্থা খারাপ হলে পিএইচসি রেফার করুন।',
      'pa' =>
        needsReferral
            ? 'ਜੇ ਸਾਹ ਫੁੱਲ ਰਿਹਾ ਹੈ ਜਾਂ ਹਾਲਤ ਗੰਭੀਰ ਹੈ ਤਾਂ ਮਰੀਜ਼ ਨੂੰ ਅੱਜ ਹੀ ਪੀਐਚਸੀ ਜਾਂ ਹਸਪਤਾਲ ਭੇਜੋ।'
            : hasFever && hasCough
            ? 'ਆਰਾਮ, ਪਾਣੀ ਅਤੇ ਨਿਗਰਾਨੀ ਦੀ ਸਲਾਹ ਦਿਓ। ਮਰੀਜ਼ ਨੂੰ ਭੀੜ ਤੋਂ ਦੂਰ ਰੱਖੋ ਅਤੇ ਲੋੜ ਪੈਣ ਤੇ ਪੀਐਚਸੀ ਭੇਜੋ।'
            : hasDiarrhoea
            ? 'ਓਆਰਐਸ, ਸਾਫ ਪਾਣੀ ਅਤੇ ਡੀਹਾਈਡਰੇਸ਼ਨ ਦੀ ਨਿਗਰਾਨੀ ਦੀ ਸਲਾਹ ਦਿਓ। ਲੋੜ ਹੋਣ ਤੇ ਪੀਐਚਸੀ ਭੇਜੋ।'
            : 'ਲੱਛਣਾਂ ਦੀ ਨਿਗਰਾਨੀ ਕਰੋ, ਆਰਾਮ ਦੀ ਸਲਾਹ ਦਿਓ ਅਤੇ ਹਾਲਤ ਖਰਾਬ ਹੋਵੇ ਤਾਂ ਪੀਐਚਸੀ ਰੈਫਰ ਕਰੋ।',
      'or' =>
        needsReferral
            ? 'ଶ୍ୱାସକଷ୍ଟ ବା ଗୁରୁତର ଅବସ୍ଥା ଥିଲେ ରୋଗୀଙ୍କୁ ଆଜିହିଁ ପିଏଚସି କିମ୍ବା ହସ୍ପିଟାଲକୁ ପଠାନ୍ତୁ।'
            : hasFever && hasCough
            ? 'ବିଶ୍ରାମ, ପାଣି ଓ ନିରୀକ୍ଷଣର ପରାମର୍ଶ ଦିଅନ୍ତୁ। ରୋଗୀଙ୍କୁ ଭିଡ଼ରୁ ଦୂରେ ରଖନ୍ତୁ ଏବଂ ଆବଶ୍ୟକ ହେଲେ ପିଏଚସି ପଠାନ୍ତୁ।'
            : hasDiarrhoea
            ? 'ଓଆରଏସ, ପରିଷ୍କାର ପାଣି ଓ ଜଳଶୁନ୍ୟତା ନିରୀକ୍ଷଣର ପରାମର୍ଶ ଦିଅନ୍ତୁ। ଆବଶ୍ୟକ ହେଲେ ପିଏଚସି ପଠାନ୍ତୁ।'
            : 'ଲକ୍ଷଣ ନିରୀକ୍ଷଣ କରନ୍ତୁ, ବିଶ୍ରାମର ପରାମର୍ଶ ଦିଅନ୍ତୁ ଏବଂ ଅବସ୍ଥା ଖରାପ ହେଲେ ପିଏଚସି ରେଫର କରନ୍ତୁ।',
      _ =>
        needsReferral
            ? 'If breathing difficulty or severe condition is present, refer the patient to PHC or hospital today.'
            : hasFever && hasCough
            ? 'Advise rest, fluids, and close monitoring. Keep the patient away from crowds and refer to PHC if needed.'
            : hasDiarrhoea
            ? 'Advise ORS, clean water, and watch for dehydration. Refer to PHC if needed.'
            : 'Monitor symptoms, advise rest, and refer to PHC if the condition worsens.',
    };
  }

  static List<String> extractSymptomsFromTranscript(String transcript) {
    final lower = transcript.toLowerCase();
    final symptoms = <String>{};

    if (_containsAny(lower, [
      'fever',
      'bukhar',
      'बुखार',
      'জ্বর',
      'ਬੁਖਾਰ',
      'ଜ୍ୱର',
    ])) {
      symptoms.add('fever');
    }
    if (_containsAny(lower, [
      'cough',
      'khansi',
      'खांसी',
      'কাশি',
      'ਖੰਘ',
      'କାଶ',
    ])) {
      symptoms.add('cough');
    }
    if (_containsAny(lower, [
      'breath',
      'saans',
      'सांस',
      'শ্বাস',
      'ਸਾਹ',
      'ଶ୍ୱାସ',
    ])) {
      symptoms.add('breathlessness');
    }
    if (_containsAny(lower, [
      'rash',
      'daane',
      'चकत्ते',
      'দাগ',
      'ਦਾਣੇ',
      'ଚର୍ମ',
    ])) {
      symptoms.add('rash');
    }
    if (_containsAny(lower, [
      'diarrhoea',
      'diarrhea',
      'loose motion',
      'दस्त',
      'ডায়রিয়া',
      'ਦਸਤ',
      'ଡାୟାରିଆ',
    ])) {
      symptoms.add('diarrhoea');
    }
    if (_containsAny(lower, [
      'vomiting',
      'ulti',
      'उल्टी',
      'বমি',
      'ਉਲਟੀ',
      'ବାନ୍ତି',
    ])) {
      symptoms.add('vomiting');
    }
    if (_containsAny(lower, [
      'headache',
      'sir dard',
      'सिरदर्द',
      'মাথাব্যথা',
      'ਸਿਰ ਦਰਦ',
      'ମୁଣ୍ଡ',
    ])) {
      symptoms.add('headache');
    }

    return symptoms.toList();
  }

  static bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static String _localizedSymptomSentence(
    String localeCode,
    List<String> symptoms,
  ) {
    final localized = localizedSymptoms(symptoms, localeCode);
    return localized.join(', ');
  }
}
