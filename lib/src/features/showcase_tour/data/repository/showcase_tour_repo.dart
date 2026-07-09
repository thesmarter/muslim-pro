import 'package:get_storage/get_storage.dart';

class ShowcaseTourRepo {
  final GetStorage box;

  ShowcaseTourRepo(this.box);

  static const _tourCompletedKey = 'showcase_tour_completed_v2';

  bool get isTourCompleted => box.read(_tourCompletedKey) ?? false;

  Future<void> markTourCompleted() async {
    await box.write(_tourCompletedKey, true);
  }

  Future<void> resetTour() async {
    await box.remove(_tourCompletedKey);
  }
}
