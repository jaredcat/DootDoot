import 'package:flutter/material.dart';

/// Built-in or entity shortcut that can appear on the Pro custom bottom bar.
enum NavPinKind {
  today,
  upcoming,
  inbox,
  someday,
  projects,
  areas,
  notes,
  search,
  settings,
  accounts,
  calendar,
  goals,
  habits,
  boards,
  project,
  area,
  note,
}

class NavPin {
  const NavPin({
    required this.id,
    required this.kind,
    required this.label,
    this.entityUid,
  });

  /// Stable id used in routes (`/tab/{id}`).
  final String id;
  final NavPinKind kind;
  final String label;
  final String? entityUid;

  bool get isTaskList =>
      kind == NavPinKind.today ||
      kind == NavPinKind.upcoming ||
      kind == NavPinKind.inbox ||
      kind == NavPinKind.someday;

  bool get isEntity =>
      kind == NavPinKind.project ||
      kind == NavPinKind.area ||
      kind == NavPinKind.note;

  IconData get icon {
    return switch (kind) {
      NavPinKind.today => Icons.wb_sunny_outlined,
      NavPinKind.upcoming => Icons.calendar_view_week_outlined,
      NavPinKind.inbox => Icons.inbox_outlined,
      NavPinKind.someday => Icons.beach_access_outlined,
      NavPinKind.projects => Icons.folder_outlined,
      NavPinKind.areas => Icons.layers_outlined,
      NavPinKind.notes => Icons.notes_outlined,
      NavPinKind.search => Icons.search,
      NavPinKind.settings => Icons.settings_outlined,
      NavPinKind.accounts => Icons.switch_account_outlined,
      NavPinKind.calendar => Icons.calendar_month_outlined,
      NavPinKind.goals => Icons.flag_outlined,
      NavPinKind.habits => Icons.loop,
      NavPinKind.boards => Icons.view_kanban_outlined,
      NavPinKind.project => Icons.folder,
      NavPinKind.area => Icons.layers,
      NavPinKind.note => Icons.sticky_note_2_outlined,
    };
  }

  IconData get selectedIcon {
    return switch (kind) {
      NavPinKind.today => Icons.wb_sunny,
      NavPinKind.upcoming => Icons.calendar_view_week,
      NavPinKind.inbox => Icons.inbox,
      NavPinKind.someday => Icons.beach_access,
      NavPinKind.projects => Icons.folder,
      NavPinKind.areas => Icons.layers,
      NavPinKind.notes => Icons.notes,
      NavPinKind.search => Icons.search,
      NavPinKind.settings => Icons.settings,
      NavPinKind.accounts => Icons.switch_account,
      NavPinKind.calendar => Icons.calendar_month,
      NavPinKind.goals => Icons.flag,
      NavPinKind.habits => Icons.loop,
      NavPinKind.boards => Icons.view_kanban,
      NavPinKind.project => Icons.folder,
      NavPinKind.area => Icons.layers,
      NavPinKind.note => Icons.sticky_note_2,
    };
  }

  /// Routes under `/more` that this pin duplicates when pinned.
  String? get moreRouteToHide {
    return switch (kind) {
      NavPinKind.projects => '/more/projects',
      NavPinKind.areas => '/more/areas',
      NavPinKind.notes => '/more/notes',
      NavPinKind.search => '/more/search',
      NavPinKind.settings => '/more/settings',
      NavPinKind.accounts => '/more/accounts',
      NavPinKind.calendar => '/more/calendar',
      NavPinKind.goals => '/more/goals',
      NavPinKind.habits => '/more/habits',
      NavPinKind.boards => '/more/boards',
      NavPinKind.project =>
        entityUid != null ? '/more/projects/$entityUid' : null,
      NavPinKind.area => entityUid != null ? '/more/areas/$entityUid' : null,
      NavPinKind.note => entityUid != null ? '/more/notes/$entityUid' : null,
      _ => null,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'label': label,
        if (entityUid != null) 'entityUid': entityUid,
      };

  factory NavPin.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'today';
    final kind = NavPinKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => NavPinKind.today,
    );
    return NavPin(
      id: json['id'] as String? ?? kind.name,
      kind: kind,
      label: json['label'] as String? ?? kind.name,
      entityUid: json['entityUid'] as String?,
    );
  }

  NavPin copyWith({String? label}) {
    return NavPin(
      id: id,
      kind: kind,
      label: label ?? this.label,
      entityUid: entityUid,
    );
  }

  /// Default pins matching the free bottom bar (without More).
  static List<NavPin> defaults() => const [
        NavPin(id: 'today', kind: NavPinKind.today, label: 'Today'),
        NavPin(id: 'upcoming', kind: NavPinKind.upcoming, label: 'Upcoming'),
        NavPin(id: 'inbox', kind: NavPinKind.inbox, label: 'Inbox'),
      ];

  static const maxPins = 5;
}
