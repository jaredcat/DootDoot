import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import 'task_list_organize.dart';

class UpcomingSortPrefsStore {
  UpcomingSortPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  String _key(String accountId) => 'dootdoot.upcomingSort.$accountId';

  UpcomingSort load(String accountId) {
    final raw = _prefs.getString(_key(accountId));
    if (raw == null || raw.isEmpty) return const UpcomingSort();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const UpcomingSort();
      final data = Map<String, dynamic>.from(map);
      final fieldName = data['field'] as String? ?? 'dueDate';
      final field = UpcomingSortField.values.firstWhere(
        (f) => f.name == fieldName,
        orElse: () => UpcomingSortField.dueDate,
      );
      return UpcomingSort(
        field: field,
        ascending: data['ascending'] as bool? ?? true,
      );
    } catch (_) {
      return const UpcomingSort();
    }
  }

  Future<void> save(String accountId, UpcomingSort value) {
    return _prefs.setString(
      _key(accountId),
      jsonEncode({
        'field': value.field.name,
        'ascending': value.ascending,
      }),
    );
  }
}

final upcomingSortProvider =
    NotifierProvider<UpcomingSortNotifier, UpcomingSort>(
  UpcomingSortNotifier.new,
);

class UpcomingSortNotifier extends Notifier<UpcomingSort> {
  @override
  UpcomingSort build() {
    final accountId = ref.watch(activeAccountIdProvider) ?? 'default';
    final prefs = ref.watch(sharedPreferencesProvider);
    return UpcomingSortPrefsStore(prefs).load(accountId);
  }

  Future<void> update(UpcomingSort value) async {
    state = value;
    final accountId = ref.read(activeAccountIdProvider) ?? 'default';
    await UpcomingSortPrefsStore(
      ref.read(sharedPreferencesProvider),
    ).save(accountId, value);
  }
}
