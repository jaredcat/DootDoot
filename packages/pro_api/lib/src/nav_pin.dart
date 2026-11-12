import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

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

  /// Outlined Material Symbol. Use `Icon(icon, fill: 1)` when selected.
  IconData get icon {
    return switch (kind) {
      NavPinKind.today => Symbols.wb_sunny,
      NavPinKind.upcoming => Symbols.calendar_view_week,
      NavPinKind.inbox => Symbols.inbox,
      NavPinKind.someday => Symbols.beach_access,
      NavPinKind.projects => Symbols.folder,
      NavPinKind.areas => Symbols.layers,
      NavPinKind.notes => Symbols.notes,
      NavPinKind.search => Symbols.search,
      NavPinKind.settings => Symbols.settings,
      NavPinKind.accounts => Symbols.switch_account,
      NavPinKind.calendar => Symbols.calendar_month,
      NavPinKind.goals => Symbols.flag,
      NavPinKind.habits => Symbols.loop,
      NavPinKind.boards => Symbols.view_kanban,
      NavPinKind.project => Symbols.folder,
      NavPinKind.area => Symbols.layers,
      NavPinKind.note => Symbols.sticky_note_2,
    };
  }

  /// Same glyph as [icon]; callers should set `Icon(..., fill: 1)` when selected.
  IconData get selectedIcon => icon;

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
