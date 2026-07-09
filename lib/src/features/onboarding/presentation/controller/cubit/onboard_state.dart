// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'onboard_cubit.dart';

sealed class OnboardState extends Equatable {
  const OnboardState();

  @override
  List<Object> get props => [];
}

final class OnboardLoadingState extends OnboardState {}

class OnboardLoadedState extends OnboardState {
  final int currentPageIndex;
  final bool showSkipBtn;
  final int pageCount;

  const OnboardLoadedState({
    required this.currentPageIndex,
    required this.showSkipBtn,
    required this.pageCount,
  });

  bool get isFinalPage => currentPageIndex + 1 == pageCount;

  OnboardLoadedState copyWith({
    int? currentPageIndex,
    bool? showSkipBtn,
    int? pageCount,
  }) {
    return OnboardLoadedState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      showSkipBtn: showSkipBtn ?? this.showSkipBtn,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  @override
  List<Object> get props => [
    currentPageIndex,
    showSkipBtn,
    pageCount,
  ];
}

class OnboardDoneState extends OnboardState {}
