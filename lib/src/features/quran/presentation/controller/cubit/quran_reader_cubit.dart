import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muslim/src/features/quran/data/models/ayah_model.dart';
import 'package:muslim/src/features/quran/data/models/reciter_model.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:muslim/src/features/quran/data/repository/quran_repository.dart';

part 'quran_reader_state.dart';

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final QuranRepository _repository;

  QuranReaderCubit(this._repository) : super(QuranReaderInitial());

  // Load all surahs
  Future<void> loadSurahs() async {
    try {
      emit(QuranReaderLoading());
      final surahs = await _repository.getAllSurahs();
      emit(QuranReaderSurahsLoaded(surahs));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Load specific surah
  Future<void> loadSurah(
    int surahNumber, {
    bool withTranslation = false,
  }) async {
    try {
      emit(QuranReaderLoading());

      final Surah surah;
      if (withTranslation) {
        surah = await _repository.getSurahWithTranslation(surahNumber);
      } else {
        surah = await _repository.getSurah(surahNumber);
      }

      // Save as last read
      if (surah.ayahs.isNotEmpty) {
        await _repository.saveLastRead(surahNumber, 1);
      }

      emit(QuranReaderSurahLoaded(surah));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Search in Quran
  Future<void> searchQuran(String query) async {
    if (query.trim().isEmpty) {
      emit(QuranReaderSearchEmpty());
      return;
    }

    try {
      emit(QuranReaderSearchLoading());
      final results = await _repository.searchQuran(query);
      emit(QuranReaderSearchResults(results, query));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Clear search
  void clearSearch() {
    emit(QuranReaderSearchEmpty());
  }

  // Toggle favorite ayah
  Future<void> toggleFavoriteAyah(Ayah ayah) async {
    try {
      if (ayah.isFavorite) {
        await _repository.removeFavoriteAyah(ayah);
      } else {
        await _repository.saveFavoriteAyah(ayah.copyWith(isFavorite: true));
      }

      // Reload current state if it's a surah
      if (state is QuranReaderSurahLoaded) {
        final currentState = state as QuranReaderSurahLoaded;
        final updatedAyahs = currentState.surah.ayahs.map((a) {
          if (a.number == ayah.number) {
            return a.copyWith(isFavorite: !a.isFavorite);
          }
          return a;
        }).toList();

        final updatedSurah = currentState.surah.copyWith(ayahs: updatedAyahs);
        emit(QuranReaderSurahLoaded(updatedSurah));
      }
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Toggle bookmark ayah
  Future<void> toggleBookmarkAyah(Ayah ayah, int surahNumber) async {
    try {
      if (ayah.isBookmarked) {
        await _repository.removeBookmark(surahNumber, ayah.numberInSurah);
      } else {
        await _repository.saveBookmark(surahNumber, ayah.numberInSurah);
      }

      // Reload current state if it's a surah
      if (state is QuranReaderSurahLoaded) {
        final currentState = state as QuranReaderSurahLoaded;
        final updatedAyahs = currentState.surah.ayahs.map((a) {
          if (a.number == ayah.number) {
            return a.copyWith(isBookmarked: !a.isBookmarked);
          }
          return a;
        }).toList();

        final updatedSurah = currentState.surah.copyWith(ayahs: updatedAyahs);
        emit(QuranReaderSurahLoaded(updatedSurah));
      }
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Load favorites
  Future<void> loadFavorites() async {
    try {
      emit(QuranReaderLoading());
      final favorites = await _repository.getFavoriteAyahs();
      emit(QuranReaderFavoritesLoaded(favorites));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Load bookmarks
  Future<void> loadBookmarks() async {
    try {
      emit(QuranReaderLoading());
      final bookmarks = await _repository.getBookmarks();
      emit(QuranReaderBookmarksLoaded(bookmarks));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Load last read
  Future<void> loadLastRead() async {
    try {
      final lastRead = await _repository.getLastRead();
      if (lastRead != null) {
        await loadSurah(lastRead['surahNumber']!);
      }
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Load Juz (Para)
  Future<void> loadJuz(int juzNumber) async {
    try {
      emit(QuranReaderLoading());
      final juzData = await _repository.getJuz(juzNumber);
      emit(QuranReaderJuzLoaded(juzData));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Load page
  Future<void> loadPage(int pageNumber) async {
    try {
      emit(QuranReaderLoading());
      final pageData = await _repository.getPage(pageNumber);
      emit(QuranReaderPageLoaded(pageData));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Get reciters
  void loadReciters() {
    try {
      final reciters = _repository.getReciters();
      emit(QuranReaderRecitersLoaded(reciters));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Select reciter
  Future<void> selectReciter(Reciter reciter) async {
    try {
      await _repository.saveSelectedReciter(reciter);
      final updatedReciters = _repository.getReciters().map((r) {
        return r.copyWith(isSelected: r.id == reciter.id);
      }).toList();
      emit(QuranReaderRecitersLoaded(updatedReciters));
    } catch (e) {
      emit(QuranReaderError(e.toString()));
    }
  }

  // Get audio URL
  String getAudioUrl(int surahNumber, Reciter reciter) {
    return _repository.getAudioUrl(surahNumber, reciter);
  }
}
