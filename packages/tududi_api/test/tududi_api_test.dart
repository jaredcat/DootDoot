import 'package:test/test.dart';
import 'package:tududi_api/tududi_api.dart';

void main() {
  group('TududiUrls', () {
    test('normalizes host without scheme', () {
      expect(
        TududiUrls.normalizeBaseUrl('tududi.example.com'),
        'https://tududi.example.com',
      );
    });

    test('strips trailing slash and /api', () {
      expect(
        TududiUrls.normalizeBaseUrl('https://app.tududi.com/api/'),
        'https://app.tududi.com',
      );
    });

    test('detects cloud', () {
      expect(TududiUrls.isCloud(TududiUrls.cloud), isTrue);
      expect(TududiUrls.isCloud('https://home.lan:3002'), isFalse);
    });
  });

  group('models', () {
    test('parses task json', () {
      final task = TududiTask.fromJson({
        'id': 1,
        'uid': 'abc',
        'name': 'Daily',
        'original_name': 'Walk dog',
        'status': 0,
        'priority': 'high',
        'due_date': '2026-11-08',
        'tags': [
          {'id': 2, 'name': 'home'},
        ],
      });
      expect(task.displayName, 'Walk dog');
      expect(task.tags.single.name, 'home');
      expect(task.isOpen, isTrue);
    });
  });
}
