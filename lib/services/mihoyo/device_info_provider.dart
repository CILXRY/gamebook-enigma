import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoProvider {
  static const _overrideKey = 'ext_fields_override';

  static Future<String?> loadOverride() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_overrideKey);
  }

  static Future<void> saveOverride(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_overrideKey, json);
  }

  static Future<void> clearOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_overrideKey);
  }

  static Future<Map<String, dynamic>> collect() async {
    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      try {
        return _collectAndroid(await plugin.androidInfo);
      } catch (_) {
        return _collectAndroidDefaults();
      }
    }

    if (Platform.isIOS) {
      try {
        return _collectIOS(await plugin.iosInfo);
      } catch (_) {
        return _collectIOSDefaults();
      }
    }

    return _collectDesktop(plugin);
  }

  static String _parseOsVersion() {
    final raw = Platform.operatingSystemVersion;
    final match = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(raw);
    if (match != null) return match.group(1)!;
    return raw;
  }

  static String _hostname() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'unknown';
    }
  }

  static Map<String, dynamic> _collectAndroid(AndroidDeviceInfo info) {
    return <String, dynamic>{
      'proxyStatus': 0,
      'isRoot': 0,
      'romCapacity': '512',
      'deviceName': info.model,
      'productName': info.product,
      'romRemain': '512',
      'hostname': info.host,
      'screenSize': '1080x2400',
      'isTablet': 0,
      'aaid': '',
      'model': info.model,
      'brand': info.brand,
      'hardware': info.hardware,
      'deviceType': info.device,
      'devId': info.id,
      'serialNumber': info.serialNumber,
      'sdCapacity': 125943,
      'buildTime': '1704316741000',
      'buildUser': 'cloudtest',
      'simState': 0,
      'ramRemain': '124603',
      'appUpdateTimeDiff': DateTime.now().millisecondsSinceEpoch,
      'deviceInfo': info.fingerprint,
      'vaid': '',
      'buildType': info.type,
      'sdkVersion': info.version.sdkInt.toString(),
      'ui_mode': 'UI_MODE_TYPE_NORMAL',
      'isMockLocation': 0,
      'cpuType': _getCpuType(info),
      'isAirMode': 0,
      'ringMode': 2,
      'chargeStatus': 3,
      'manufacturer': info.manufacturer,
      'emulatorStatus': info.isPhysicalDevice ? 0 : 1,
      'appMemory': '512',
      'osVersion': info.version.release,
      'vendor': 'unknown',
      'accelerometer': '',
      'sdRemain': 123276,
      'buildTags': info.tags,
      'packageName': 'com.mihoyo.hyperion',
      'networkType': 'WiFi',
      'oaid': '',
      'debugStatus': 1,
      'ramCapacity': '125943',
      'magnetometer': '',
      'display': info.display,
      'appInstallTimeDiff': DateTime.now().millisecondsSinceEpoch,
      'packageVersion': '2.20.2',
      'gyroscope': '',
      'batteryStatus': 85,
      'hasKeyboard': 10,
      'board': info.board,
    };
  }

  static String _getCpuType(AndroidDeviceInfo info) {
    final abis = info.supported64BitAbis;
    if (abis.isNotEmpty) return abis.first;
    final abis32 = info.supported32BitAbis;
    if (abis32.isNotEmpty) return abis32.first;
    return 'arm64-v8a';
  }

  static Map<String, dynamic> _collectAndroidDefaults() {
    return <String, dynamic>{
      'proxyStatus': 0,
      'isRoot': 0,
      'romCapacity': '512',
      'deviceName': 'Pixel5',
      'productName': 'redfin',
      'romRemain': '512',
      'hostname': _hostname(),
      'screenSize': '1080x2400',
      'isTablet': 0,
      'aaid': '',
      'model': 'Pixel5',
      'brand': 'google',
      'hardware': 'qcom',
      'deviceType': 'redfin',
      'devId': 'REL',
      'serialNumber': 'unknown',
      'sdCapacity': 125943,
      'buildTime': '1704316741000',
      'buildUser': 'cloudtest',
      'simState': 0,
      'ramRemain': '124603',
      'appUpdateTimeDiff': DateTime.now().millisecondsSinceEpoch,
      'deviceInfo':
          'google/redfin/redfin:13/TQ3A.230901.001/2311.40000.5.0:user/release-keys',
      'vaid': '',
      'buildType': 'user',
      'sdkVersion': '33',
      'ui_mode': 'UI_MODE_TYPE_NORMAL',
      'isMockLocation': 0,
      'cpuType': 'arm64-v8a',
      'isAirMode': 0,
      'ringMode': 2,
      'chargeStatus': 3,
      'manufacturer': 'Google',
      'emulatorStatus': 0,
      'appMemory': '512',
      'osVersion': _parseOsVersion(),
      'vendor': 'unknown',
      'accelerometer': '',
      'sdRemain': 123276,
      'buildTags': 'release-keys',
      'packageName': 'com.mihoyo.hyperion',
      'networkType': 'WiFi',
      'oaid': '',
      'debugStatus': 1,
      'ramCapacity': '125943',
      'magnetometer': '',
      'display': 'TQ3A.230901.001',
      'appInstallTimeDiff': DateTime.now().millisecondsSinceEpoch,
      'packageVersion': '2.20.2',
      'gyroscope': '',
      'batteryStatus': 85,
      'hasKeyboard': 10,
      'board': 'windows',
    };
  }

  static Map<String, dynamic> _collectIOS(IosDeviceInfo info) {
    return <String, dynamic>{
      'ramCapacity': '3746',
      'hasVpn': '0',
      'proxyStatus': '0',
      'screenBrightness': '0.550',
      'packageName': 'com.miHoYo.mhybbs',
      'romRemain': '100513',
      'deviceName': info.name,
      'isJailBreak': '0',
      'magnetometer': '-160.495300x-206.488358x58.534348',
      'buildTime': '1706406805675',
      'ramRemain': '97',
      'accelerometer': '-0.419876x-0.748367x-0.508057',
      'cpuCores': Platform.numberOfProcessors.toString(),
      'cpuType': 'CPU_TYPE_ARM64',
      'packageVersion': '2.20.1',
      'gyroscope': '0.133974x-0.051780x-0.062961',
      'batteryStatus': '45',
      'appUpdateTimeDiff': '1707130080397',
      'appMemory': '57',
      'screenSize': '414×896',
      'vendor': '--',
      'model': info.model,
      'IDFV': info.identifierForVendor ?? '',
      'romCapacity': '488153',
      'isPushEnabled': '1',
      'appInstallTimeDiff': '1696756955347',
      'osVersion': info.systemVersion,
      'chargeStatus': '1',
      'isSimInserted': '1',
      'networkType': 'WIFI',
    };
  }

  static Map<String, dynamic> _collectIOSDefaults() {
    return <String, dynamic>{
      'ramCapacity': '3746',
      'hasVpn': '0',
      'proxyStatus': '0',
      'screenBrightness': '0.550',
      'packageName': 'com.miHoYo.mhybbs',
      'romRemain': '100513',
      'deviceName': 'iPhone',
      'isJailBreak': '0',
      'magnetometer': '-160.495300x-206.488358x58.534348',
      'buildTime': '1706406805675',
      'ramRemain': '97',
      'accelerometer': '-0.419876x-0.748367x-0.508057',
      'cpuCores': Platform.numberOfProcessors.toString(),
      'cpuType': 'CPU_TYPE_ARM64',
      'packageVersion': '2.20.1',
      'gyroscope': '0.133974x-0.051780x-0.062961',
      'batteryStatus': '45',
      'appUpdateTimeDiff': '1707130080397',
      'appMemory': '57',
      'screenSize': '414×896',
      'vendor': '--',
      'model': 'iPhone12,5',
      'IDFV': '',
      'romCapacity': '488153',
      'isPushEnabled': '1',
      'appInstallTimeDiff': '1696756955347',
      'osVersion': _parseOsVersion(),
      'chargeStatus': '1',
      'isSimInserted': '1',
      'networkType': 'WIFI',
    };
  }

  static Future<Map<String, dynamic>> _collectDesktop(
    DeviceInfoPlugin plugin,
  ) async {
    final os = Platform.operatingSystem;
    try {
      if (os == 'macos') {
        final info = await plugin.macOsInfo;
        return _buildDesktopFields(
          deviceName: info.computerName,
          hostname: info.hostName,
          model: info.model,
          osVersion: info.osRelease,
          ramCapacity: (info.memorySize ~/ (1024 * 1024)).toString(),
          ramRemain: (info.memorySize ~/ (1024 * 1024)).toString(),
          board: info.arch,
          brand: info.model,
          manufacturer: 'Apple',
          hardware: info.arch,
          cpuType: info.arch,
          deviceType: info.model,
        );
      }
      if (os == 'windows') {
        final info = await plugin.windowsInfo;
        return _buildDesktopFields(
          deviceName: info.computerName,
          osVersion:
              '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}',
          ramCapacity: info.systemMemoryInMegabytes.toString(),
          ramRemain: info.systemMemoryInMegabytes.toString(),
        );
      }
      if (os == 'linux') {
        final info = await plugin.linuxInfo;
        return _buildDesktopFields(
          deviceName: info.name,
          hostname: info.name,
          osVersion: info.versionId ?? '',
          board: info.machineId ?? '',
        );
      }
    } catch (_) {}

    return _collectAndroidDefaults();
  }

  static Map<String, dynamic> _buildDesktopFields({
    required String deviceName,
    String? hostname,
    String? model,
    String osVersion = 'unknown',
    String ramCapacity = '4096',
    String ramRemain = '2048',
    String board = 'unknown',
    String brand = 'unknown',
    String manufacturer = 'unknown',
    String hardware = 'unknown',
    String cpuType = 'unknown',
    String deviceType = 'unknown',
  }) {
    return <String, dynamic>{
      'proxyStatus': 0,
      'isRoot': 0,
      'romCapacity': '512',
      'deviceName': deviceName,
      'productName': model ?? deviceName,
      'romRemain': '512',
      'hostname': hostname ?? deviceName,
      'screenSize': '1920x1080',
      'isTablet': 0,
      'aaid': '',
      'model': model ?? deviceName,
      'brand': brand,
      'hardware': hardware,
      'deviceType': deviceType,
      'devId': 'REL',
      'serialNumber': 'unknown',
      'sdCapacity': 256000,
      'buildTime': '1704316741000',
      'buildUser': manufacturer,
      'simState': 0,
      'ramRemain': ramRemain,
      'appUpdateTimeDiff': DateTime.now().millisecondsSinceEpoch,
      'deviceInfo': '$manufacturer/$deviceType/$deviceType:$osVersion',
      'vaid': '',
      'buildType': 'user',
      'sdkVersion': '33',
      'ui_mode': 'UI_MODE_TYPE_NORMAL',
      'isMockLocation': 0,
      'cpuType': cpuType,
      'isAirMode': 0,
      'ringMode': 2,
      'chargeStatus': 3,
      'manufacturer': manufacturer,
      'emulatorStatus': 0,
      'appMemory': '512',
      'osVersion': osVersion,
      'vendor': 'unknown',
      'accelerometer': '',
      'sdRemain': 256000,
      'buildTags': 'release-keys',
      'packageName': 'com.mihoyo.hyperion',
      'networkType': 'WiFi',
      'oaid': '',
      'debugStatus': 1,
      'ramCapacity': ramCapacity,
      'magnetometer': '',
      'display': osVersion,
      'appInstallTimeDiff': DateTime.now().millisecondsSinceEpoch,
      'packageVersion': '2.20.2',
      'gyroscope': '',
      'batteryStatus': 100,
      'hasKeyboard': 10,
      'board': board,
    };
  }
}
