import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/src/features/quran/data/models/ayah_model.dart';
import 'package:muslim/src/features/quran/data/models/reciter_model.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:muslim/src/features/quran/data/repository/quran_repository.dart';

class OfflineQuranRepository implements QuranRepository {
  final SharedPreferences _prefs;

  OfflineQuranRepository(this._prefs);

  // Cache keys
  static const String _surahsCacheKey = 'cached_surahs_offline';
  static const String _quranTextCacheKey = 'cached_quran_text';
  static const String _downloadedSurahsKey = 'downloaded_surahs';
  static const String _lastUpdateKey = 'last_quran_update';

  @override
  Future<List<Surah>> getAllSurahs() async {
    try {
      // Try to get from cache first
      final cachedSurahs = _prefs.getString(_surahsCacheKey);
      if (cachedSurahs != null) {
        final List<dynamic> surahsJson =
            json.decode(cachedSurahs) as List<dynamic>;
        return surahsJson
            .map((json) => Surah.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // If not cached, load from assets
      final surahsData = await _loadSurahsFromAssets();

      // Cache the result
      await _prefs.setString(_surahsCacheKey, json.encode(surahsData));

      return surahsData.map((json) => Surah.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get surahs offline: $e');
    }
  }

  @override
  Future<Surah> getSurah(int surahNumber,
      {String edition = 'ar.alafasy'}) async {
    try {
      // Check if surah is downloaded
      final isDownloaded = await _isSurahDownloaded(surahNumber);

      if (isDownloaded) {
        return await _getSurahFromCache(surahNumber);
      } else {
        // Return basic surah info without ayahs
        final surahs = await getAllSurahs();
        final surah = surahs.firstWhere((s) => s.number == surahNumber);
        return surah.copyWith(ayahs: []);
      }
    } catch (e) {
      throw Exception('Failed to get surah offline: $e');
    }
  }

  @override
  Future<Surah> getSurahWithTranslation(
    int surahNumber, {
    String arabicEdition = 'ar.alafasy',
    String translationEdition = 'en.sahih',
  }) async {
    // For offline mode, return Arabic only
    return getSurah(surahNumber, edition: arabicEdition);
  }

  @override
  Future<Ayah> getAyah(
    int surahNumber,
    int ayahNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final surah = await getSurah(surahNumber, edition: edition);
      final ayah = surah.ayahs.firstWhere(
        (a) => a.numberInSurah == ayahNumber,
        orElse: () => throw Exception('Ayah not found'),
      );
      return ayah;
    } catch (e) {
      throw Exception('Failed to get ayah offline: $e');
    }
  }

  @override
  Future<List<Ayah>> searchQuran(
    String query, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final results = <Ayah>[];
      final surahs = await getAllSurahs();

      for (final surah in surahs) {
        final isDownloaded = await _isSurahDownloaded(surah.number);
        if (isDownloaded) {
          final fullSurah = await _getSurahFromCache(surah.number);
          for (final ayah in fullSurah.ayahs) {
            if (ayah.text.contains(query)) {
              results.add(ayah);
            }
          }
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search Quran offline: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEditions() async {
    // Return default Arabic edition for offline mode
    return [
      {
        'identifier': 'ar.alafasy',
        'language': 'ar',
        'name': 'Arabic',
        'englishName': 'Arabic',
        'format': 'text',
        'type': 'quran',
      }
    ];
  }

  @override
  Future<Map<String, dynamic>> getJuz(
    int juzNumber, {
    String edition = 'ar.alafasy',
  }) async {
    // This would require implementing Juz mapping
    throw UnimplementedError('Juz not implemented for offline mode');
  }

  @override
  Future<Map<String, dynamic>> getPage(
    int pageNumber, {
    String edition = 'ar.alafasy',
  }) async {
    // This would require implementing page mapping
    throw UnimplementedError('Page not implemented for offline mode');
  }

  @override
  List<Reciter> getReciters() {
    return PopularReciters.reciters;
  }

  @override
  String getAudioUrl(int surahNumber, Reciter reciter) {
    return reciter.getAudioUrl(surahNumber);
  }

  // Local storage methods
  @override
  Future<void> saveFavoriteAyah(Ayah ayah) async {
    final favorites = await getFavoriteAyahs();
    if (!favorites.any((a) => a.number == ayah.number)) {
      favorites.add(ayah);
      final favoritesJson = favorites.map((a) => a.toJson()).toList();
      await _prefs.setString('favorite_ayahs', json.encode(favoritesJson));
    }
  }

  @override
  Future<void> removeFavoriteAyah(Ayah ayah) async {
    final favorites = await getFavoriteAyahs();
    favorites.removeWhere((a) => a.number == ayah.number);
    final favoritesJson = favorites.map((a) => a.toJson()).toList();
    await _prefs.setString('favorite_ayahs', json.encode(favoritesJson));
  }

  @override
  Future<List<Ayah>> getFavoriteAyahs() async {
    final favoritesString = _prefs.getString('favorite_ayahs');
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
      await _prefs.setString('bookmarks', json.encode(bookmarks));
    }
  }

  @override
  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere(
      (b) => b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber,
    );
    await _prefs.setString('bookmarks', json.encode(bookmarks));
  }

  @override
  Future<List<Map<String, int>>> getBookmarks() async {
    final bookmarksString = _prefs.getString('bookmarks');
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
    await _prefs.setString('last_read', json.encode(lastRead));
  }

  @override
  Future<Map<String, int>?> getLastRead() async {
    final lastReadString = _prefs.getString('last_read');
    if (lastReadString != null) {
      final Map<String, dynamic> lastReadJson =
          json.decode(lastReadString) as Map<String, dynamic>;
      return lastReadJson.cast<String, int>();
    }
    return null;
  }

  @override
  Future<void> saveSelectedReciter(Reciter reciter) async {
    await _prefs.setString('selected_reciter', json.encode(reciter.toJson()));
  }

  @override
  Future<Reciter?> getSelectedReciter() async {
    final reciterString = _prefs.getString('selected_reciter');
    if (reciterString != null) {
      final Map<String, dynamic> reciterJson =
          json.decode(reciterString) as Map<String, dynamic>;
      return Reciter.fromJson(reciterJson);
    }
    return null;
  }

  // Private helper methods
  Future<List<Map<String, dynamic>>> _loadSurahsFromAssets() async {
    try {
      final String data =
          await rootBundle.loadString('assets/data/surahs.json');
      final List<dynamic> jsonList = json.decode(data) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      // Fallback: create basic surah list
      return _createBasicSurahsList();
    }
  }

  List<Map<String, dynamic>> _createBasicSurahsList() {
    // Basic list of 114 surahs with minimal info
    final surahs = <Map<String, dynamic>>[];
    final surahNames = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام',
      'الأعراف',
      'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
      // ... Add all 114 surah names
    ];

    for (int i = 0; i < 114; i++) {
      surahs.add({
        'number': i + 1,
        'name': i < surahNames.length ? surahNames[i] : 'سورة ${i + 1}',
        'englishName': 'Surah ${i + 1}',
        'englishNameTranslation': 'Surah ${i + 1}',
        'numberOfAyahs': 7, // Default, should be actual count
        'revelationType': 'Meccan',
      });
    }

    return surahs;
  }

  Future<bool> _isSurahDownloaded(int surahNumber) async {
    final downloadedSurahs = _prefs.getStringList(_downloadedSurahsKey) ?? [];
    return downloadedSurahs.contains(surahNumber.toString());
  }

  Future<Surah> _getSurahFromCache(int surahNumber) async {
    final cacheKey = '${_quranTextCacheKey}_$surahNumber';
    final cachedSurah = _prefs.getString(cacheKey);

    if (cachedSurah != null) {
      final Map<String, dynamic> surahJson =
          json.decode(cachedSurah) as Map<String, dynamic>;
      return Surah.fromJson(surahJson);
    }

    throw Exception('Surah $surahNumber not found in cache');
  }

  // Download management methods
  Future<void> downloadSurah(int surahNumber) async {
    // This would download and cache a surah for offline use
    // Implementation would depend on your data source
  }

  Future<void> deleteCachedSurah(int surahNumber) async {
    final cacheKey = '${_quranTextCacheKey}_$surahNumber';
    await _prefs.remove(cacheKey);

    final downloadedSurahs = _prefs.getStringList(_downloadedSurahsKey) ?? [];
    downloadedSurahs.remove(surahNumber.toString());
    await _prefs.setStringList(_downloadedSurahsKey, downloadedSurahs);
  }

  Future<List<int>> getDownloadedSurahs() async {
    final downloadedSurahs = _prefs.getStringList(_downloadedSurahsKey) ?? [];
    return downloadedSurahs.map((s) => int.parse(s)).toList();
  }
}
