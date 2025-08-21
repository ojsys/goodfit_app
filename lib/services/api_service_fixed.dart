import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/auth_result.dart';
import '../models/user_profile.dart';
import '../models/fitness_activity.dart';
import '../utils/logger.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8001/api/v1';
  static const String _tokenKey = 'auth_token';
  
  String? _authToken;
  late http.Client _client;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _client = http.Client();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    if (_authToken != null) {
      AppLogger.info('Loaded existing token from storage: ${_authToken!.substring(0, 10)}... (length: ${_authToken!.length})', 'ApiService');
    } else {
      AppLogger.info('No existing token found in storage', 'ApiService');
    }
  }

  Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    AppLogger.info('Token saved to SharedPreferences: ${token.substring(0, 10)}... (length: ${token.length})', 'ApiService');
  }

  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth && _authToken != null) {
      // Use Bearer format (matches your backend APIToken authentication)
      headers['Authorization'] = 'Bearer $_authToken';
      AppLogger.info('Using Bearer format: Bearer ${_authToken?.substring(0, 10)}...', 'ApiService');
    }
    
    return headers;
  }

  bool get isAuthenticated => _authToken != null;

  // Helper method to handle paginated responses
  List<T> _parsePaginatedResponse<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    try {
      if (data is Map<String, dynamic>) {
        // Django REST Framework pagination format
        if (data.containsKey('results') && data['results'] is List) {
          return (data['results'] as List)
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
        }
        // Single item response
        else if (data.containsKey('id')) {
          return [fromJson(data)];
        }
      }
      // Direct list response
      else if (data is List) {
        return data
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      AppLogger.warning('Unexpected response format: $data', 'ApiService');
      return [];
    } catch (e) {
      AppLogger.error('Error parsing paginated response: $e', 'ApiService');
      return [];
    }
  }

  Future<ApiResponse<String>> testConnection() async {
    try {
      AppLogger.network('Testing connection', 0, _baseUrl);
      
      final response = await _client.get(
        Uri.parse('$_baseUrl/'),
        headers: _getHeaders(includeAuth: false),
      ).timeout(const Duration(seconds: 5));

      AppLogger.network('/', response.statusCode, 'Connection test');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success('Connection successful');
      } else {
        return ApiResponse.error('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Test connection error', 'ApiService', e);
      return ApiResponse.error('Connection test failed: ${e.toString()}');
    }
  }

  Future<ApiResponse<AuthResult>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      AppLogger.info('Attempting to register user with email: $email', 'ApiService');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirm': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      ).timeout(const Duration(seconds: 10));

      AppLogger.network('/auth/register/', response.statusCode);

      final data = jsonDecode(response.body);
      AppLogger.info('Registration response data: $data', 'ApiService');
      
      if (response.statusCode == 201) {
        String? token = data['token'] ?? data['access_token'] ?? data['auth_token'] ?? data['key'];
        
        if (token != null) {
          await _saveToken(token);
          AppLogger.info('User registration successful - Token saved: ${token.substring(0, 10)}...', 'ApiService');
        } else {
          AppLogger.error('Registration successful but no token found in response: $data', 'ApiService');
          return ApiResponse.error('Authentication token not received');
        }
        
        return ApiResponse.success(AuthResult.fromJson(data));
      } else {
        final errorMessage = data is Map<String, dynamic> 
            ? (data['message'] ?? data['error'] ?? data['detail'] ?? 'Registration failed')
            : 'Registration failed';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      AppLogger.error('Registration error', 'ApiService', e);
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting to login user with email: $email', 'ApiService');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      AppLogger.network('/auth/login/', response.statusCode);

      final data = jsonDecode(response.body);
      AppLogger.info('Login response data: $data', 'ApiService');
      
      if (response.statusCode == 200) {
        String? token = data['token'] ?? data['access_token'] ?? data['auth_token'] ?? data['key'];
        
        if (token != null) {
          await _saveToken(token);
          AppLogger.info('User login successful - Token saved: ${token.substring(0, 10)}...', 'ApiService');
        } else {
          return ApiResponse.error('Authentication token not received');
        }
        
        return ApiResponse.success(AuthResult.fromJson(data));
      } else {
        final errorMessage = data is Map<String, dynamic> 
            ? (data['message'] ?? data['error'] ?? data['detail'] ?? 'Login failed')
            : 'Login failed';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      AppLogger.error('Login error', 'ApiService', e);
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<UserProfile>> getUserProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/me/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/auth/me/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(UserProfile.fromJson(data));
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      AppLogger.error('Error getting user profile', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<FitnessActivity>>> getFitnessActivities() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/activities/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activities/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = _parsePaginatedResponse(data, (json) => FitnessActivity.fromJson(json));
        return ApiResponse.success(activities);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else {
        return ApiResponse.error('Failed to get activities');
      }
    } catch (e) {
      AppLogger.error('Error getting fitness activities', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // GOALS API - Fixed for new goal types
  Future<ApiResponse<List<Map<String, dynamic>>>> getGoals() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/goals/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/goals/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final goals = _parsePaginatedResponse(data, (json) => json);
        return ApiResponse.success(goals);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else {
        return ApiResponse.error('Failed to get goals');
      }
    } catch (e) {
      AppLogger.error('Error getting goals', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createGoal(Map<String, dynamic> goalData) async {
    try {
      AppLogger.info('Creating goal with data: $goalData', 'ApiService');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/fitness/goals/'),
        headers: _getHeaders(),
        body: jsonEncode(goalData),
      );

      AppLogger.network('/fitness/goals/', response.statusCode, 'CREATE');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.info('Goal created successfully', 'ApiService');
        return ApiResponse.success(data);
      } else if (response.statusCode == 400) {
        try {
          final data = jsonDecode(response.body);
          final errors = <String>[];
          
          if (data is Map<String, dynamic>) {
            data.forEach((key, value) {
              if (value is List) {
                errors.addAll(value.map((e) => '$key: $e'));
              } else {
                errors.add('$key: $value');
              }
            });
          }
          
          final errorMessage = errors.isNotEmpty ? errors.join(', ') : 'Invalid goal data';
          AppLogger.warning('Goal creation validation error: $errorMessage', 'ApiService');
          return ApiResponse.error(errorMessage);
        } catch (e) {
          return ApiResponse.error('Invalid goal data');
        }
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else {
        return ApiResponse.error('Failed to create goal (${response.statusCode})');
      }
    } catch (e) {
      AppLogger.error('Error creating goal', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getActiveGoals() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/goals/active/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/goals/active/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final goals = _parsePaginatedResponse(data, (json) => json);
        return ApiResponse.success(goals);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else {
        return ApiResponse.error('Failed to get active goals');
      }
    } catch (e) {
      AppLogger.error('Error getting active goals', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ROUTES API - Fixed parsing
  Future<ApiResponse<List<Map<String, dynamic>>>> getPopularRoutes() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/routes/popular/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/routes/popular/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = _parsePaginatedResponse(data, (json) => json);
        return ApiResponse.success(routes);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist yet
        return ApiResponse.success([]);
      } else {
        return ApiResponse.error('Failed to get popular routes');
      }
    } catch (e) {
      AppLogger.error('Error getting popular routes', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ACHIEVEMENTS API - Fixed parsing
  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentAchievements() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/user-achievements/recent/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/user-achievements/recent/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final achievements = _parsePaginatedResponse(data, (json) => json);
        return ApiResponse.success(achievements);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist yet
        return ApiResponse.success([]);
      } else {
        return ApiResponse.error('Failed to get recent achievements');
      }
    } catch (e) {
      AppLogger.error('Error getting recent achievements', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // PERSONAL RECORDS API - Fixed parsing
  Future<ApiResponse<List<Map<String, dynamic>>>> getPersonalRecords() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/personal-records/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/personal-records/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = _parsePaginatedResponse(data, (json) => json);
        return ApiResponse.success(records);
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication required');
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist yet
        return ApiResponse.success([]);
      } else {
        return ApiResponse.error('Failed to get personal records');
      }
    } catch (e) {
      AppLogger.error('Error getting personal records', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/logout/'),
        headers: _getHeaders(),
      );
      
      AppLogger.network('/auth/logout/', response.statusCode);
      await clearToken();
      AppLogger.info('User logged out successfully', 'ApiService');
      return ApiResponse.success(null);
    } catch (e) {
      AppLogger.error('Error during logout', 'ApiService', e);
      await clearToken();
      return ApiResponse.error('Logout error: $e');
    }
  }
}