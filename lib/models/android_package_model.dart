class AndroidPackageModel {
  final String packageName;
  final String appName;
  final String versionName;
  final int installTime;
  final bool isSystemApp;
  final String iconBase64;

  AndroidPackageModel({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.installTime,
    required this.isSystemApp,
    required this.iconBase64,
  });

  factory AndroidPackageModel.fromMap(Map<String, dynamic> map) {
    return AndroidPackageModel(
      packageName: (map['packageName'] as String?) ?? '',
      appName: (map['appName'] as String?) ?? '',
      versionName: (map['versionName'] as String?) ?? '',
      installTime: (map['installTime'] as num?)?.toInt() ?? 0,
      isSystemApp: (map['isSystemApp'] as bool?) ?? false,
      iconBase64: (map['iconBase64'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'versionName': versionName,
      'installTime': installTime,
      'isSystemApp': isSystemApp,
      'iconBase64': iconBase64,
    };
  }
}
