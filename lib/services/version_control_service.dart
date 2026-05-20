import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum VersionStatus {
  upToDate,
  softUpdate,
  hardUpdate,
}

class VersionControlResult {
  final VersionStatus status;
  final String latestVersion;
  final String minVersion;
  final String storeUrl;

  VersionControlResult({
    required this.status,
    required this.latestVersion,
    required this.minVersion,
    required this.storeUrl,
  });
}

class VersionControlService {
  static const String localAppVersion = "1.0.0"; // Local version of this app build

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches version config from Firestore `/config/version` and compares it with localAppVersion.
  Future<VersionControlResult> checkVersion() async {
    try {
      final doc = await _firestore.collection('config').doc('version').get();

      if (!doc.exists) {
        // Fallback if document doesn't exist yet
        return VersionControlResult(
          status: VersionStatus.upToDate,
          latestVersion: localAppVersion,
          minVersion: localAppVersion,
          storeUrl: "",
        );
      }

      final data = doc.data()!;
      final latestVersion = (data['current_version'] as String?) ?? localAppVersion;
      final minVersion = (data['min_version'] as String?) ?? localAppVersion;
      final storeUrl = (data['store_url'] as String?) ?? "https://play.google.com";

      final hasHardUpdate = _isVersionGreater(minVersion, localAppVersion);
      final hasSoftUpdate = _isVersionGreater(latestVersion, localAppVersion);

      VersionStatus status = VersionStatus.upToDate;
      if (hasHardUpdate) {
        status = VersionStatus.hardUpdate;
      } else if (hasSoftUpdate) {
        status = VersionStatus.softUpdate;
      }

      return VersionControlResult(
        status: status,
        latestVersion: latestVersion,
        minVersion: minVersion,
        storeUrl: storeUrl,
      );
    } catch (e) {
      debugPrint("Version check failed: $e");
      // Fallback on network failure to avoid blocking users
      return VersionControlResult(
        status: VersionStatus.upToDate,
        latestVersion: localAppVersion,
        minVersion: localAppVersion,
        storeUrl: "",
      );
    }
  }

  /// Helper to compare semantic versions: returns true if v1 > v2.
  bool _isVersionGreater(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map(int.parse).toList();
      final parts2 = v2.split('.').map(int.parse).toList();

      // Pad with zeros if short format (e.g. "1.0" -> "1.0.0")
      while (parts1.length < 3) {
        parts1.add(0);
      }
      while (parts2.length < 3) {
        parts2.add(0);
      }

      for (var i = 0; i < 3; i++) {
        if (parts1[i] > parts2[i]) {
          return true;
        } else if (parts1[i] < parts2[i]) {
          return false;
        }
      }
    } catch (_) {
      // In case of parsing error, fallback to basic string comparison
      return v1.compareTo(v2) > 0;
    }
    return false;
  }
}
