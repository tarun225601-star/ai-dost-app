class AppMode {
  final int id;
  final String name;
  final String description;
  final bool isFree;
  final bool isVipPredictive;

  const AppMode({
    required this.id,
    required this.name,
    required this.description,
    required this.isFree,
    required this.isVipPredictive,
  });
}

class AppModesList {
  static const List<AppMode> modes = [
    AppMode(
      id: 1,
      name: "सिंपल चैट (Simple Chat)",
      description: "जेमिनी जैसी सरल और सादी फ्री बातचीत",
      isFree: true,
      isVipPredictive: false,
    ),
    AppMode(
      id: 2,
      name: "स्टडी मोड (Study Line)",
      description: "पढ़ाई, नोट्स और कठिन विषयों को आसान बनाने के लिए",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 3,
      name: "फ्रेंडली बातचीत (Friend Line)",
      description: "दिल की बात शेयर करने और दोस्ती निभाने के लिए",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 4,
      name: "बिजनेस लाइन (Business & Startup)",
      description: "बिजनेस आइडिया, स्टार्टअप और मार्केटिंग रणनीतियां",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 5,
      name: "संकटमोचन / क्राइसिस मोड",
      description: "मुसीबत या तनाव के समय सही रास्ता दिखाने के लिए",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 6,
      name: "हेल्थ और फिटनेस लाइन",
      description: "सेहत, डाइट और मानसिक शांति के लिए",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 7,
      name: "क्रिएटिव स्टूडियो (Creative Line)",
      description: "लिखने, वीडियो स्क्रिप्ट या किसी भी क्रिएटिव काम के लिए",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 8,
      name: "फाइनेंस और मनी लाइन",
      description: "पैसे बचाने और बजट मैनेज करने के लिए",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 9,
      name: "लीगल और ट्रेवल गाइड",
      description: "कानूनी उलझनों और नई जगहों की जानकारी के लिए",
      isFree: false,
      isVipPredictive: false,
    ),
    AppMode(
      id: 10,
      name: "प्रिडिक्टिव भविष्यवाणी मोड (VIP)",
      description: "आपकी जरूरत को पहले ही भांपकर सबसे सटीक सुझाव देने वाला",
      isFree: false,
      isVipPredictive: true, // यह सबसे महंगा और वीआईपी मोड है!
    ),
  ];
}
