// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:muslim/src/features/home/data/repository/translation_db_helper.dart';

part 'translation_state.dart';

class TranslationCubit extends Cubit<TranslationState> {
  final GetStorage box;
  final TranslationDBHelper translationDBHelper;
  TranslationCubit(
    this.box,
    this.translationDBHelper,
  ) : super(
          TranslationState(
            selectedLanguage: box.read<String>('translation_language') ?? 'ar',
            showTranslation: box.read<bool>('show_translation') ?? false,
          ),
        );

  ///MARK: Change Language
  Future<void> changeLanguage(String language) async {
    await box.write('translation_language', language);
    emit(state.copyWith(selectedLanguage: language));
  }

  ///MARK: Toggle Translation
  Future<void> toggleTranslation() async {
    final newValue = !state.showTranslation;
    await box.write('show_translation', newValue);
    emit(state.copyWith(showTranslation: newValue));
  }

  ///MARK: Load Translations
  Future<void> loadTranslations() async {
    final titleTranslations =
        await translationDBHelper.getAllTitleTranslations(state.selectedLanguage);
    final contentTranslations =
        await translationDBHelper.getAllContentTranslations(state.selectedLanguage);
    emit(
      state.copyWith(
        titleTranslations: titleTranslations,
        contentTranslations: contentTranslations,
      ),
    );
  }
}
