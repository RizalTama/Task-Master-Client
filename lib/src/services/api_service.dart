import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_master/src/models/user.dart';

class ApiService {
  final String _baseUrl = "http://10.0.2.2:8000"; // Use 10.0.2.2 for Android emulator to connect to host localhost
  String? _token;

  // --- Authentication ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      _token = data['access_token'];
      // Note: The backend will need to return user info along with the token
      // For now, we assume it returns a 'user' object with 'uid' and 'email'.
      return {
        'token': _token,
        'user': User.fromJson(data['user']),
      };
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  void clearToken() {
    _token = null;
  }

  // --- Private method for headers ---
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- Task and Project API calls ---

  Future<Map<String, dynamic>> postChat(String message) async {
    // This endpoint expects a query parameter, not JSON body.
    final response = await http.post(
      Uri.parse('$_baseUrl/chat?user_message=$message'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to post chat: ${response.body}');
    }
  }

  Future<List<dynamic>> getAllTasks() async {
    final response = await http.get(Uri.parse('$_baseUrl/tasks'), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to get tasks');
    }
  }

  Future<List<dynamic>> getActiveTasks() async {
    final response = await http.get(Uri.parse('$_baseUrl/tasks/active'), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to get active tasks');
    }
  }

  Future<List<dynamic>> getProjects() async {
    final response = await http.get(Uri.parse('$_baseUrl/tasks/projects'), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to get projects');
    }
  }

  Future<bool> createTask(String description, {String? dueDate, String? projectName}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: _headers,
      body: json.encode({
        'description': description,
        'due_date': dueDate,
        'project_name': projectName,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['success'] ?? false;
    }
    return false;
  }
}
