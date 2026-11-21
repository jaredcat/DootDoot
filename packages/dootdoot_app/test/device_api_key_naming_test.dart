import 'package:dootdoot_app/core/accounts/device_install_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceInstallIdentity.formatApiKeyName', () {
    test('includes readable device label and short install id', () {
      expect(
        DeviceInstallIdentity.formatApiKeyName(
          deviceLabel: 'Pixel 8',
          installId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        ),
        'DootDoot · Pixel 8 · a1b2c3d4',
      );
    });

    test('sanitizes and truncates noisy labels', () {
      expect(
        DeviceInstallIdentity.sanitizeDeviceLabel("  Jared's iPhone!!!  "),
        "Jared's iPhone",
      );
      expect(DeviceInstallIdentity.sanitizeDeviceLabel(''), 'Device');
      final long = 'A' * 60;
      expect(DeviceInstallIdentity.sanitizeDeviceLabel(long).length, 40);
    });

    test('is deterministic for the same install id', () {
      const id = '11111111-2222-3333-4444-555555555555';
      final a = DeviceInstallIdentity.formatApiKeyName(
        deviceLabel: 'iPhone',
        installId: id,
      );
      final b = DeviceInstallIdentity.formatApiKeyName(
        deviceLabel: 'iPhone',
        installId: id,
      );
      expect(a, b);
      expect(a, 'DootDoot · iPhone · 11111111');
    });
  });
}
