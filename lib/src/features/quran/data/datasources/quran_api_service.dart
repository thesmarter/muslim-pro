import 'package:dio/dio.dart';
import 'package:muslim/src/features/quran/data/models/ayah_model.dart';
import 'package:muslim/src/features/quran/data/models/reciter_model.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';

class QuranApiService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  final Dio _dio;

  QuranApiService() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Get all surahs with basic information
  Future<List<Surah>> getAllSurahs() async {
    try {
      final response = await _dio.get('/surah');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((surah) => Surah.fromJson(surah as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load surahs');
      }
    } catch (e) {
      throw Exception('Error fetching surahs: $e');
    }
  }

  // Get specific surah with all ayahs
  Future<Surah> getSurah(
    int surahNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final response = await _dio.get('/surah/$surahNumber/$edition');

      if (response.statusCode == 200) {
        final surahData = response.data['data'] as Map<String, dynamic>;
        return Surah.fromJson(surahData);
      } else {
        throw Exception('Failed to load surah $surahNumber');
      }
    } catch (e) {
      throw Exception('Error fetching surah $surahNumber: $e');
    }
  }

  // Get surah with translation
  Future<Surah> getSurahWithTranslation(
    int surahNumber, {
    String arabicEdition = 'ar.alafasy',
    String translationEdition = 'en.sahih',
  }) async {
    try {
      // Get Arabic text
      final arabicResponse =
          await _dio.get('/surah/$surahNumber/$arabicEdition');

      // Get translation
      final translationResponse =
          await _dio.get('/surah/$surahNumber/$translationEdition');

      if (arabicResponse.statusCode == 200 &&
          translationResponse.statusCode == 200) {
        final arabicData = arabicResponse.data['data'] as Map<String, dynamic>;
        final translationData =
            translationResponse.data['data'] as Map<String, dynamic>;

        // Combine Arabic and translation
        final surah = Surah.fromJson(arabicData);
        final translationAyahs = translationData['ayahs'] as List<dynamic>;

        final combinedAyahs = <Ayah>[];
        for (int i = 0; i < surah.ayahs.length; i++) {
          final ayah = surah.ayahs[i];
          final translation = i < translationAyahs.length
              ? (translationAyahs[i] as Map<String, dynamic>)['text'] as String
              : null;

          combinedAyahs.add(ayah.copyWith(translation: translation));
        }

        return surah.copyWith(ayahs: combinedAyahs);
      } else {
        throw Exception('Failed to load surah with translation');
      }
    } catch (e) {
      throw Exception('Error fetching surah with translation: $e');
    }
  }

  // Get specific ayah
  Future<Ayah> getAyah(
    int surahNumber,
    int ayahNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final response =
          await _dio.get('/ayah/$surahNumber:$ayahNumber/$edition');

      if (response.statusCode == 200) {
        final ayahData = response.data['data'] as Map<String, dynamic>;
        return Ayah.fromJson(ayahData);
      } else {
        throw Exception('Failed to load ayah $surahNumber:$ayahNumber');
      }
    } catch (e) {
      throw Exception('Error fetching ayah: $e');
    }
  }

  // Search in Quran
  Future<List<Ayah>> searchQuran(
    String query, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final response = await _dio.get('/search/$query/all/$edition');

      if (response.statusCode == 200) {
        final matches = response.data['data']['matches'] as List<dynamic>;
        return matches
            .map((match) => Ayah.fromJson(match as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to search in Quran');
      }
    } catch (e) {
      throw Exception('Error searching in Quran: $e');
    }
  }

  // Get available editions (translations, reciters, etc.)
  Future<List<Map<String, dynamic>>> getEditions() async {
    try {
      final response = await _dio.get('/edition');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          response.data['data'] as List<dynamic>,
        );
      } else {
        throw Exception('Failed to load editions');
      }
    } catch (e) {
      throw Exception('Error fetching editions: $e');
    }
  }

  // Get Juz (Para) information
  Future<Map<String, dynamic>> getJuz(
    int juzNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final response = await _dio.get('/juz/$juzNumber/$edition');

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Juz $juzNumber');
      }
    } catch (e) {
      throw Exception('Error fetching Juz: $e');
    }
  }

  // Get page information
  Future<Map<String, dynamic>> getPage(
    int pageNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final response = await _dio.get('/page/$pageNumber/$edition');

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load page $pageNumber');
      }
    } catch (e) {
      throw Exception('Error fetching page: $e');
    }
  }

  // Get audio URL for surah
  String getAudioUrl(int surahNumber, Reciter reciter) {
    return reciter.getAudioUrl(surahNumber);
  }

  // Get available reciters
  List<Reciter> getReciters() {
    return PopularReciters.reciters;
  }
}
