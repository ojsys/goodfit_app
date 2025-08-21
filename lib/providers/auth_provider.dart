import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  static const String _userKey = 'stored_user';
  static const String _userProfileKey = 'stored_user_profile';

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _apiService.isAuthenticated && _user != null;

  Future<void> init() async {
    await _apiService.init();
    
    // Try to load stored user data first
    await _loadStoredUserData();
    
    if (_apiService.isAuthenticated) {
      // Try to load user profile to validate token
      try {
        await loadUserProfile();
      } catch (e) {
        AppLogger.info('Token validation failed on startup, clearing invalid token', 'AuthProvider');
        // Clear invalid token to prevent authentication issues
        await _apiService.clearToken();
        await _clearStoredUserData();
        _user = null;
        _userProfile = null;
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
        await _saveUserData();
        await loadUserProfile(); // Load full profile after login
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
        await _saveUserData();
        await loadUserProfile(); // Load full profile after registration
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
      // Store both user and profile data
      final profileData = result.data!;
      _userProfile = profileData;
      _user = User(
        id: profileData.id,
        email: profileData.email,
        firstName: profileData.firstName,
        lastName: profileData.lastName,
        isVerified: profileData.isVerified,
      );
      
      // Persist user data
      await _saveUserData();
      await _saveUserProfile();
      
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
        await _clearStoredUserData();
        _user = null;
        _userProfile = null;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _clearStoredUserData();
    _user = null;
    _userProfile = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private methods for persistent storage
  Future<void> _saveUserData() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
      AppLogger.info('User data saved to persistent storage', 'AuthProvider');
    }
  }

  Future<void> _saveUserProfile() async {
    if (_userProfile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, jsonEncode(_userProfile!.toJson()));
      AppLogger.info('User profile saved to persistent storage', 'AuthProvider');
    }
  }

  Future<void> _loadStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user data
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _user = User.fromJson(userData);
        AppLogger.info('Loaded stored user data for: ${_user!.email}', 'AuthProvider');
      }
      
      // Load user profile data
      final profileJson = prefs.getString(_userProfileKey);
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        _userProfile = UserProfile.fromJson(profileData);
        AppLogger.info('Loaded stored user profile data', 'AuthProvider');
      }
      
      if (_user != null || _userProfile != null) {
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Failed to load stored user data: $e', 'AuthProvider');
      await _clearStoredUserData();
    }
  }

  Future<void> _clearStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_userProfileKey);
      AppLogger.info('Cleared stored user data', 'AuthProvider');
    } catch (e) {
      AppLogger.error('Failed to clear stored user data: $e', 'AuthProvider');
    }
  }

  Future<bool> updateBasicProfile({
    String? firstName,
    String? lastName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _apiService.updateBasicProfile(
        firstName: firstName,
        lastName: lastName,
      );
      
      if (result.success) {
        // Update local user data
        if (_user != null) {
          _user = User(
            id: _user!.id,
            email: _user!.email,
            firstName: firstName ?? _user!.firstName,
            lastName: lastName ?? _user!.lastName,
            isVerified: _user!.isVerified,
          );
          await _saveUserData();
          notifyListeners();
        }
        _setLoading(false);
        AppLogger.info('Basic profile updated successfully', 'AuthProvider');
        return true;
      } else {
        _setError(result.error ?? 'Failed to update basic profile');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      AppLogger.error('Error updating basic profile', 'AuthProvider', e);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    DateTime? birthDate,
    String? gender,
    List<String>? interests,
    String? datingIntentions,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Update basic profile first if needed
      if (firstName != null || lastName != null) {
        final basicResult = await updateBasicProfile(
          firstName: firstName,
          lastName: lastName,
        );
        if (!basicResult) {
          return false;
        }
      }

      // Update extended profile
      final result = await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        birthDate: birthDate,
        gender: gender,
        interests: interests,
        datingIntentions: datingIntentions,
        phoneNumber: phoneNumber,
      );
      
      if (result.success && result.data != null) {
        // Update local profile data
        _userProfile = result.data!;
        
        // Also update user data with any basic profile changes
        if (firstName != null || lastName != null) {
          _user = User(
            id: _user!.id,
            email: _user!.email,
            firstName: firstName ?? _user!.firstName,
            lastName: lastName ?? _user!.lastName,
            isVerified: _user!.isVerified,
          );
          await _saveUserData();
        }
        
        await _saveUserProfile();
        notifyListeners();
        _setLoading(false);
        AppLogger.info('Profile updated successfully', 'AuthProvider');
        return true;
      } else {
        _setError(result.error ?? 'Failed to update profile');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      AppLogger.error('Error updating profile', 'AuthProvider', e);
      return false;
    }
  }

  Future<bool> updateFitnessProfile({
    String? activityLevel,
    List<String>? fitnessGoals,
    List<String>? favoriteActivities,
    int? workoutFrequency,
    String? preferredWorkoutTime,
    String? gymMembership,
    String? injuriesLimitations,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _apiService.updateFitnessProfile(
        activityLevel: activityLevel,
        fitnessGoals: fitnessGoals,
        favoriteActivities: favoriteActivities,
        workoutFrequency: workoutFrequency,
        preferredWorkoutTime: preferredWorkoutTime,
        gymMembership: gymMembership,
        injuriesLimitations: injuriesLimitations,
      );
      
      if (result.success) {
        // Reload the full profile to ensure all data is synchronized
        await loadUserProfile();
        _setLoading(false);
        AppLogger.info('Fitness profile updated successfully', 'AuthProvider');
        return true;
      } else {
        _setError(result.error ?? 'Failed to update fitness profile');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      AppLogger.error('Error updating fitness profile', 'AuthProvider', e);
      return false;
    }
  }

  Future<bool> updatePrivacySettings({
    bool? showProfilePublicly,
    bool? showFitnessData,
    bool? showLocation,
    bool? showOnlineStatus,
    bool? allowMessagesFromStrangers,
    bool? showInDiscovery,
    bool? shareWorkoutData,
    bool? showAge,
    bool? showDistance,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _apiService.updatePrivacySettings(
        showProfilePublicly: showProfilePublicly,
        showFitnessData: showFitnessData,
        showLocation: showLocation,
        showOnlineStatus: showOnlineStatus,
        allowMessagesFromStrangers: allowMessagesFromStrangers,
        showInDiscovery: showInDiscovery,
        shareWorkoutData: shareWorkoutData,
        showAge: showAge,
        showDistance: showDistance,
      );
      
      if (result.success) {
        // Reload the full profile to ensure all data is synchronized
        await loadUserProfile();
        _setLoading(false);
        AppLogger.info('Privacy settings updated successfully', 'AuthProvider');
        return true;
      } else {
        _setError(result.error ?? 'Failed to update privacy settings');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      AppLogger.error('Error updating privacy settings', 'AuthProvider', e);
      return false;
    }
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _apiService.uploadProfileImage(imageFile);
      
      if (result.success) {
        // Reload user profile to get updated image URL
        await loadUserProfile();
        _setLoading(false);
        AppLogger.info('Profile image uploaded successfully', 'AuthProvider');
        return true;
      } else {
        _setError(result.error ?? 'Failed to upload profile image');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      _setLoading(false);
      AppLogger.error('Error uploading profile image', 'AuthProvider', e);
      return false;
    }
  }
}