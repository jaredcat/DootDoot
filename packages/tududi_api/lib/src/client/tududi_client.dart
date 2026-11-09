import 'package:dio/dio.dart';

import '../errors.dart';
import '../models/models.dart';

typedef JsonMap = Map<String, dynamic>;

/// REST client for one Tududi server (Cloud or self-hosted).
class TududiClient {
  TududiClient({
    required Dio dio,
    required this.baseUrl,
  }) : _dio = dio;

  final Dio _dio;
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
      await _dio.get<dynamic>('/api/logout');
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

  Future<Map<String, dynamic>> probeServer() async {
    try {
      final data = await _get('/api/version');
      return _asMap(data);
    } on TududiApiException {
      rethrow;
    } catch (e) {
      throw TududiUnsupportedServerException(
        'Could not reach Tududi at $baseUrl',
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
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (projectId != null) 'project_id': projectId,
      if (projectUid != null) 'project_uid': projectUid,
      if (areaUid != null) 'area_uid': areaUid,
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

  Future<TududiTask> completeTask(String uid, {bool done = true}) {
    return updateTask(uid, {
      'status': done ? TaskStatus.done : TaskStatus.notStarted,
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

  // --- Areas ---

  Future<List<TududiArea>> listAreas() async {
    final data = await _get('/api/areas');
    return _parseList(data, TududiArea.fromJson);
  }

  Future<TududiArea> createArea(Map<String, dynamic> body) async {
    final data = await _post('/api/area', body);
    return TududiArea.fromJson(_unwrapEntity(_asMap(data), 'area'));
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

  Future<Map<String, dynamic>> search(String query) async {
    final data = await _get('/api/search', query: {'q': query});
    return _asMap(data);
  }

  // --- Goals / Habits (parity) ---

  Future<List<TududiGoal>> listGoals() async {
    final data = await _get('/api/goals');
    return _parseList(data, TududiGoal.fromJson);
  }

  Future<List<TududiHabit>> listHabits() async {
    final data = await _get('/api/habits');
    return _parseList(data, TududiHabit.fromJson);
  }

  Future<void> completeHabit(String uid) async {
    await _post('/api/habit/$uid/complete', const {});
  }

  // --- Inbox ---

  Future<List<Map<String, dynamic>>> listInbox() async {
    final data = await _get('/api/inbox');
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    final map = _asMap(data);
    final items = map['items'] ?? map['inbox'] ?? map['data'];
    if (items is List) {
      return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return _handle(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<dynamic> _post(String path, Object? body) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);
      return _handle(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<dynamic> _patch(String path, Object? body) async {
    try {
      final response = await _dio.patch<dynamic>(path, data: body);
      return _handle(response);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Future<void> _delete(String path) async {
    try {
      final response = await _dio.delete<dynamic>(path);
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
    final message = _extractError(response.data) ??
        'Request failed with status $code';
    throw TududiApiException(
      message: message,
      statusCode: code,
      body: response.data,
    );
  }

  TududiApiException _fromDio(DioException e) {
    final code = e.response?.statusCode;
    final message = _extractError(e.response?.data) ??
        e.message ??
        'Network error';
    return TududiApiException(
      message: message,
      statusCode: code,
      body: e.response?.data,
    );
  }

  String? _extractError(Object? data) {
    if (data is Map) {
      return (data['error'] ?? data['message'] ?? data['msg'])?.toString();
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

  List<T> _parseList<T>(
    Object? data,
    T Function(JsonMap) fromJson,
  ) {
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['tasks'] ??
          map['projects'] ??
          map['areas'] ??
          map['notes'] ??
          map['tags'] ??
          map['goals'] ??
          map['habits'] ??
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
