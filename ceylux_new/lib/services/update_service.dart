import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String? downloadUrl;
  final String? changelog;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    this.downloadUrl,
    this.changelog,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;
  UpdateService._();

  static const String githubRepo = 'perpova/Ceylux-App';
  static const String apiUrl = 'https://api.github.com/repos/$githubRepo/releases/latest';
  static const String _lastInstalledVersionKey = 'last_installed_version';
  static const String _pendingUpdateVersionKey = 'pending_update_version';
  static const String _updateAttemptCountKey = 'update_attempt_count';

  /// Helper to compare two version strings. Supports semantic version comparison
  /// and build number comparison if a '+' separator is present.
  bool _isNewerVersion(String currentVersion, String currentBuild, String remoteTag) {
    // Strip starting 'v' or 'V' if any
    String remote = remoteTag.toLowerCase().startsWith('v') ? remoteTag.substring(1) : remoteTag;
    String local = currentVersion.toLowerCase().startsWith('v') ? currentVersion.substring(1) : currentVersion;

    List<String> remoteSplit = remote.split('+');
    List<String> localSplit = local.split('+');

    String remoteVer = remoteSplit[0];
    String localVer = localSplit[0];

    String remoteBuild = remoteSplit.length > 1 ? remoteSplit[1] : '';
    String localBuild = localSplit.length > 1 ? localSplit[1] : currentBuild;

    List<String> rParts = remoteVer.split('.');
    List<String> lParts = localVer.split('.');
    int maxLen = rParts.length > lParts.length ? rParts.length : lParts.length;

    for (int i = 0; i < maxLen; i++) {
      int rNum = i < rParts.length ? int.tryParse(rParts[i]) ?? 0 : 0;
      int lNum = i < lParts.length ? int.tryParse(lParts[i]) ?? 0 : 0;
      
      if (rNum > lNum) return true;
      if (lNum > rNum) return false;
    }

    if (remoteBuild.isNotEmpty) {
      int rBuildNum = int.tryParse(remoteBuild) ?? 0;
      int lBuildNum = int.tryParse(localBuild) ?? 0;
      return rBuildNum > lBuildNum;
    }

    return false;
  }

  /// Checks if a new release is available on GitHub.
  Future<UpdateInfo> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'CeyluxAppUpdater',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return UpdateInfo(hasUpdate: false, latestVersion: '');
      }

      final Map<String, dynamic> release = jsonDecode(response.body);
      final String remoteTag = release['tag_name'] ?? '';
      final String changelog = release['body'] ?? 'No changelog provided.';
      final List<dynamic> assets = release['assets'] ?? [];

      String? downloadUrl;
      for (var asset in assets) {
        final String assetName = asset['name'] ?? '';
        if (assetName.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'];
          break;
        }
      }

      if (remoteTag.isEmpty || downloadUrl == null) {
        return UpdateInfo(hasUpdate: false, latestVersion: '');
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String currentBuild = packageInfo.buildNumber;

      final bool hasUpdate = _isNewerVersion(currentVersion, currentBuild, remoteTag);

      return UpdateInfo(
        hasUpdate: hasUpdate,
        latestVersion: remoteTag,
        downloadUrl: downloadUrl,
        changelog: changelog,
      );
    } catch (_) {
      // In case of error (e.g. no internet), assume no update to allow the user to proceed.
      return UpdateInfo(hasUpdate: false, latestVersion: '');
    }
  }

  /// Triggers the OTA update process.
  Stream<OtaEvent> startOtaUpdate(String downloadUrl) {
    return OtaUpdate().execute(
      downloadUrl,
      destinationFilename: 'ceylux_update.apk',
    );
  }

  /// Save that an update has been started for tracking purposes.
  Future<void> markUpdateStarted(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingUpdateVersionKey, version);
  }

  /// Mark update as completed (successfully installed).
  Future<void> markUpdateInstalled(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastInstalledVersionKey, version);
    await prefs.remove(_pendingUpdateVersionKey);
    await prefs.setInt(_updateAttemptCountKey, 0);
  }

  /// Get the last installed version to skip re-showing the same update.
  Future<String?> getLastInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastInstalledVersionKey);
  }

  /// Get pending update version that was attempted.
  Future<String?> getPendingUpdateVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingUpdateVersionKey);
  }

  /// Increment update attempt count for this version.
  Future<int> incrementUpdateAttemptCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_updateAttemptCountKey) ?? 0;
    count++;
    await prefs.setInt(_updateAttemptCountKey, count);
    return count;
  }

  /// Reset update attempt count.
  Future<void> resetUpdateAttemptCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_updateAttemptCountKey, 0);
  }

  /// Check if we should skip this update (already tried or installed).
  Future<bool> shouldSkipUpdate(String remoteVersion) async {
    final lastInstalled = await getLastInstalledVersion();
    final pending = await getPendingUpdateVersion();
    
    // Skip if this exact version was already installed
    if (lastInstalled == remoteVersion) {
      return true;
    }
    
    // Skip if this version is still pending (installation in progress or failed)
    if (pending == remoteVersion) {
      final attemptCount = (await SharedPreferences.getInstance()).getInt(_updateAttemptCountKey) ?? 0;
      // Allow up to 2 attempts per version, then skip
      if (attemptCount >= 2) {
        return true;
      }
    }
    
    return false;
  }
}
