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
  static const String _baseUrl = 'http://194.195.86.92:8000/api/v1';
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

  Map<String, String> _getHeaders({bool useBearerFormat = true, bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth && _authToken != null) {
      if (useBearerFormat) {
        // Default: Bearer format (APIToken - backend expects this)
        headers['Authorization'] = 'Bearer $_authToken';
        AppLogger.info('Using Bearer format: Bearer ${_authToken?.substring(0, 10)}...', 'ApiService');
      } else {
        // Legacy: Token format (DRF TokenAuthentication - deprecated)
        headers['Authorization'] = 'Token $_authToken';
        AppLogger.info('Using Token format: Token ${_authToken?.substring(0, 10)}...', 'ApiService');
      }
      AppLogger.info('Full Authorization header: ${headers['Authorization']?.substring(0, 20)}...', 'ApiService');
    } else if (!includeAuth) {
      AppLogger.info('Skipping authorization header for this request', 'ApiService');
    } else {
      AppLogger.warning('No auth token available for request', 'ApiService');
    }
    
    return headers;
  }

  bool get isAuthenticated => _authToken != null;

  Future<ApiResponse<String>> testConnection() async {
    try {
      AppLogger.network('Testing connection', 0, _baseUrl);
      
      final response = await _client.get(
        Uri.parse('$_baseUrl/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));

      AppLogger.network('/', response.statusCode, 'Connection test');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success('Connection successful');
      } else {
        return ApiResponse.error('Server returned status: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      AppLogger.error('Test connection socket exception', 'ApiService', e);
      return ApiResponse.error('Unable to connect to server at $_baseUrl');
    } catch (e) {
      AppLogger.error('Test connection error', 'ApiService', e);
      return ApiResponse.error('Connection test failed: ${e.toString()}');
    }
  }

  // Method to exchange Django token for APIToken
  Future<void> _attemptTokenExchange(String djangoToken, {String? email, String? password}) async {
    try {
      AppLogger.info('Attempting to exchange Django token for APIToken...', 'ApiService');
      
      // Try multiple possible endpoints for APIToken exchange based on backend URLs
      final endpoints = [
        '/auth/tokens/create/',  // From Django urls.py - api_views.create_token
        '/auth/tokens/',         // From Django urls.py - TokenManagementView  
        '/api/v1/auth/tokens/create/',  // Full path version
        '/api/v1/auth/tokens/',         // Full path version
      ];
      
      for (final endpoint in endpoints) {
        AppLogger.info('Trying token exchange endpoint: $endpoint', 'ApiService');
        
        // Try POST request first (for creating new token)
        Map<String, dynamic> requestBody;
        
        if (endpoint.contains('create') && email != null && password != null) {
          // For /auth/tokens/create/ which expects email and password
          requestBody = {
            'email': email,
            'password': password,
            'name': 'Mobile App Token',
          };
          AppLogger.info('Using email/password for token creation', 'ApiService');
        } else {
          // For other endpoints that might accept the Django token
          requestBody = {
            'name': 'Mobile App Token',
          };
          AppLogger.info('Using Django token for token creation', 'ApiService');
        }
        
        var response = await _client.post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (!endpoint.contains('create') || email == null) 'Authorization': 'Token $djangoToken',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 10));

        AppLogger.network('$endpoint (POST)', response.statusCode);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final apiToken = data['key'] ?? data['token'] ?? data['api_token'];
          
          if (apiToken != null && apiToken != djangoToken) {
            await _saveToken(apiToken);
            AppLogger.info('Successfully exchanged for APIToken: ${apiToken.substring(0, 10)}...', 'ApiService');
            return; // Success, exit the loop
          } else {
            AppLogger.info('Token exchange returned same token, continuing with current token', 'ApiService');
            return; // No need to try other endpoints
          }
        } else if (response.statusCode == 404) {
          AppLogger.info('POST endpoint $endpoint not found, trying GET...', 'ApiService');
          
          // Try GET request (for listing existing tokens)
          response = await _client.get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Token $djangoToken',
            },
          ).timeout(const Duration(seconds: 10));

          AppLogger.network('$endpoint (GET)', response.statusCode);
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            AppLogger.info('GET tokens response: $data', 'ApiService');
            
            // Look for an existing active token
            if (data is List && data.isNotEmpty) {
              final firstToken = data.first;
              final apiToken = firstToken['key'] ?? firstToken['token'];
              
              if (apiToken != null && apiToken != djangoToken) {
                await _saveToken(apiToken);
                AppLogger.info('Found existing APIToken: ${apiToken.substring(0, 10)}...', 'ApiService');
                return;
              }
            }
          }
        } else {
          AppLogger.warning('Token exchange failed at $endpoint with status ${response.statusCode}', 'ApiService');
          AppLogger.info('Exchange response: ${response.body}', 'ApiService');
        }
      }
      
      AppLogger.warning('All token exchange endpoints failed', 'ApiService');
      
      // Try to get token info to understand what's wrong
      await _getTokenInfo(djangoToken);
    } catch (e) {
      AppLogger.warning('Token exchange attempt failed: $e', 'ApiService');
      // Continue with the original token
    }
  }

  // Get information about the current token
  Future<void> _getTokenInfo(String token) async {
    try {
      AppLogger.info('Getting token information...', 'ApiService');
      
      final endpoints = [
        '/auth/token-info/',
        '/api/v1/auth/token-info/',
      ];
      
      for (final endpoint in endpoints) {
        final response = await _client.get(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(const Duration(seconds: 5));

        AppLogger.network('$endpoint (token-info)', response.statusCode);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          AppLogger.info('Token info: $data', 'ApiService');
          return;
        } else if (response.statusCode != 404) {
          AppLogger.info('Token info error: ${response.body}', 'ApiService');
        }
      }
    } catch (e) {
      AppLogger.info('Token info request failed: $e', 'ApiService');
    }
  }

  // Quick test to verify token works immediately after login
  Future<void> _testTokenValidity() async {
    try {
      AppLogger.info('Testing token validity immediately after login...', 'ApiService');
      
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/me/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));

      AppLogger.network('/auth/me/ (post-login test)', response.statusCode);
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Token is valid immediately after login!', 'ApiService');
      } else {
        AppLogger.warning('❌ Token is invalid immediately after login! Status: ${response.statusCode}', 'ApiService');
        AppLogger.info('Response: ${response.body}', 'ApiService');
      }
    } catch (e) {
      AppLogger.warning('Token validity test failed: $e', 'ApiService');
    }
  }

  // Method to try token refresh or get a new session token
  Future<ApiResponse<String>> refreshToken() async {
    if (_authToken == null) {
      return ApiResponse.error('No token to refresh');
    }

    try {
      AppLogger.info('Attempting token refresh...', 'ApiService');
      
      // Try refresh endpoint
      final refreshResponse = await _client.post(
        Uri.parse('$_baseUrl/auth/refresh/'),
        headers: _getHeaders(),
        body: jsonEncode({'token': _authToken}),
      ).timeout(const Duration(seconds: 10));

      AppLogger.network('/auth/refresh/', refreshResponse.statusCode);
      
      if (refreshResponse.statusCode == 200) {
        final data = jsonDecode(refreshResponse.body);
        final newToken = data['token'] ?? data['access_token'] ?? data['auth_token'] ?? data['key'];
        
        if (newToken != null) {
          await _saveToken(newToken);
          AppLogger.info('Token refreshed successfully', 'ApiService');
          return ApiResponse.success(newToken);
        }
      }
      
      // If refresh fails, try to get a new session token
      AppLogger.info('Refresh failed, trying session token endpoint...', 'ApiService');
      final sessionResponse = await _client.post(
        Uri.parse('$_baseUrl/auth/session/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      AppLogger.network('/auth/session/', sessionResponse.statusCode);
      
      if (sessionResponse.statusCode == 200 || sessionResponse.statusCode == 201) {
        final data = jsonDecode(sessionResponse.body);
        final newToken = data['token'] ?? data['access_token'] ?? data['auth_token'] ?? data['key'];
        
        if (newToken != null) {
          await _saveToken(newToken);
          AppLogger.info('Session token obtained successfully', 'ApiService');
          return ApiResponse.success(newToken);
        }
      }

      AppLogger.warning('Both token refresh and session endpoints failed', 'ApiService');
      return ApiResponse.error('Failed to refresh token');
      
    } catch (e) {
      AppLogger.error('Token refresh error', 'ApiService', e);
      return ApiResponse.error('Token refresh failed: $e');
    }
  }

  // Debug method to validate token and get detailed error information
  Future<ApiResponse<Map<String, dynamic>>> validateToken() async {
    if (_authToken == null) {
      return ApiResponse.error('No token available');
    }

    try {
      AppLogger.info('=== TOKEN VALIDATION DEBUG ===', 'ApiService');
      AppLogger.info('Token length: ${_authToken!.length}', 'ApiService');
      AppLogger.info('Token preview: ${_authToken!.substring(0, math.min(20, _authToken!.length))}...', 'ApiService');
      AppLogger.info('Token type: ${_authToken!.runtimeType}', 'ApiService');
      
      // Test with multiple endpoints to see which one works
      final endpoints = [
        '/auth/me/',
        '/fitness/activities/',
        '/fitness/goals/',
      ];

      final results = <String, Map<String, dynamic>>{};

      for (final endpoint in endpoints) {
        // Test with Bearer format (primary - backend expects this)
        AppLogger.info('Testing $endpoint with Bearer format...', 'ApiService');
        final bearerResponse = await _client.get(
          Uri.parse('$_baseUrl$endpoint'),
          headers: _getHeaders(useBearerFormat: true),
        ).timeout(const Duration(seconds: 10));

        AppLogger.info('$endpoint (Bearer): Status ${bearerResponse.statusCode}', 'ApiService');
        AppLogger.info('$endpoint (Bearer): Body ${bearerResponse.body.substring(0, math.min(200, bearerResponse.body.length))}', 'ApiService');

        results['${endpoint}_bearer'] = {
          'status_code': bearerResponse.statusCode,
          'body': bearerResponse.body,
          'success': bearerResponse.statusCode >= 200 && bearerResponse.statusCode < 300,
        };

        // Test with Token format (legacy)
        AppLogger.info('Testing $endpoint with Token format (legacy)...', 'ApiService');
        final tokenResponse = await _client.get(
          Uri.parse('$_baseUrl$endpoint'),
          headers: _getHeaders(useBearerFormat: false),
        ).timeout(const Duration(seconds: 10));

        AppLogger.info('$endpoint (Token): Status ${tokenResponse.statusCode}', 'ApiService');
        AppLogger.info('$endpoint (Token): Body ${tokenResponse.body.substring(0, math.min(200, tokenResponse.body.length))}', 'ApiService');

        results['${endpoint}_token'] = {
          'status_code': tokenResponse.statusCode,
          'body': tokenResponse.body,
          'success': tokenResponse.statusCode >= 200 && tokenResponse.statusCode < 300,
        };
      }

      AppLogger.info('=== TOKEN VALIDATION COMPLETE ===', 'ApiService');
      return ApiResponse.success(results);

    } catch (e) {
      AppLogger.error('Token validation error', 'ApiService', e);
      return ApiResponse.error('Token validation failed: $e');
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
        headers: _getHeaders(includeAuth: false), // Don't send auth header for registration
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
        // Check different possible token keys
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
            ? (data['message'] ?? data['error'] ?? 'Registration failed')
            : 'Registration failed';
        AppLogger.warning('Registration failed: $errorMessage', 'ApiService');
        return ApiResponse.error(errorMessage);
      }
    } on SocketException catch (e) {
      AppLogger.error('Socket exception during registration', 'ApiService', e);
      return ApiResponse.error('Unable to connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      AppLogger.error('HTTP exception during registration', 'ApiService', e);
      return ApiResponse.error('Server error occurred. Please try again later.');
    } on FormatException catch (e) {
      AppLogger.error('Format exception during registration', 'ApiService', e);
      return ApiResponse.error('Invalid response from server.');
    } catch (e) {
      AppLogger.error('General exception during registration', 'ApiService', e);
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
        headers: _getHeaders(includeAuth: false), // Don't send auth header for login
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      AppLogger.network('/auth/login/', response.statusCode);

      final data = jsonDecode(response.body);
      AppLogger.info('Login response data: $data', 'ApiService');
      
      if (response.statusCode == 200) {
        // Check different possible token keys
        String? token = data['token'] ?? data['access_token'] ?? data['auth_token'] ?? data['key'];
        
        if (token != null) {
          await _saveToken(token);
          AppLogger.info('User login successful - Token saved: ${token.substring(0, 10)}...', 'ApiService');
          
          // Try to exchange Django token for APIToken if needed
          await _attemptTokenExchange(token, email: email, password: password);
          
          // Immediately test the token after exchange
          await _testTokenValidity();
        } else {
          AppLogger.error('Login successful but no token found in response: $data', 'ApiService');
          return ApiResponse.error('Authentication token not received');
        }
        
        return ApiResponse.success(AuthResult.fromJson(data));
      } else {
        final errorMessage = data is Map<String, dynamic> 
            ? (data['message'] ?? data['error'] ?? 'Login failed')
            : 'Login failed';
        AppLogger.warning('Login failed: $errorMessage', 'ApiService');
        return ApiResponse.error(errorMessage);
      }
    } on SocketException catch (e) {
      AppLogger.error('Socket exception during login', 'ApiService', e);
      return ApiResponse.error('Unable to connect to server. Please check your internet connection.');
    } on HttpException catch (e) {
      AppLogger.error('HTTP exception during login', 'ApiService', e);
      return ApiResponse.error('Server error occurred. Please try again later.');
    } on FormatException catch (e) {
      AppLogger.error('Format exception during login', 'ApiService', e);
      return ApiResponse.error('Invalid response from server.');
    } catch (e) {
      AppLogger.error('General exception during login', 'ApiService', e);
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
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(UserProfile.fromJson(data));
      } else {
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
        final activities = (data['results'] as List)
            .map((json) => FitnessActivity.fromJson(json))
            .toList();
        return ApiResponse.success(activities);
      } else if (response.statusCode == 404 || response.statusCode == 401) {
        // Endpoint might not be implemented yet, return error to trigger local fallback
        AppLogger.warning('Fitness activities endpoint not available, using local storage', 'ApiService');
        return ApiResponse.error('Endpoint not available');
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to get activities');
      }
    } catch (e) {
      AppLogger.error('Error getting fitness activities', 'ApiService', e);
      // Return error to trigger local fallback
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<FitnessActivity>> createActivity({
    required String activityType,
    required int durationMinutes,
    double? distanceKm,
    int? caloriesBurned,
    String? activityName,
    String? startLocation,
    String? endLocation,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/fitness/activities/'),
        headers: _getHeaders(),
        body: jsonEncode({
          'activity_type': activityType,
          'duration_minutes': durationMinutes,
          'distance_km': distanceKm,
          'calories_burned': caloriesBurned,
          if (activityName != null) 'name': activityName,
          if (startLocation != null) 'start_location': startLocation,
          if (endLocation != null) 'end_location': endLocation,
          if (startLatitude != null) 'start_latitude': startLatitude,
          if (startLongitude != null) 'start_longitude': startLongitude,
          if (endLatitude != null) 'end_latitude': endLatitude,
          if (endLongitude != null) 'end_longitude': endLongitude,
        }),
      );

      AppLogger.network('/fitness/activities/', response.statusCode, 'CREATE');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return ApiResponse.success(FitnessActivity.fromJson(data));
      } else if (response.statusCode == 404 || response.statusCode == 401) {
        // Endpoint might not be implemented yet or auth issues, return error to trigger local fallback
        AppLogger.warning('Activity creation endpoint not available, using local storage', 'ApiService');
        return ApiResponse.error('Endpoint not available');
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to create activity');
      }
    } catch (e) {
      AppLogger.error('Error creating fitness activity', 'ApiService', e);
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

  Future<ApiResponse<UserProfile>> updateProfile({
    String? bio,
    DateTime? birthDate,
    String? gender,
    List<String>? interests,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/auth/profile/'),
        headers: _getHeaders(),
        body: jsonEncode({
          if (bio != null) 'bio': bio,
          if (birthDate != null) 'birth_date': birthDate.toIso8601String(),
          if (gender != null) 'gender': gender,
          if (interests != null) 'interests': interests,
        }),
      );

      AppLogger.network('/auth/profile/', response.statusCode, 'UPDATE');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse.success(UserProfile.fromJson(data));
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      AppLogger.error('Error updating profile', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getDiscovery() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/matching/discovery/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/matching/discovery/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(users);
      } else if (response.statusCode == 404) {
        AppLogger.warning('Discovery endpoint not found', 'ApiService');
        return ApiResponse.error('Discovery feature not yet available');
      } else if (response.statusCode == 401) {
        AppLogger.warning('Unauthorized access to discovery endpoint', 'ApiService');
        return ApiResponse.error('Authentication required');
      } else {
        // Try to decode error message, but handle cases where response isn't JSON
        String errorMessage = 'Failed to get discovery';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? errorMessage;
        } catch (e) {
          // Response body is not JSON (likely HTML error page)
          AppLogger.warning('Non-JSON error response from discovery endpoint', 'ApiService');
        }
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      AppLogger.error('Error getting discovery', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<void>> performMatchAction({
    required int userId,
    required String action, // 'like' or 'pass'
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/matching/actions/'),
        headers: _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'action': action,
        }),
      );

      AppLogger.network('/matching/actions/', response.statusCode, action.toUpperCase());
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to perform action');
      }
    } catch (e) {
      AppLogger.error('Error performing match action', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getMatches() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/matching/matches/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/matching/matches/', response.statusCode);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final matches = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(matches);
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to get matches');
      }
    } catch (e) {
      AppLogger.error('Error getting matches', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getEvents() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/events/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/events/', response.statusCode);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final events = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(events);
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to get events');
      }
    } catch (e) {
      AppLogger.error('Error getting events', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    String? location,
    String? activityType,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/events/'),
        headers: _getHeaders(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'date_time': dateTime.toIso8601String(),
          if (location != null) 'location': location,
          if (activityType != null) 'activity_type': activityType,
        }),
      );

      AppLogger.network('/events/', response.statusCode, 'CREATE');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(data['message'] ?? 'Failed to create event');
      }
    } catch (e) {
      AppLogger.error('Error creating event', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== FITNESS ACTIVITY TYPES ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getActivityTypes() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/activity-types/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activity-types/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final types = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(types);
      } else {
        return ApiResponse.error('Failed to get activity types');
      }
    } catch (e) {
      AppLogger.error('Error getting activity types', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getActivityType(int id) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/activity-types/$id/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activity-types/$id/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to get activity type');
      }
    } catch (e) {
      AppLogger.error('Error getting activity type', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== FITNESS ACTIVITIES EXTENDED ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getActivitiesFeed() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/activities/feed/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activities/feed/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(activities);
      } else {
        return ApiResponse.error('Failed to get activities feed');
      }
    } catch (e) {
      AppLogger.error('Error getting activities feed', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<FitnessActivity>>> getMyActivities() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/activities/my_activities/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activities/my_activities/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = (data['results'] as List)
            .map((json) => FitnessActivity.fromJson(json))
            .toList();
        return ApiResponse.success(activities);
      } else {
        return ApiResponse.error('Failed to get my activities');
      }
    } catch (e) {
      AppLogger.error('Error getting my activities', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<FitnessActivity>> updateActivity(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/fitness/activities/$id/'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      AppLogger.network('/fitness/activities/$id/', response.statusCode, 'UPDATE');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.success(FitnessActivity.fromJson(responseData));
      } else {
        return ApiResponse.error('Failed to update activity');
      }
    } catch (e) {
      AppLogger.error('Error updating activity', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<FitnessActivity>> partialUpdateActivity(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/fitness/activities/$id/'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );

      AppLogger.network('/fitness/activities/$id/', response.statusCode, 'PATCH');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.success(FitnessActivity.fromJson(responseData));
      } else {
        return ApiResponse.error('Failed to update activity');
      }
    } catch (e) {
      AppLogger.error('Error updating activity', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<void>> deleteActivity(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/fitness/activities/$id/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activities/$id/', response.statusCode, 'DELETE');
      
      if (response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to delete activity');
      }
    } catch (e) {
      AppLogger.error('Error deleting activity', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<FitnessActivity>> getActivity(int id) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/activities/$id/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activities/$id/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(FitnessActivity.fromJson(data));
      } else {
        return ApiResponse.error('Failed to get activity');
      }
    } catch (e) {
      AppLogger.error('Error getting activity', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== KUDOS SYSTEM ==========
  Future<ApiResponse<void>> giveKudos(int activityId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/fitness/activities/$activityId/kudos/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activities/$activityId/kudos/', response.statusCode);
      
      if (response.statusCode == 201) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to give kudos');
      }
    } catch (e) {
      AppLogger.error('Error giving kudos', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<void>> removeKudos(int activityId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/fitness/activities/$activityId/remove_kudos/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/activities/$activityId/remove_kudos/', response.statusCode);
      
      if (response.statusCode == 204) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to remove kudos');
      }
    } catch (e) {
      AppLogger.error('Error removing kudos', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== FITNESS ROUTES ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoutes() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/routes/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/routes/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(routes);
      } else {
        return ApiResponse.error('Failed to get routes');
      }
    } catch (e) {
      AppLogger.error('Error getting routes', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createRoute(Map<String, dynamic> routeData) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/fitness/routes/'),
        headers: _getHeaders(),
        body: jsonEncode(routeData),
      );

      AppLogger.network('/fitness/routes/', response.statusCode, 'CREATE');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to create route');
      }
    } catch (e) {
      AppLogger.error('Error creating route', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getNearbyRoutes({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      String url = '$_baseUrl/fitness/routes/nearby/';
      if (latitude != null && longitude != null) {
        url += '?lat=$latitude&lng=$longitude';
        if (radius != null) url += '&radius=$radius';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/routes/nearby/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(routes);
      } else {
        return ApiResponse.error('Failed to get nearby routes');
      }
    } catch (e) {
      AppLogger.error('Error getting nearby routes', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getPopularRoutes() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/routes/popular/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/routes/popular/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(routes);
      } else {
        return ApiResponse.error('Failed to get popular routes');
      }
    } catch (e) {
      AppLogger.error('Error getting popular routes', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== FITNESS GOALS ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getGoals() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/goals/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/goals/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final goals = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(goals);
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
      AppLogger.info('Creating goal with Bearer format (APIToken)', 'ApiService');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl/fitness/goals/'),
        headers: _getHeaders(),
        body: jsonEncode(goalData),
      );

      AppLogger.network('/fitness/goals/', response.statusCode, 'CREATE');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.info('Goal created successfully on server', 'ApiService');
        return ApiResponse.success(data);
      } else if (response.statusCode == 401) {
        AppLogger.warning('Unauthorized goal creation attempt', 'ApiService');
        return ApiResponse.error('Authentication required');
      } else if (response.statusCode == 400) {
        // Get detailed validation errors
        try {
          final data = jsonDecode(response.body);
          AppLogger.warning('Goal creation 400 response: $data', 'ApiService');
          final errorMessage = data['message'] ?? data['error'] ?? data['detail'] ?? 'Invalid goal data';
          AppLogger.warning('Goal creation validation error: $errorMessage', 'ApiService');
          return ApiResponse.error(errorMessage);
        } catch (e) {
          AppLogger.warning('Goal creation failed with 400 but no parseable error: ${response.body}', 'ApiService');
          return ApiResponse.error('Invalid goal data');
        }
      } else {
        AppLogger.warning('Goal creation failed with status ${response.statusCode}', 'ApiService');
        AppLogger.info('Response body: ${response.body}', 'ApiService');
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
        final goals = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(goals);
      } else {
        return ApiResponse.error('Failed to get active goals');
      }
    } catch (e) {
      AppLogger.error('Error getting active goals', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== ACHIEVEMENTS ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getAchievements() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/achievements/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/achievements/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final achievements = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(achievements);
      } else {
        return ApiResponse.error('Failed to get achievements');
      }
    } catch (e) {
      AppLogger.error('Error getting achievements', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getUserAchievements() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/user-achievements/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/user-achievements/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final achievements = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(achievements);
      } else {
        return ApiResponse.error('Failed to get user achievements');
      }
    } catch (e) {
      AppLogger.error('Error getting user achievements', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentAchievements() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/user-achievements/recent/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/user-achievements/recent/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final achievements = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(achievements);
      } else {
        return ApiResponse.error('Failed to get recent achievements');
      }
    } catch (e) {
      AppLogger.error('Error getting recent achievements', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== PERSONAL RECORDS ==========
  Future<ApiResponse<List<Map<String, dynamic>>>> getPersonalRecords() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/personal-records/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/personal-records/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = List<Map<String, dynamic>>.from(data['results'] ?? data);
        return ApiResponse.success(records);
      } else {
        return ApiResponse.error('Failed to get personal records');
      }
    } catch (e) {
      AppLogger.error('Error getting personal records', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== HEALTH & INSIGHTS ==========
  Future<ApiResponse<Map<String, dynamic>>> getHealthData() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/health/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/health/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to get health data');
      }
    } catch (e) {
      AppLogger.error('Error getting health data', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getInsights() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/insights/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/insights/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to get insights');
      }
    } catch (e) {
      AppLogger.error('Error getting insights', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== LEADERBOARD ==========
  Future<ApiResponse<Map<String, dynamic>>> getLeaderboard({
    String? timeframe,
    String? activityType,
  }) async {
    try {
      String url = '$_baseUrl/fitness/leaderboard/';
      List<String> params = [];
      if (timeframe != null) params.add('timeframe=$timeframe');
      if (activityType != null) params.add('activity_type=$activityType');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/leaderboard/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to get leaderboard');
      }
    } catch (e) {
      AppLogger.error('Error getting leaderboard', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== SYNC STATUS ==========
  Future<ApiResponse<Map<String, dynamic>>> getSyncStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/fitness/sync/status/'),
        headers: _getHeaders(),
      );

      AppLogger.network('/fitness/sync/status/', response.statusCode);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to get sync status');
      }
    } catch (e) {
      AppLogger.error('Error getting sync status', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateSyncStatus(Map<String, dynamic> syncData) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/fitness/sync/status/'),
        headers: _getHeaders(),
        body: jsonEncode(syncData),
      );

      AppLogger.network('/fitness/sync/status/', response.statusCode, 'UPDATE');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to update sync status');
      }
    } catch (e) {
      AppLogger.error('Error updating sync status', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }

  // ========== STRAVA INTEGRATION ==========
  Future<ApiResponse<Map<String, dynamic>>> connectStrava(Map<String, dynamic> authData) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/fitness/strava/connect/'),
        headers: _getHeaders(),
        body: jsonEncode(authData),
      );

      AppLogger.network('/fitness/strava/connect/', response.statusCode);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error('Failed to connect Strava');
      }
    } catch (e) {
      AppLogger.error('Error connecting Strava', 'ApiService', e);
      return ApiResponse.error('Network error: $e');
    }
  }
}