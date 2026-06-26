import 'package:get_storage/get_storage.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/data/models/titles_freq_enum.dart';

class AppSettingsRepo {
  final GetStorage box;

  AppSettingsRepo(this.box);

  ///MARK:Release First open
  /* ******* is first open to this release ******* */

  static const _currentVersion = "currentVersion";
  String get currentVersion => box.read(_currentVersion) ?? "";

  Future<void> changCurrentVersion({required String value}) async {
    await box.write(_currentVersion, value);
  }

  ///MARK:Azkar Read Mode
  /* ******* Azkar Read Mode ******* */
  static const isCardReadModeKey = 'is_card_read_mode';

  /// get Zikr Page mode
  /// If it is true then
  /// page mode will be card mode
  /// if not page mode will be page
  bool get isCardReadMode => box.read(isCardReadModeKey) ?? false;

  /// set Zikr Page mode
  /// If it is true then
  /// page mode will be card mode
  /// if not page mode will be page
  Future<void> changeReadModeStatus({required bool value}) => box.write(isCardReadModeKey, value);

  ///
  void toggleReadModeStatus() {
    changeReadModeStatus(value: !isCardReadMode);
  }

  ///MARK:Hinidi Digits
  /* ******* Hinidi Digits ******* */

  static const String _useHindiDigitsKey = "useHindiDigits";
  bool get useHindiDigits => box.read(_useHindiDigitsKey) ?? false;

  Future<void> changeUseHindiDigits({required bool use}) async =>
      await box.write(_useHindiDigitsKey, use);

  Future toggleUseHindiDigits() async {
    await changeUseHindiDigits(use: !useHindiDigits);
  }

  ///MARK:WakeLock
  /* ******* WakeLock ******* */

  static const String _enableWakeLockKey = "enableWakeLock";
  bool get enableWakeLock => box.read(_enableWakeLockKey) ?? false;

  Future<void> changeEnableWakeLock({required bool use}) => box.write(_enableWakeLockKey, use);

  void toggleEnableWakeLock() {
    changeEnableWakeLock(use: !enableWakeLock);
  }

  ///MARK:Dashboard Arrangement
  /* ******* Dashboard Arrangement ******* */

  static const String dashboardArrangementKey = "list_arrange";

  List<int> getDashboardArrangement(int tabsCount) {
    final dynamic data = box.read(dashboardArrangementKey);

    List<String> savedIds = [];
    try {
      if (data is String) {
        if (data.isNotEmpty) {
          final String cleanedData = data.replaceAll('[', '').replaceAll(']', '');
          savedIds = cleanedData
              .split(",")
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (data is List) {
        savedIds = data.map((e) => e.toString().trim()).toList();
      }
    } catch (e) {
      savedIds = [];
    }

    // Check if the stored layout is in the old integer format
    final bool isOldFormat = savedIds.isNotEmpty && savedIds.every((id) => int.tryParse(id) != null);

    if (isOldFormat) {
      // Map old numeric indices to new stable string IDs
      final int oldLength = savedIds.length;
      final List<String> migratedIds = [];
      for (final idStr in savedIds) {
        final int? index = int.tryParse(idStr);
        if (index != null) {
          migratedIds.add(_mapOldIndexToId(index, oldLength));
        }
      }
      savedIds = migratedIds;
    }

    // Resolve saved IDs to current indices of appDashboardTabs
    final List<int> arrangement = [];
    for (final id in savedIds) {
      final int index = appDashboardTabs.indexWhere((tab) => tab.id == id);
      if (index != -1 && !arrangement.contains(index)) {
        arrangement.add(index);
      }
    }

    // Check if we need to fix the list (either missing new tabs or has mismatch)
    bool needsFix = arrangement.length != appDashboardTabs.length;
    if (!needsFix) {
      for (int i = 0; i < appDashboardTabs.length; i++) {
        if (!arrangement.contains(i)) {
          needsFix = true;
          break;
        }
      }
    }

    if (needsFix) {
      // Append any missing tab indices in their default order
      for (int i = 0; i < appDashboardTabs.length; i++) {
        if (!arrangement.contains(i)) {
          arrangement.add(i);
        }
      }
      
      // Save the cleaned/updated ID layout back to storage
      changeDashboardArrangement(arrangement);
    }

    return arrangement;
  }

  String _mapOldIndexToId(int index, int totalCount) {
    if (totalCount == 3) {
      if (index == 0) return 'index';
      if (index == 1) return 'favorites_content';
      if (index == 2) return 'favorites_zikr';
    } else if (totalCount == 4) {
      if (index == 0) return 'index';
      if (index == 1) return 'quran';
      if (index == 2) return 'favorites_content';
      if (index == 3) return 'favorites_zikr';
    } else if (totalCount == 5) {
      // Upgrading from Stage 3 (where prayer_times was at index 1, quran at index 2)
      if (index == 0) return 'index';
      if (index == 1) return 'prayer_times';
      if (index == 2) return 'quran';
      if (index == 3) return 'favorites_content';
      if (index == 4) return 'favorites_zikr';
    }
    
    // Fallback/Default Stage 4 mapping
    if (index == 0) return 'index';
    if (index == 1) return 'favorites_content';
    if (index == 2) return 'favorites_zikr';
    if (index == 3) return 'quran';
    if (index == 4) return 'prayer_times';
    return 'index';
  }

  void changeDashboardArrangement(List<int> value) {
    final List<String> ids = value.map((index) {
      if (index >= 0 && index < appDashboardTabs.length) {
        return appDashboardTabs[index].id;
      }
      return '';
    }).where((id) => id.isNotEmpty).toList();

    box.write(dashboardArrangementKey, ids.join(","));
  }

  ///MARK:Azkar Read Mode
  /* ******* Azkar Read Mode ******* */
  static const praiseWithVolumeKeysKey = 'praiseWithVolumeKeys';

  bool get praiseWithVolumeKeys => box.read(praiseWithVolumeKeysKey) ?? true;

  Future<void> changePraiseWithVolumeKeysStatus({required bool value}) =>
      box.write(praiseWithVolumeKeysKey, value);

  ///MARK:Ignore Notification Permission
  /* ******* Ignore Notification Permission ******* */
  static const ignoreNotificationPermissionKey = 'ignoreNotificationPermission';

  bool get ignoreNotificationPermission => box.read(ignoreNotificationPermissionKey) ?? false;

  Future<void> changeIgnoreNotificationPermissionStatus({
    required bool value,
  }) => box.write(ignoreNotificationPermissionKey, value);

  ///MARK:Titles Freq filters
  /* ******* Titles Freq filters ******* */
  static const String _titlesFreqFilter = "titlesFreqFilter";

  List<TitlesFreqEnum> get getTitlesFreqFilterStatus {
    final String? data = box.read(_titlesFreqFilter);

    final List<TitlesFreqEnum> result = List.of([]);
    if (data != null && data.isNotEmpty) {
      result.addAll(result.toEnumList(data));
    } else {
      result.addAll(TitlesFreqEnum.values);
    }

    return result;
  }

  Future setTitlesFreqFilterStatus(List<TitlesFreqEnum> freqList) {
    return box.write(_titlesFreqFilter, freqList.toJson());
  }

  ///MARK:Show Audio Bar
  /* ******* Show Audio Bar ******* */
  static const showAudioBarKey = 'showAudioBar';

  bool get showAudioBar => box.read(showAudioBarKey) ?? true;

  Future<void> changeShowAudioBarStatus({required bool value}) => box.write(showAudioBarKey, value);

}
