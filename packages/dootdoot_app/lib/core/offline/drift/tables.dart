import 'package:drift/drift.dart';

/// Cached Tududi entity row (JSON payload + sync metadata).
class CachedEntities extends Table {
  TextColumn get accountId => text()();
  TextColumn get entityType => text()(); // task|note|habit|project|area|goal
  TextColumn get uid => text()();
  TextColumn get payloadJson => text()();
  TextColumn get updatedAt => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {accountId, entityType, uid};
}

class OutboxOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get accountId => text()();
  TextColumn get entity => text()(); // task|note|habit
  TextColumn get op => text()(); // create|update|complete
  TextColumn get entityUid => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get baseJson => text().nullable()();
  TextColumn get baseUpdatedAt => text().nullable()();
  TextColumn get clientId => text()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending|conflict
  TextColumn get conflictServerJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class IdMaps extends Table {
  TextColumn get accountId => text()();
  TextColumn get localUid => text()();
  TextColumn get serverUid => text()();

  @override
  Set<Column<Object>> get primaryKey => {accountId, localUid};
}
