import 'package:get_storage/get_storage.dart';
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

    List<int> arrangement = [];
    try {
      if (data == null) {
        arrangement = List.generate(tabsCount, (index) => index);
      } else if (data is List) {
        arrangement = List<int>.from(data);
      } else if (data is String) {
        if (data.isEmpty) {
          arrangement = List.generate(tabsCount, (index) => index);
        } else {
          final String cleanedData = data.replaceAll('[', '').replaceAll(']', '');
          arrangement = cleanedData
              .split(",")
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map<int>((e) => int.parse(e))
              .toList();
        }
      } else {
        arrangement = List.generate(tabsCount, (index) => index);
      }
    } catch (e) {
      arrangement = List.generate(tabsCount, (index) => index);
    }

    // Ensure all indices are present and valid
    bool needsFix = arrangement.length != tabsCount;
    
    if (!needsFix) {
      // Check if all indices from 0 to tabsCount-1 are present
      for (int i = 0; i < tabsCount; i++) {
        if (!arrangement.contains(i)) {
          needsFix = true;
          break;
        }
      }
    }

    if (needsFix) {
      // Create a set of unique valid indices
      final Set<int> validIndices = arrangement.where((i) => i >= 0 && i < tabsCount).toSet();
      
      // Add any missing indices
      for (int i = 0; i < tabsCount; i++) {
        validIndices.add(i);
      }
      
      // Create a new arrangement list
      final List<int> newArrangement = [];
      
      // First, add existing valid indices in their current order
      for (final i in arrangement) {
        if (i >= 0 && i < tabsCount && !newArrangement.contains(i)) {
          newArrangement.add(i);
        }
      }
      
      // Then, add any remaining valid indices that weren't in the original list
      for (int i = 0; i < tabsCount; i++) {
        if (!newArrangement.contains(i)) {
          newArrangement.add(i);
        }
      }
      
      arrangement = newArrangement;
      
      // Save the fixed arrangement back to storage
      changeDashboardArrangement(arrangement);
    }

    return arrangement;
  }

  void changeDashboardArrangement(List<int> value) {
    box.write(dashboardArrangementKey, value.join(","));
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
