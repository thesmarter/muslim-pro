import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
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

  Future start() async {
    emit(
      const OnboardLoadedState(
        showSkipBtn: true,
        currentPageIndex: 0,
        pageCount: 1,
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
