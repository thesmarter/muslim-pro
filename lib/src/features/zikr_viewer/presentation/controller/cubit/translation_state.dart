// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'translation_cubit.dart';

class TranslationState extends Equatable {
  final String selectedLanguage;
  final bool showTranslation;
  final Map<int, String> titleTranslations;
  final Map<int, Map<String, String?>> contentTranslations;

  const TranslationState({
    this.selectedLanguage = 'ar',
    this.showTranslation = false,
    this.titleTranslations = const {},
    this.contentTranslations = const {},
  });

  @override
  List<Object> get props {
    return [
      selectedLanguage,
      showTranslation,
      titleTranslations,
      contentTranslations,
    ];
  }

  TranslationState copyWith({
    String? selectedLanguage,
    bool? showTranslation,
    Map<int, String>? titleTranslations,
    Map<int, Map<String, String?>>? contentTranslations,
  }) {
    return TranslationState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      showTranslation: showTranslation ?? this.showTranslation,
      titleTranslations: titleTranslations ?? this.titleTranslations,
      contentTranslations: contentTranslations ?? this.contentTranslations,
    );
  }
}
