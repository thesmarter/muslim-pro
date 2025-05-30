import 'package:equatable/equatable.dart';

class Reciter extends Equatable {
  final int id;
  final String name;
  final String englishName;
  final String language;
  final String format;
  final String baseUrl;
  final bool isSelected;
  final String? description;
  final String? imageUrl;

  const Reciter({
    required this.id,
    required this.name,
    required this.englishName,
    required this.language,
    required this.format,
    required this.baseUrl,
    this.isSelected = false,
    this.description,
    this.imageUrl,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      language: json['language'] as String,
      format: json['format'] as String,
      baseUrl: json['baseUrl'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'language': language,
      'format': format,
      'baseUrl': baseUrl,
      'isSelected': isSelected,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  Reciter copyWith({
    int? id,
    String? name,
    String? englishName,
    String? language,
    String? format,
    String? baseUrl,
    bool? isSelected,
    String? description,
    String? imageUrl,
  }) {
    return Reciter(
      id: id ?? this.id,
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      language: language ?? this.language,
      format: format ?? this.format,
      baseUrl: baseUrl ?? this.baseUrl,
      isSelected: isSelected ?? this.isSelected,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String getAudioUrl(int surahNumber) {
    // Format the surah number with leading zeros (e.g., 001, 002, etc.)
    final formattedSurahNumber = surahNumber.toString().padLeft(3, '0');
    return '$baseUrl$formattedSurahNumber.$format';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        englishName,
        language,
        format,
        baseUrl,
        isSelected,
        description,
        imageUrl,
      ];
}

// Predefined popular reciters
class PopularReciters {
  static const List<Reciter> reciters = [
    Reciter(
      id: 1,
      name: 'عبد الباسط عبد الصمد',
      englishName: 'Abdul Basit Abdul Samad',
      language: 'Arabic',
      format: 'mp3',
      baseUrl: 'https://server8.mp3quran.net/abd_basit/',
      description: 'One of the most famous Quran reciters',
    ),
    Reciter(
      id: 2,
      name: 'مشاري راشد العفاسي',
      englishName: 'Mishary Rashid Alafasy',
      language: 'Arabic',
      format: 'mp3',
      baseUrl: 'https://server8.mp3quran.net/afs/',
      description: 'Popular contemporary reciter from Kuwait',
    ),
    Reciter(
      id: 3,
      name: 'ماهر المعيقلي',
      englishName: 'Maher Al Muaiqly',
      language: 'Arabic',
      format: 'mp3',
      baseUrl: 'https://server8.mp3quran.net/maher/',
      description: 'Imam of the Grand Mosque in Mecca',
    ),
    Reciter(
      id: 4,
      name: 'سعد الغامدي',
      englishName: 'Saad Al Ghamdi',
      language: 'Arabic',
      format: 'mp3',
      baseUrl: 'https://server7.mp3quran.net/s_gmd/',
      description: 'Popular Saudi reciter',
    ),
    Reciter(
      id: 3,
      name: 'ماهر المعيقلي',
      englishName: 'Maher Al Mueaqly',
      language: 'Arabic',
      format: 'mp3',
      baseUrl: 'https://server11.mp3quran.net/maher/',
      description: 'Imam of the Grand Mosque in Mecca',
    ),
    Reciter(
      id: 4,
      name: 'سعد الغامدي',
      englishName: 'Saad Al Ghamdi',
      language: 'Arabic',
      format: 'mp3',
      baseUrl: 'https://server7.mp3quran.net/s_gmd/',
      description: 'Renowned Saudi reciter',
    ),
    Reciter(
      id: 5,
      name: 'أحمد العجمي',
      englishName: 'Ahmed Al Ajmy',
      language: 'Arabic',
      format: 'mp3',
      baseUrl: 'https://server10.mp3quran.net/ajm/',
      description: 'Imam of the Grand Mosque in Mecca',
    ),
  ];
}
