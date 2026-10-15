import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/features/update/data/models/update_info_model.dart';
import 'package:muslim/src/features/update/data/repository/update_repo.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class UpdateState {}

class UpdateInitial extends UpdateState {}
class UpdateLoading extends UpdateState {}
class UpdateNoNeeded extends UpdateState {}
class ForceUpdateRequired extends UpdateState {
  final UpdateInfo updateInfo;
  ForceUpdateRequired(this.updateInfo);
}
class OptionalUpdateAvailable extends UpdateState {
  final UpdateInfo updateInfo;
  OptionalUpdateAvailable(this.updateInfo);
}

class UpdateCubit extends Cubit<UpdateState> {
  final UpdateRepo _repo;
  final PackageInfo _packageInfo;

  UpdateCubit(this._repo, this._packageInfo) : super(UpdateInitial());

  Future<void> checkForUpdate() async {
    emit(UpdateLoading());
    
    final updateInfo = await _repo.fetchUpdateInfo();
    
    if (updateInfo != null) {
      final int currentAppVersion = int.tryParse(_packageInfo.buildNumber) ?? 0;
      
      if (_isUpdateRequired(currentAppVersion, updateInfo.latestVersion)) {
        if (updateInfo.forceUpdate) {
          emit(ForceUpdateRequired(updateInfo));
        } else {
          emit(OptionalUpdateAvailable(updateInfo));
        }
        return;
      }
    }
    
    emit(UpdateNoNeeded());
  }

  void dismissUpdate() {
    emit(UpdateNoNeeded());
  }

  bool _isUpdateRequired(int currentVersion, String latestVersionStr) {
    try {
      final int latestVersion = int.parse(latestVersionStr);
      return latestVersion > currentVersion;
    } catch (e) {
      return false;
    }
  }
}
