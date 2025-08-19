import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _apiService.isAuthenticated && _user != null;

  Future<void> init() async {
    await _apiService.init();
    if (_apiService.isAuthenticated) {
      // Try to load user profile to validate token
      try {
        await loadUserProfile();
      } catch (e) {
        AppLogger.info('Token validation failed on startup, clearing invalid token', 'AuthProvider');
        // Clear invalid token to prevent authentication issues
        await _apiService.clearToken();
        _user = null;
        notifyListeners();
      }
    }
  }

  Future<void> testConnection() async {
    AppLogger.info('Testing API connection...', 'AuthProvider');
    final result = await _apiService.testConnection();
    if (result.success) {
      AppLogger.info('Connection test successful: ${result.data}', 'AuthProvider');
    } else {
      AppLogger.error('Connection test failed: ${result.error}', 'AuthProvider');
    }
  }

  Future<void> debugTokenValidation() async {
    AppLogger.info('Running comprehensive token validation...', 'AuthProvider');
    final result = await _apiService.validateToken();
    if (result.success) {
      AppLogger.info('Token validation results: ${result.data}', 'AuthProvider');
      
      // Check if all endpoints failed
      final results = result.data as Map<String, dynamic>;
      final allFailed = results.values.every((result) => 
        result is Map<String, dynamic> && 
        (result['status_code'] == 401 || result['success'] == false));
      
      if (allFailed) {
        AppLogger.warning('All endpoints failed with current token, attempting refresh...', 'AuthProvider');
        await _attemptTokenRefresh();
      }
    } else {
      AppLogger.error('Token validation failed: ${result.error}', 'AuthProvider');
    }
  }

  Future<void> _attemptTokenRefresh() async {
    AppLogger.info('Attempting token refresh to resolve authentication issue...', 'AuthProvider');
    final refreshResult = await _apiService.refreshToken();
    
    if (refreshResult.success) {
      AppLogger.info('Token refresh successful, running validation again...', 'AuthProvider');
      // Run validation again with the new token
      final validationResult = await _apiService.validateToken();
      if (validationResult.success) {
        AppLogger.info('Post-refresh validation results: ${validationResult.data}', 'AuthProvider');
      }
    } else {
      AppLogger.warning('Token refresh failed: ${refreshResult.error}', 'AuthProvider');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _apiService.login(email: email, password: password);
      
      if (result.success && result.data != null) {
        _user = result.data!.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (result.success && result.data != null) {
        _user = result.data!.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.error ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadUserProfile() async {
    final result = await _apiService.getUserProfile();
    if (result.success && result.data != null) {
      // Extract user from profile data
      final profileData = result.data!;
      _user = User(
        id: profileData.id,
        email: profileData.email,
        firstName: profileData.firstName,
        lastName: profileData.lastName,
        isVerified: profileData.isVerified,
      );
      notifyListeners();
      AppLogger.info('User profile loaded successfully for: ${profileData.email}', 'AuthProvider');
    } else {
      AppLogger.warning('Failed to load user profile: ${result.error}', 'AuthProvider');
      // If it's an authentication error, clear the invalid token
      if (result.error?.contains('Authentication') == true || 
          result.error?.contains('401') == true ||
          result.error?.contains('Invalid token') == true) {
        AppLogger.info('Clearing invalid token due to authentication error', 'AuthProvider');
        await _apiService.clearToken();
        _user = null;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}