/// Model representing a Surah (chapter) in the Quran
class SurahModel {
  /// Surah number (1-114)
  final int id;

  /// Arabic name of the Surah
  final String nameArabic;

  /// English transliteration of the Surah name
  final String nameEnglish;

  /// Type of Surah: "مكية" (Meccan) or "مدنية" (Medinan)
  final String type;

  /// Number of verses (ayat) in the Surah
  final int versesCount;

  /// URL to the audio file of the Surah recitation
  final String audioUrl;

  /// Whether the audio file has been downloaded for offline use
  bool isDownloaded;

  /// Whether the Surah is marked as favorite by the user
  bool isFavorite;

  /// Download progress (0.0 to 1.0)
  double downloadProgress;

  /// Creates a new SurahModel instance
  SurahModel({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.type,
    required this.versesCount,
    required this.audioUrl,
    this.isDownloaded = false,
    this.isFavorite = false,
    this.downloadProgress = 0.0,
  });

  /// Generates the audio file name based on Surah ID
  /// Example: Surah 1 -> "001.mp3", Surah 114 -> "114.mp3"
  String get audioFileName => '${id.toString().padLeft(3, '0')}.mp3';

  /// Returns the display name based on the current locale
  String getDisplayName(bool isArabic) {
    return isArabic ? nameArabic : nameEnglish;
  }

  /// Converts the SurahModel to a JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'nameArabic': nameArabic,
        'nameEnglish': nameEnglish,
        'type': type,
        'versesCount': versesCount,
        'audioUrl': audioUrl,
        'isDownloaded': isDownloaded,
        'isFavorite': isFavorite,
        'downloadProgress': downloadProgress,
      };

  /// Creates a SurahModel from a JSON map
  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] as int,
      nameArabic: json['nameArabic'] as String,
      nameEnglish: json['nameEnglish'] as String,
      type: json['type'] as String,
      versesCount: json['versesCount'] as int,
      audioUrl: json['audioUrl'] as String,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Creates a copy of this SurahModel with optionally modified fields
  SurahModel copyWith({
    int? id,
    String? nameArabic,
    String? nameEnglish,
    String? type,
    int? versesCount,
    String? audioUrl,
    bool? isDownloaded,
    bool? isFavorite,
    double? downloadProgress,
  }) {
    return SurahModel(
      id: id ?? this.id,
      nameArabic: nameArabic ?? this.nameArabic,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      type: type ?? this.type,
      versesCount: versesCount ?? this.versesCount,
      audioUrl: audioUrl ?? this.audioUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  @override
  String toString() {
    return 'SurahModel(id: $id, nameArabic: $nameArabic, nameEnglish: $nameEnglish, '
        'type: $type, versesCount: $versesCount, isDownloaded: $isDownloaded, '
        'isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurahModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
