import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Initialize session from local storage if available
  static Future<bool> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJson = prefs.getString('current_user');
      if (_token != null && userJson != null) {
        currentUser = UserModel.fromJson(jsonDecode(userJson));
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _persistSession(String token, UserModel user) async {
    _token = token;
    currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('current_user', jsonEncode(user.toJson()));
    } catch (_) {}
  }

  /// 1. Standard username and password login
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
        final token = data['token'];
        final user = UserModel.fromJson(data['user']);
        await _persistSession(token, user);
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

  /// 2. Google OAuth Login for IITM Smail (@smail.iitm.ac.in)
  static Future<UserModel> googleLogin({
    required String email,
    String? name,
    String? idToken,
    String? photoUrl,
  }) async {
    final url = Uri.parse('$baseUrl/auth/google');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'name': name,
          'idToken': idToken,
          'photoUrl': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = UserModel.fromJson(data['user']);
        await _persistSession(token, user);
        return currentUser!;
      } else {
        final errorMsg = _extractErrorMessage(response);
        throw Exception(errorMsg ?? 'Failed to authenticate IITM Google Account');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed host lookup')) {
        rethrow;
      }
      throw Exception('Cannot connect to backend server at $baseUrl');
    }
  }

  /// 3. Logout and clear session
  static Future<void> logout() async {
    _token = null;
    currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');
    } catch (_) {}
  }

  /// 4. Fetch assets for a specific location (e.g. Room 101)
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

  /// 5. Update physical asset status
  static Future<AssetModel> updateAssetStatus({
    required int locationId,
    required int assetId,
    required String status,
    String? comment,
  }) async {
    final url = Uri.parse('$baseUrl/locations/$locationId/assets/$assetId');
    final response = await http.put(
      url,
      headers: _headers,
      body: jsonEncode({
        'status': status.toUpperCase(),
        'comment': comment,
      }),
    );

    if (response.statusCode == 200) {
      return AssetModel.fromJson(jsonDecode(response.body));
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to update asset status');
    }
  }

  /// 6. Fetch complaints (optionally scoped to a location or active only)
  static Future<List<ComplaintModel>> getComplaints({
    int? hostelId,
    int? floorId,
    int? locationId,
    bool? activeOnly,
  }) async {
    final queryParams = <String, String>{};
    if (hostelId != null) queryParams['hostelId'] = hostelId.toString();
    if (floorId != null) queryParams['floorId'] = floorId.toString();
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

  /// 7. Submit a new maintenance complaint
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

  /// 8. Update complaint status (Staff / Manager only)
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

  /// 9. Fetch Manager Dashboard Executive Summary
  static Future<Map<String, dynamic>> getDashboardSummary({int hostelId = 1}) async {
    final url = Uri.parse('$baseUrl/dashboard/summary?hostelId=$hostelId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to load dashboard summary');
    }
  }

  /// 10. Fetch Floors for a Hostel
  static Future<List<dynamic>> getFloors({int hostelId = 1}) async {
    final url = Uri.parse('$baseUrl/hostels/$hostelId/floors');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to load floors');
    }
  }

  /// 11. Fetch Locations for a Floor
  static Future<List<dynamic>> getLocations(int floorId) async {
    final url = Uri.parse('$baseUrl/floors/$floorId/locations');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to load locations');
    }
  }

  /// 12. Mark Location Inspected
  static Future<void> markInspected({
    required int locationId,
    required String staffName,
  }) async {
    final url = Uri.parse('$baseUrl/locations/$locationId/inspections');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'staffName': staffName}),
    );

    if (response.statusCode != 200) {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to record inspection');
    }
  }

  /// 13. Create new Location on a Floor (Manager only)
  static Future<Map<String, dynamic>> createLocation({
    required int floorId,
    required String name,
    required String type,
    String? roomType,
  }) async {
    final url = Uri.parse('$baseUrl/floors/$floorId/locations');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'type': type.toUpperCase(),
        'roomType': roomType?.toUpperCase(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg ?? 'Failed to create location');
    }
  }

  /// Helper to extract readable backend error messages
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
