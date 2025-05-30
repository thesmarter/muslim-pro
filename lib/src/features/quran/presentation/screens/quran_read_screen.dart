import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension_object.dart';
import 'package:muslim/src/core/shared/widgets/loading.dart';
import 'package:muslim/src/core/values/constant.dart';
import 'package:muslim/src/features/quran/data/models/surah_name_enum.dart';
import 'package:muslim/src/features/quran/presentation/components/between_page_effect.dart';
import 'package:muslim/src/features/quran/presentation/components/page_side_effect.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_cubit.dart';

class QuranReadScreen extends StatelessWidget {
  final SurahNameEnum surahName;

  const QuranReadScreen({super.key, required this.surahName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<QuranCubit>()..start(surahName),
      child: BlocBuilder<QuranCubit, QuranState>(
        builder: (context, state) {
          if (state is! QuranLoadedState) {
            return const Loading();
          }
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
              title: Text(
                () {
                  switch (state.surahName) {
                    case SurahNameEnum.alKahf:
                      return S.of(context).suraAlKahf;
                    case SurahNameEnum.alMulk:
                      return S.of(context).suraAlMulk;
                    case SurahNameEnum.assajdah:
                      return S.of(context).suraAsSajdah;
                    case SurahNameEnum.endofAliImran:
                      return S.of(context).endSuraAliImran;
                  }
                }(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8.0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${state.requiredSurah.pages.length}"
                        .toArabicNumberString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: GestureDetector(
                onDoubleTap: () => context.read<QuranCubit>().onDoubleTap(),
                child: PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  controller: context.read<QuranCubit>().pageController,
                  itemCount: state.requiredSurah.pages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: Card(
                        elevation: 8,
                        shadowColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              BetweenPageEffect(
                                index:
                                    state.requiredSurah.pages[index].pageNumber,
                              ),
                              PageSideEffect(
                                index:
                                    state.requiredSurah.pages[index].pageNumber,
                              ),
                              Center(
                                child: ColorFiltered(
                                  colorFilter: greyScale,
                                  child: ColorFiltered(
                                    colorFilter: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? invert
                                        : normal,
                                    child: Image.asset(
                                      state.requiredSurah.pages[index].image,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 400,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_not_supported,
                                                size: 64,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'لا يمكن تحميل الصفحة',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'الصفحة رقم ${state.requiredSurah.pages[index].pageNumber}',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    state.requiredSurah.pages[index].pageNumber
                                        .toArabicNumberString(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
