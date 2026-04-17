import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/features/update/data/models/update_info_model.dart';
import 'package:muslim/src/features/update/data/repository/update_repo.dart';

abstract class UpdateState {}

class UpdateInitial extends UpdateState {}
class UpdateLoading extends UpdateState {}
class UpdateNoNeeded extends UpdateState {}
class UpdateRequired extends UpdateState {
  final UpdateInfo updateInfo;
  UpdateRequired(this.updateInfo);
}

class UpdateCubit extends Cubit<UpdateState> {
  final UpdateRepo _repo;

  UpdateCubit(this._repo) : super(UpdateInitial());

  Future<void> checkForUpdate() async {
    emit(UpdateLoading());
    
    final updateInfo = await _repo.fetchUpdateInfo();
    
    if (updateInfo != null) {
      // ⚠️ رقم الإصدار الحالي للتطبيق - يتم تغييره يدوياً قبل أي تحديث
      const int currentAppVersion = 1; 
      
      if (_isUpdateRequired(currentAppVersion, updateInfo.latestVersion)) {
        emit(UpdateRequired(updateInfo));
        return;
      }
    }
    
    emit(UpdateNoNeeded());
  }

  bool _isUpdateRequired(int currentVersion, String latestVersionStr) {
    try {
      // تحويل رقم الإصدار القادم من السيرفر إلى رقم صحيح للمقارنة
      int latestVersion = int.parse(latestVersionStr);
      return latestVersion > currentVersion;
    } catch (e) {
      // في حالة وجود خطأ في التحويل (مثلاً لو كان النص 1.0 بدلاً من 1)
      return false;
    }
  }
}
