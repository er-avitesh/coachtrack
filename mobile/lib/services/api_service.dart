// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
    );
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    throw ApiException(body['message'] ?? 'Request failed', res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
