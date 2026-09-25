import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/core/functions/print.dart';

class AppBlocObserver extends BlocObserver {
  bool detailed = false;
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is Cubit) {
      if (detailed) {
        printColor(
          '[Cubit] currentState: ${change.currentState} | nextState: ${change.nextState}',
          color: PrintColors.red,
        );
      } else {
        printColor(
          '[Cubit] currentState: ${change.currentState.runtimeType} | nextState: ${change.nextState.runtimeType}',
          color: PrintColors.red,
        );
      }
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (detailed) {
        printColor(
          '[Bloc] event: ${transition.event} | currentState: ${transition.currentState} | nextState: ${transition.nextState}',
          color: PrintColors.magenta,
        );
      } else {
        printColor(
          '[Bloc] event: ${transition.event.runtimeType} | currentState: ${transition.currentState.runtimeType} | nextState: ${transition.nextState.runtimeType}',
          color: PrintColors.magenta,
        );
    }
  }
}
