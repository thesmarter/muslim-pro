class UpdateInfo {
  final String latestVersion;
  final bool forceUpdate;
  final String message;
  final String updateUrl;

  UpdateInfo({
    required this.latestVersion,
    required this.forceUpdate,
    required this.message,
    required this.updateUrl,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: (json['latest_version'] as String?) ?? '',
      forceUpdate: (json['force_update'] as bool?) ?? false,
      message: (json['message'] as String?) ?? '',
      updateUrl: (json['update_url'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'force_update': forceUpdate,
      'message': message,
      'update_url': updateUrl,
    };
  }
}
