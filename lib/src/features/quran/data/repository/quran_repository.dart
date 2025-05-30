import 'dart:convert';

import 'package:muslim/src/features/quran/data/datasources/quran_api_service.dart';
import 'package:muslim/src/features/quran/data/models/ayah_model.dart';
import 'package:muslim/src/features/quran/data/models/reciter_model.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class QuranRepository {
  Future<List<Surah>> getAllSurahs();
  Future<Surah> getSurah(int surahNumber, {String edition});
  Future<Surah> getSurahWithTranslation(
    int surahNumber, {
    String arabicEdition,
    String translationEdition,
  });
  Future<Ayah> getAyah(int surahNumber, int ayahNumber, {String edition});
  Future<List<Ayah>> searchQuran(String query, {String edition});
  Future<List<Map<String, dynamic>>> getEditions();
  Future<Map<String, dynamic>> getJuz(int juzNumber, {String edition});
  Future<Map<String, dynamic>> getPage(int pageNumber, {String edition});
  List<Reciter> getReciters();
  String getAudioUrl(int surahNumber, Reciter reciter);

  // Local storage methods
  Future<void> saveFavoriteAyah(Ayah ayah);
  Future<void> removeFavoriteAyah(Ayah ayah);
  Future<List<Ayah>> getFavoriteAyahs();
  Future<void> saveBookmark(int surahNumber, int ayahNumber);
  Future<void> removeBookmark(int surahNumber, int ayahNumber);
  Future<List<Map<String, int>>> getBookmarks();
  Future<void> saveLastRead(int surahNumber, int ayahNumber);
  Future<Map<String, int>?> getLastRead();
  Future<void> saveSelectedReciter(Reciter reciter);
  Future<Reciter?> getSelectedReciter();
}

class QuranRepositoryImpl implements QuranRepository {
  final QuranApiService _apiService;
  SharedPreferences? _prefs;

  QuranRepositoryImpl(this._apiService) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<List<Surah>> getAllSurahs() async {
    try {
      // Try to get from cache first
      final cachedSurahs = _prefs?.getString('cached_surahs');
      if (cachedSurahs != null) {
        final List<dynamic> surahsJson =
            json.decode(cachedSurahs) as List<dynamic>;
        return surahsJson
            .map((json) => Surah.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // If not cached, fetch from API
      final surahs = await _apiService.getAllSurahs();

      // Cache the result
      final surahsJson = surahs.map((surah) => surah.toJson()).toList();
      await _prefs?.setString('cached_surahs', json.encode(surahsJson));

      return surahs;
    } catch (e) {
      throw Exception('Failed to get surahs: $e');
    }
  }

  @override
  Future<Surah> getSurah(
    int surahNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      return await _apiService.getSurah(surahNumber, edition: edition);
    } catch (e) {
      throw Exception('Failed to get surah $surahNumber: $e');
    }
  }

  @override
  Future<Surah> getSurahWithTranslation(
    int surahNumber, {
    String arabicEdition = 'ar.alafasy',
    String translationEdition = 'en.sahih',
  }) async {
    try {
      return await _apiService.getSurahWithTranslation(
        surahNumber,
        arabicEdition: arabicEdition,
        translationEdition: translationEdition,
      );
    } catch (e) {
      throw Exception('Failed to get surah with translation: $e');
    }
  }

  @override
  Future<Ayah> getAyah(
    int surahNumber,
    int ayahNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      return await _apiService.getAyah(
        surahNumber,
        ayahNumber,
        edition: edition,
      );
    } catch (e) {
      throw Exception('Failed to get ayah: $e');
    }
  }

  @override
  Future<List<Ayah>> searchQuran(
    String query, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      return await _apiService.searchQuran(query, edition: edition);
    } catch (e) {
      throw Exception('Failed to search Quran: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEditions() async {
    try {
      return await _apiService.getEditions();
    } catch (e) {
      throw Exception('Failed to get editions: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getJuz(
    int juzNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      return await _apiService.getJuz(juzNumber, edition: edition);
    } catch (e) {
      throw Exception('Failed to get Juz: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPage(
    int pageNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      return await _apiService.getPage(pageNumber, edition: edition);
    } catch (e) {
      throw Exception('Failed to get page: $e');
    }
  }

  @override
  List<Reciter> getReciters() {
    return _apiService.getReciters();
  }

  @override
  String getAudioUrl(int surahNumber, Reciter reciter) {
    return _apiService.getAudioUrl(surahNumber, reciter);
  }

  // Local storage implementations
  @override
  Future<void> saveFavoriteAyah(Ayah ayah) async {
    final favorites = await getFavoriteAyahs();
    if (!favorites.any((fav) => fav.number == ayah.number)) {
      favorites.add(ayah);
      final favoritesJson = favorites.map((ayah) => ayah.toJson()).toList();
      await _prefs?.setString('favorite_ayahs', json.encode(favoritesJson));
    }
  }

  @override
  Future<void> removeFavoriteAyah(Ayah ayah) async {
    final favorites = await getFavoriteAyahs();
    favorites.removeWhere((fav) => fav.number == ayah.number);
    final favoritesJson = favorites.map((ayah) => ayah.toJson()).toList();
    await _prefs?.setString('favorite_ayahs', json.encode(favoritesJson));
  }

  @override
  Future<List<Ayah>> getFavoriteAyahs() async {
    final favoritesString = _prefs?.getString('favorite_ayahs');
    if (favoritesString != null) {
      final List<dynamic> favoritesJson =
          json.decode(favoritesString) as List<dynamic>;
      return favoritesJson
          .map((json) => Ayah.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveBookmark(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    final bookmark = {'surahNumber': surahNumber, 'ayahNumber': ayahNumber};
    if (!bookmarks.any(
      (b) => b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber,
    )) {
      bookmarks.add(bookmark);
      await _prefs?.setString('bookmarks', json.encode(bookmarks));
    }
  }

  @override
  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere(
      (b) => b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber,
    );
    await _prefs?.setString('bookmarks', json.encode(bookmarks));
  }

  @override
  Future<List<Map<String, int>>> getBookmarks() async {
    final bookmarksString = _prefs?.getString('bookmarks');
    if (bookmarksString != null) {
      final List<dynamic> bookmarksJson =
          json.decode(bookmarksString) as List<dynamic>;
      return bookmarksJson.cast<Map<String, int>>();
    }
    return [];
  }

  @override
  Future<void> saveLastRead(int surahNumber, int ayahNumber) async {
    final lastRead = {'surahNumber': surahNumber, 'ayahNumber': ayahNumber};
    await _prefs?.setString('last_read', json.encode(lastRead));
  }

  @override
  Future<Map<String, int>?> getLastRead() async {
    final lastReadString = _prefs?.getString('last_read');
    if (lastReadString != null) {
      final Map<String, dynamic> lastReadJson =
          json.decode(lastReadString) as Map<String, dynamic>;
      return lastReadJson.cast<String, int>();
    }
    return null;
  }

  @override
  Future<void> saveSelectedReciter(Reciter reciter) async {
    await _prefs?.setString('selected_reciter', json.encode(reciter.toJson()));
  }

  @override
  Future<Reciter?> getSelectedReciter() async {
    final reciterString = _prefs?.getString('selected_reciter');
    if (reciterString != null) {
      final reciterJson = json.decode(reciterString) as Map<String, dynamic>;
      return Reciter.fromJson(reciterJson);
    }
    return null;
  }
}
