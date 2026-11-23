import 'package:dio/dio.dart';

import '../errors.dart';
import '../models/models.dart';

typedef JsonMap = Map<String, dynamic>;

/// REST client for one Tududi server (Cloud or self-hosted).
class TududiClient {
  TududiClient({required this.dio, required this.baseUrl});

  final Dio dio;
  final String baseUrl;

  // --- Auth ---

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/api/login', {
      'email': email,
      'password': password,
    });
    return LoginResult.fromJson(_asMap(data));
  }

  Future<void> logout() async {
    try {
      await dio.get<dynamic>('/api/logout');
    } catch (_) {
      // Best-effort.
    }
  }

  Future<TududiUser> currentUser() async {
    final data = await _get('/api/current_user');
    final map = _asMap(data);
    if (map['user'] is Map) {
      return TududiUser.fromJson(Map<String, dynamic>.from(map['user'] as Map));
    }
    return TududiUser.fromJson(map);
  }

  Future<String> fetchCsrfToken() async {
    final data = await _get('/api/csrf-token');
    final map = _asMap(data);
    return (map['csrfToken'] ?? map['csrf_token'] ?? map['token'] ?? '')
        .toString();
  }

  /// Creates a personal API token (prefer Bearer auth on mobile to avoid CSRF).
  Future<ApiKeyCreated> createApiKey({
    String name = 'DootDoot',
    String? expiresAt,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (expiresAt != null) body['expires_at'] = expiresAt;
    final data = await _post('/api/profile/api-keys', body);
    return ApiKeyCreated.fromJson(_asMap(data));
  }

  /// Lists personal API keys (metadata only; full tokens are never returned).
  Future<List<ApiKeyInfo>> listApiKeys() async {
    final data = await _get('/api/profile/api-keys');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ApiKeyInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return _parseList(data, ApiKeyInfo.fromJson);
  }

  /// Soft-revokes a personal API key. Cannot be undone.
  Future<ApiKeyInfo> revokeApiKey(int id) async {
    final data = await _post('/api/profile/api-keys/$id/revoke', const {});
    return ApiKeyInfo.fromJson(_asMap(data));
  }

  /// Permanently deletes a personal API key.
  Future<void> deleteApiKey(int id) async {
    await _delete('/api/profile/api-keys/$id');
  }

  Future<Map<String, dynamic>> probeServer() async {
    try {
      final data = await _get('/api/version');
      return _asMap(data);
    } on TududiApiException {
      rethrow;
    } catch (e) {
      throw TududiUnsupportedServerException(
        'Could not reach tududi at $baseUrl',
      );
    }
  }

  // --- Tasks ---

  Future<List<TududiTask>> listTasks({
    String? type,
    String? status,
    int? projectId,
    String? projectUid,
    String? areaUid,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'type': ?type,
      'status': ?status,
      'project_id': ?projectId,
      'project_uid': ?projectUid,
      'area_uid': ?areaUid,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final data = await _get('/api/tasks', query: query);
    return _parseList(data, TududiTask.fromJson);
  }

  Future<TududiTask> getTask(String uid) async {
    final data = await _get('/api/task/$uid');
    return TududiTask.fromJson(_unwrapEntity(_asMap(data), 'task'));
  }

  Future<TududiTask> createTask(Map<String, dynamic> body) async {
    final data = await _post('/api/task', body);
    return TududiTask.fromJson(_unwrapEntity(_asMap(data), 'task'));
  }

  Future<TududiTask> updateTask(String uid, Map<String, dynamic> body) async {
    final data = await _patch('/api/task/$uid', body);
    return TududiTask.fromJson(_unwrapEntity(_asMap(data), 'task'));
  }

  Future<void> deleteTask(String uid) async {
    await _delete('/api/task/$uid');
  }

  Future<TududiTask> completeTask(
    String uid, {
    bool done = true,
    int? restoreStatus,
  }) {
    return updateTask(uid, {
      'status': done
          ? TaskStatus.done
          : (restoreStatus ?? TaskStatus.notStarted),
    });
  }

  // --- Projects ---

  Future<List<TududiProject>> listProjects() async {
    final data = await _get('/api/projects');
    return _parseList(data, TududiProject.fromJson);
  }

  Future<TududiProject> getProject(String uid) async {
    final data = await _get('/api/project/$uid');
    return TududiProject.fromJson(_unwrapEntity(_asMap(data), 'project'));
  }

  Future<TududiProject> createProject(Map<String, dynamic> body) async {
    final data = await _post('/api/project', body);
    return TududiProject.fromJson(_unwrapEntity(_asMap(data), 'project'));
  }

  Future<TududiProject> updateProject(
    String uid,
    Map<String, dynamic> body,
  ) async {
    final data = await _patch('/api/project/$uid', body);
    return TududiProject.fromJson(_unwrapEntity(_asMap(data), 'project'));
  }

  Future<void> deleteProject(String uid) async {
    await _delete('/api/project/$uid');
  }

  // --- Areas ---

  Future<List<TududiArea>> listAreas() async {
    final data = await _get('/api/areas');
    return _parseList(data, TududiArea.fromJson);
  }

  Future<TududiArea> createArea(Map<String, dynamic> body) async {
    final data = await _post('/api/area', body);
    return TududiArea.fromJson(_unwrapEntity(_asMap(data), 'area'));
  }

  Future<TududiArea> updateArea(String uid, Map<String, dynamic> body) async {
    final data = await _patch('/api/area/$uid', body);
    return TududiArea.fromJson(_unwrapEntity(_asMap(data), 'area'));
  }

  Future<void> deleteArea(String uid) async {
    await _delete('/api/area/$uid');
  }

  // --- Notes ---

  Future<List<TududiNote>> listNotes() async {
    final data = await _get('/api/notes');
    return _parseList(data, TududiNote.fromJson);
  }

  Future<TududiNote> getNote(String uid) async {
    final data = await _get('/api/note/$uid');
    return TududiNote.fromJson(_unwrapEntity(_asMap(data), 'note'));
  }

  Future<TududiNote> createNote(Map<String, dynamic> body) async {
    final data = await _post('/api/note', body);
    return TududiNote.fromJson(_unwrapEntity(_asMap(data), 'note'));
  }

  Future<TududiNote> updateNote(String uid, Map<String, dynamic> body) async {
    final data = await _patch('/api/note/$uid', body);
    return TududiNote.fromJson(_unwrapEntity(_asMap(data), 'note'));
  }

  Future<void> deleteNote(String uid) async {
    await _delete('/api/note/$uid');
  }

  // --- Tags ---

  Future<List<TududiTag>> listTags() async {
    final data = await _get('/api/tags');
    return _parseList(data, TududiTag.fromJson);
  }

  // --- Search ---

  Future<Map<String, dynamic>> search(
    String query, {
    String? priority,
    String? due,
    String? defer,
    List<String>? tags,
  }) async {
    final params = <String, dynamic>{'q': query};
    if (priority != null && priority.isNotEmpty) params['priority'] = priority;
    if (due != null && due.isNotEmpty) params['due'] = due;
    if (defer != null && defer.isNotEmpty) params['defer'] = defer;
    if (tags != null && tags.isNotEmpty) params['tags'] = tags.join(',');
    final data = await _get('/api/search', query: params);
    return _asMap(data);
  }

  // --- Views ---

  Future<List<TududiView>> listViews() async {
    final data = await _get('/api/views');
    return _parseList(data, TududiView.fromJson);
  }

  Future<TududiView> getView(String uid) async {
    final data = await _get('/api/views/$uid');
    return TududiView.fromJson(_unwrapEntity(_asMap(data), 'view'));
  }

  Future<TududiView> createView(Map<String, dynamic> body) async {
    final data = await _post('/api/views', body);
    return TududiView.fromJson(_unwrapEntity(_asMap(data), 'view'));
  }

  Future<TududiView> updateView(String uid, Map<String, dynamic> body) async {
    final data = await _patch('/api/views/$uid', body);
    return TududiView.fromJson(_unwrapEntity(_asMap(data), 'view'));
  }

  Future<void> deleteView(String uid) async {
    await _delete('/api/views/$uid');
  }

  // --- Goals / Habits (parity) ---

  Future<List<TududiGoal>> listGoals() async {
    final data = await _get('/api/goals');
    return _parseList(data, TududiGoal.fromJson);
  }

  Future<TududiGoal> getGoal(String uid) async {
    final data = await _get('/api/goal/$uid');
    return TududiGoal.fromJson(_unwrapEntity(_asMap(data), 'goal'));
  }

  Future<TududiGoal> updateGoal(String uid, Map<String, dynamic> body) async {
    final data = await _patch('/api/goal/$uid', body);
    return TududiGoal.fromJson(_unwrapEntity(_asMap(data), 'goal'));
  }

  Future<List<TududiHabit>> listHabits() async {
    final data = await _get('/api/habits');
    return _parseList(data, TududiHabit.fromJson);
  }

  Future<void> completeHabit(String uid) async {
    await _post('/api/habit/$uid/complete', const {});
  }

  /// Completions for a habit. Items include at least `id` and `completed_at`.
  Future<List<Map<String, dynamic>>> listHabitCompletions(String uid) async {
    final data = await _get('/api/habit/$uid/completions');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final list = data['completions'] ?? data['data'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  Future<void> deleteHabitCompletion(String uid, int completionId) async {
    await _delete('/api/habit/$uid/completions/$completionId');
  }

  /// Undo today's completion when possible (deletes the latest completion).
  Future<bool> uncompleteHabitToday(String uid) async {
    final completions = await listHabitCompletions(uid);
    if (completions.isEmpty) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map<String, dynamic>? todayCompletion;
    for (final row in completions) {
      final raw = row['completed_at']?.toString();
      if (raw == null || raw.isEmpty) continue;
      final parsed = DateTime.tryParse(raw)?.toLocal();
      if (parsed == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      if (day == today) {
        todayCompletion = row;
        break;
      }
    }
    todayCompletion ??= completions.first;
    final id = todayCompletion['id'];
    final completionId = id is int
        ? id
        : id is num
        ? id.toInt()
        : int.tryParse(id?.toString() ?? '');
    if (completionId == null) return false;
    await deleteHabitCompletion(uid, completionId);
    return true;
  }

  // --- Inbox ---

  Future<List<Map<String, dynamic>>> listInbox() async {
    final data = await _get('/api/inbox');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final map = _asMap(data);
    final items = map['items'] ?? map['inbox'] ?? map['data'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  // --- OIDC discovery (parity) ---

  Future<List<Map<String, dynamic>>> listOidcProviders() async {
    try {
      final data = await _get('/api/oidc/providers');
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      // Optional endpoint.
    }
    return const [];
  }

  String oidcAuthUrl(String slug) => '$baseUrl/api/oidc/auth/$slug';

  // --- HTTP helpers ---

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await dio.get<dynamic>(path, queryParameters: query);
      return _handle(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<dynamic> _post(String path, Object? body) async {
    try {
      final response = await dio.post<dynamic>(path, data: body);
      return _handle(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<dynamic> _patch(String path, Object? body) async {
    try {
      final response = await dio.patch<dynamic>(path, data: body);
      return _handle(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<void> _delete(String path) async {
    try {
      final response = await dio.delete<dynamic>(path);
      _handle(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  dynamic _handle(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      return response.data;
    }
    final message =
        _extractError(response.data) ?? 'Request failed with status $code';
    throw TududiApiException(
      message: message,
      statusCode: code,
      body: response.data,
    );
  }

  TududiApiException _fromDio(DioException e) {
    final code = e.response?.statusCode;
    final message =
        _extractError(e.response?.data) ?? e.message ?? 'Network error';
    return TududiApiException(
      message: message,
      statusCode: code,
      body: e.response?.data,
    );
  }

  String? _extractError(Object? data) {
    if (data is Map) {
      // Prefer `message` — tududi often puts a short code in `error`.
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
      final error = data['error']?.toString();
      if (error != null && error.isNotEmpty) return error;
      return data['msg']?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  JsonMap _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  JsonMap _unwrapEntity(JsonMap map, String key) {
    if (map[key] is Map) {
      return Map<String, dynamic>.from(map[key] as Map);
    }
    return map;
  }

  List<T> _parseList<T>(Object? data, T Function(JsonMap) fromJson) {
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested =
          map['tasks'] ??
          map['projects'] ??
          map['areas'] ??
          map['notes'] ??
          map['tags'] ??
          map['goals'] ??
          map['habits'] ??
          map['apiKeys'] ??
          map['api_keys'] ??
          map['data'] ??
          map['items'];
      list = nested is List ? nested : const [];
    } else {
      list = const [];
    }

    return list
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
