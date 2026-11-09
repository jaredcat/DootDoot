import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';

/// Which Today sections are visible. Planned is always shown.
class TodaySectionVisibility {
  const TodaySectionVisibility({
    this.showOverdue = true,
    this.showSuggested = true,
    this.showCompleted = true,
  });

  final bool showOverdue;
  final bool showSuggested;
  final bool showCompleted;

  TodaySectionVisibility copyWith({
    bool? showOverdue,
    bool? showSuggested,
    bool? showCompleted,
  }) {
    return TodaySectionVisibility(
      showOverdue: showOverdue ?? this.showOverdue,
      showSuggested: showSuggested ?? this.showSuggested,
      showCompleted: showCompleted ?? this.showCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'showOverdue': showOverdue,
        'showSuggested': showSuggested,
        'showCompleted': showCompleted,
      };

  factory TodaySectionVisibility.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TodaySectionVisibility();
    return TodaySectionVisibility(
      showOverdue: json['showOverdue'] as bool? ?? true,
      showSuggested: json['showSuggested'] as bool? ?? true,
      showCompleted: json['showCompleted'] as bool? ?? true,
    );
  }
}

class TodaySectionPrefsStore {
  TodaySectionPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  String _key(String accountId) => 'dootdoot.todaySections.$accountId';

  TodaySectionVisibility load(String accountId) {
    final raw = _prefs.getString(_key(accountId));
    if (raw == null || raw.isEmpty) return const TodaySectionVisibility();
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return TodaySectionVisibility.fromJson(map);
      }
      if (map is Map) {
        return TodaySectionVisibility.fromJson(
          Map<String, dynamic>.from(map),
        );
      }
    } catch (_) {}
    return const TodaySectionVisibility();
  }

  Future<void> save(String accountId, TodaySectionVisibility value) {
    return _prefs.setString(_key(accountId), jsonEncode(value.toJson()));
  }
}

final todaySectionVisibilityProvider =
    NotifierProvider<TodaySectionVisibilityNotifier, TodaySectionVisibility>(
  TodaySectionVisibilityNotifier.new,
);

class TodaySectionVisibilityNotifier extends Notifier<TodaySectionVisibility> {
  @override
  TodaySectionVisibility build() {
    final accountId = ref.watch(activeAccountIdProvider) ?? 'default';
    final prefs = ref.watch(sharedPreferencesProvider);
    return TodaySectionPrefsStore(prefs).load(accountId);
  }

  Future<void> update(TodaySectionVisibility value) async {
    state = value;
    final accountId = ref.read(activeAccountIdProvider) ?? 'default';
    await TodaySectionPrefsStore(
      ref.read(sharedPreferencesProvider),
    ).save(accountId, value);
  }
}
