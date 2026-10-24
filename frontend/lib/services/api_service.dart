import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/asset_model.dart';
import '../models/complaint_model.dart';

class ApiService {
  // Use http://10.0.2.2:8080/api if running on Android Emulator.
  // Use http://localhost:8080/api for Chrome, macOS, and iOS Simulator.
  static String get defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static String baseUrl = defaultBaseUrl;
  static String? _token;
  static UserModel? currentUser;

  static bool get isAuthenticated => _token != null;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// 1. Authenticate with username and password
  static Future<UserModel> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        currentUser = UserModel.fromJson(data['user']);
        return currentUser!;
      } else {
        final errorMsg = _extractErrorMessage(response);
        throw Exception(errorMsg ?? 'Invalid username or password');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed host lookup')) {
        rethrow;
      }
      throw Exception('Cannot connect to backend server at $baseUrl');
    }
  }

  /// 2. Logout and clear session
  static void logout() {
    _token = null;
    currentUser = null;
  }

  /// 3. Fetch assets for a specific location (e.g. Room 101)
  static Future<List<AssetModel>> getAssets(int locationId) async {
    final url = Uri.parse('$baseUrl/locations/$locationId/assets');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((item) => AssetModel.fromJson(item)).toList();
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to load assets (Status ${response.statusCode})');
    }
  }

  /// 4. Fetch complaints (optionally scoped to a location or active only)
  static Future<List<ComplaintModel>> getComplaints({
    int? locationId,
    bool? activeOnly,
  }) async {
    final queryParams = <String, String>{};
    if (locationId != null) queryParams['locationId'] = locationId.toString();
    if (activeOnly != null) queryParams['activeOnly'] = activeOnly.toString();

    final url = Uri.parse('$baseUrl/complaints').replace(queryParameters: queryParams);
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((item) => ComplaintModel.fromJson(item)).toList();
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to load complaints');
    }
  }

  /// 5. Submit a new maintenance complaint
  static Future<ComplaintModel> createComplaint({
    required int locationId,
    int? assetId,
    required String title,
    required String description,
    required String priority,
  }) async {
    final url = Uri.parse('$baseUrl/complaints');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'locationId': locationId,
        'assetId': assetId,
        'title': title,
        'description': description,
        'priority': priority.toUpperCase(),
        'reportedBy': currentUser?.fullName ?? currentUser?.username ?? 'Student',
      }),
    );

    if (response.statusCode == 201) {
      return ComplaintModel.fromJson(jsonDecode(response.body));
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to submit complaint');
    }
  }

  /// 6. Update complaint status (Staff / Manager only)
  static Future<ComplaintModel> updateComplaintStatus({
    required int complaintId,
    required String status,
    String? resolutionNotes,
  }) async {
    final url = Uri.parse('$baseUrl/complaints/$complaintId');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({
        'status': status.toUpperCase(),
        'resolutionNotes': resolutionNotes,
        'resolvedBy': currentUser?.fullName ?? currentUser?.username,
      }),
    );

    if (response.statusCode == 200) {
      return ComplaintModel.fromJson(jsonDecode(response.body));
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to update complaint status');
    }
  }

  /// 7. Helper to extract readable backend error messages
  static String? _extractErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    } catch (_) {}
    return null;
  }
}
