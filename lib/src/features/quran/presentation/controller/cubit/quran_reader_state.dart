part of 'quran_reader_cubit.dart';

abstract class QuranReaderState extends Equatable {
  const QuranReaderState();

  @override
  List<Object?> get props => [];
}

class QuranReaderInitial extends QuranReaderState {}

class QuranReaderLoading extends QuranReaderState {}

class QuranReaderError extends QuranReaderState {
  final String message;

  const QuranReaderError(this.message);

  @override
  List<Object> get props => [message];
}

class QuranReaderSurahsLoaded extends QuranReaderState {
  final List<Surah> surahs;

  const QuranReaderSurahsLoaded(this.surahs);

  @override
  List<Object> get props => [surahs];
}

class QuranReaderSurahLoaded extends QuranReaderState {
  final Surah surah;

  const QuranReaderSurahLoaded(this.surah);

  @override
  List<Object> get props => [surah];
}

class QuranReaderSearchEmpty extends QuranReaderState {}

class QuranReaderSearchLoading extends QuranReaderState {}

class QuranReaderSearchResults extends QuranReaderState {
  final List<Ayah> results;
  final String query;

  const QuranReaderSearchResults(this.results, this.query);

  @override
  List<Object> get props => [results, query];
}

class QuranReaderFavoritesLoaded extends QuranReaderState {
  final List<Ayah> favorites;

  const QuranReaderFavoritesLoaded(this.favorites);

  @override
  List<Object> get props => [favorites];
}

class QuranReaderBookmarksLoaded extends QuranReaderState {
  final List<Map<String, int>> bookmarks;

  const QuranReaderBookmarksLoaded(this.bookmarks);

  @override
  List<Object> get props => [bookmarks];
}

class QuranReaderJuzLoaded extends QuranReaderState {
  final Map<String, dynamic> juzData;

  const QuranReaderJuzLoaded(this.juzData);

  @override
  List<Object> get props => [juzData];
}

class QuranReaderPageLoaded extends QuranReaderState {
  final Map<String, dynamic> pageData;

  const QuranReaderPageLoaded(this.pageData);

  @override
  List<Object> get props => [pageData];
}

class QuranReaderRecitersLoaded extends QuranReaderState {
  final List<Reciter> reciters;

  const QuranReaderRecitersLoaded(this.reciters);

  @override
  List<Object> get props => [reciters];
}
