import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'account_secrets.dart';

/// Stable per-install identity used to name tududi API keys.
///
/// The install id is persisted in secure storage so re-login on the same
/// install reuses the same key name (and can revoke prior keys with that name).
/// Uninstall / clear-data may mint a new id; that leaves at most one orphan key.
class DeviceInstallIdentity {
  DeviceInstallIdentity({
    AccountSecrets? secrets,
    DeviceInfoPlugin? deviceInfo,
    Uuid? uuid,
  }) : _secrets = secrets ?? AccountSecrets(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _uuid = uuid ?? const Uuid();

  final AccountSecrets _secrets;
  final DeviceInfoPlugin _deviceInfo;
  final Uuid _uuid;

  Future<String> installId() async {
    final existing = await _secrets.readDeviceInstallId();
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await _secrets.saveDeviceInstallId(created);
    return created;
  }

  Future<String> deviceLabel() async {
    try {
      if (kIsWeb) return 'Web';
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return _firstNonEmpty([info.model, info.name, info.brand]) ?? 'Android';
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return _firstNonEmpty([info.modelName, info.name, info.model]) ??
            'iPhone';
      }
      if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return _firstNonEmpty([
              info.modelName,
              info.model,
              info.computerName,
            ]) ??
            'Mac';
      }
      if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return _firstNonEmpty([info.productName, info.computerName]) ??
            'Windows';
      }
      if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return _firstNonEmpty([info.prettyName, info.name]) ?? 'Linux';
      }
    } catch (_) {
      // Fall through to generic label.
    }
    return 'Device';
  }

  /// Human-readable + unique key name, e.g. `DootDoot · Pixel 8 · a1b2c3d4`.
  Future<String> apiKeyName() async {
    final label = await deviceLabel();
    final id = await installId();
    return formatApiKeyName(deviceLabel: label, installId: id);
  }

  static String formatApiKeyName({
    required String deviceLabel,
    required String installId,
  }) {
    final short = installId.replaceAll('-', '');
    final suffix = short.length >= 8 ? short.substring(0, 8) : short;
    final label = sanitizeDeviceLabel(deviceLabel);
    return 'DootDoot · $label · $suffix';
  }

  static String sanitizeDeviceLabel(String raw) {
    final collapsed = raw
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r"[^\w\s.\-+()']"), '')
        .trim();
    if (collapsed.isEmpty) return 'Device';
    if (collapsed.length <= 40) return collapsed;
    return collapsed.substring(0, 40).trimRight();
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
