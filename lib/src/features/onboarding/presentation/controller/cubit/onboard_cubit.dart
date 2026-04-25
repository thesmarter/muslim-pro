import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/shared/widgets/empty.dart';
import 'package:muslim/src/core/utils/volume_button_manager.dart';
import 'package:muslim/src/features/settings/data/repository/app_settings_repo.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'onboard_state.dart';

class OnboardCubit extends Cubit<OnboardState> {
  final AppSettingsRepo appSettingsRepo;
  final VolumeButtonManager volumeButtonManager;
  PageController pageController = PageController();
  OnboardCubit(this.appSettingsRepo, this.volumeButtonManager) : super(OnboardLoadingState()) {
    _init();
  }

  StreamSubscription? _volumeSubscription;
  void _init() {
    volumeButtonManager.toggleActivation(activate: true);
    _volumeSubscription = volumeButtonManager.stream.listen((event) {
      if (event == VolumeButtonEvent.volumeUpDown || event == VolumeButtonEvent.volumeUpUp) {
        pageController.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      } else if (event == VolumeButtonEvent.volumeDownDown ||
          event == VolumeButtonEvent.volumeDownUp) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      }
    });

    pageController.addListener(() {
      final int index = pageController.page!.round();
      onPageChanged(index);
    });
  }

  ///TODO: Change every release
  List<Empty> get pageData {
    return [
      const Empty(
        title: "الجديد في هذا الإصدار",
        isImage: false,
        isItemList: true,
        description: """
مواقيت الصلاة: أضفنا نظاماً متكاملاً لمواقيت الصلاة مع تحديد تلقائي للموقع، وبحث يدوي عن المدن، وإمكانية تعديل الأوقات بدقة.
المصحف الشامل: قسم جديد للقرآن الكريم (بالرسم العثماني) مع إمكانية القراءة، البحث، والتفسير، والاستماع بأصوات مشاهير القراء.
تكامل ذكي: الوصول للمصحف ومواقيت الصلاة مباشرة من التبويبات الرئيسية لسهولة التنقل.
تحسينات الأداء: ضغط حجم التطبيق عبر نظام عرض تقني حديث وأكثر سلاسة.
إصلاحات عامة: تحسين استقرار نظام الإشعارات ومعالجة بعض الأخطاء في عرض الأذكار.
""",
      ),
    ];
  }

  Future start() async {
    emit(
      OnboardLoadedState(
        showSkipBtn: true,
        currentPageIndex: 0,
        pages: pageData,
      ),
    );
  }

  Future onPageChanged(int index) async {
    final state = this.state;
    if (state is! OnboardLoadedState) return;
    emit(state.copyWith(currentPageIndex: index));
  }

  Future done() async {
    await appSettingsRepo.changCurrentVersion(value: sl<PackageInfo>().version);
    _volumeSubscription?.cancel();
    volumeButtonManager.dispose();
    emit(OnboardDoneState());
  }

  @override
  Future<void> close() {
    pageController.dispose();
    _volumeSubscription?.cancel();
    volumeButtonManager.dispose();
    return super.close();
  }
}
