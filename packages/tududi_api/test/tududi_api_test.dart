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
    test('parses api key list and create payloads', () {
      final listed = ApiKeyInfo.fromJson({
        'id': 9,
        'name': 'DootDoot · Pixel 8 · a1b2c3d4',
        'token_prefix': 'tt_6f654c53c',
        'created_at': '2026-11-12T14:38:10Z',
        'last_used_at': null,
        'expires_at': null,
        'revoked_at': null,
      });
      expect(listed.id, 9);
      expect(listed.isActive, isTrue);
      expect(listed.tokenPrefix, 'tt_6f654c53c');

      final created = ApiKeyCreated.fromJson({
        'token': 'tt_abc',
        'apiKey': {
          'id': 10,
          'name': 'DootDoot · Pixel 8 · a1b2c3d4',
          'token_prefix': 'tt_abc',
        },
      });
      expect(created.token, 'tt_abc');
      expect(created.id, 10);
      expect(created.name, 'DootDoot · Pixel 8 · a1b2c3d4');
    });

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
      expect(task.toPatchJson()['name'], 'Walk dog');
      expect(task.toCreateJson()['name'], 'Walk dog');
    });

    test('formats project state labels', () {
      expect(ProjectState.label('not_started'), 'Not started');
      expect(ProjectState.label('in_progress'), 'In progress');
      expect(ProjectState.label('planned'), 'Planned');
      expect(ProjectState.label(null), '');
    });
  });
}
