import 'package:equatable/equatable.dart';

class Ayah extends Equatable {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final bool sajda;
  final String? translation;
  final String? transliteration;
  final String? tafsir;
  final bool isFavorite;
  final bool isBookmarked;
  final String? audioUrl;

  const Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.sajda,
    this.translation,
    this.transliteration,
    this.tafsir,
    this.isFavorite = false,
    this.isBookmarked = false,
    this.audioUrl,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      manzil: json['manzil'] as int,
      page: json['page'] as int,
      ruku: json['ruku'] as int,
      hizbQuarter: json['hizbQuarter'] as int,
      sajda: json['sajda'] as bool? ?? false,
      translation: json['translation'] as String?,
      transliteration: json['transliteration'] as String?,
      tafsir: json['tafsir'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'sajda': sajda,
      'translation': translation,
      'transliteration': transliteration,
      'tafsir': tafsir,
      'isFavorite': isFavorite,
      'isBookmarked': isBookmarked,
      'audioUrl': audioUrl,
    };
  }

  Ayah copyWith({
    int? number,
    String? text,
    int? numberInSurah,
    int? juz,
    int? manzil,
    int? page,
    int? ruku,
    int? hizbQuarter,
    bool? sajda,
    String? translation,
    String? transliteration,
    String? tafsir,
    bool? isFavorite,
    bool? isBookmarked,
    String? audioUrl,
  }) {
    return Ayah(
      number: number ?? this.number,
      text: text ?? this.text,
      numberInSurah: numberInSurah ?? this.numberInSurah,
      juz: juz ?? this.juz,
      manzil: manzil ?? this.manzil,
      page: page ?? this.page,
      ruku: ruku ?? this.ruku,
      hizbQuarter: hizbQuarter ?? this.hizbQuarter,
      sajda: sajda ?? this.sajda,
      translation: translation ?? this.translation,
      transliteration: transliteration ?? this.transliteration,
      tafsir: tafsir ?? this.tafsir,
      isFavorite: isFavorite ?? this.isFavorite,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  @override
  List<Object?> get props => [
        number,
        text,
        numberInSurah,
        juz,
        manzil,
        page,
        ruku,
        hizbQuarter,
        sajda,
        translation,
        transliteration,
        tafsir,
        isFavorite,
        isBookmarked,
        audioUrl,
      ];
}
