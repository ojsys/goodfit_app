import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Accessibility state
  bool _isInitialized = false;
  bool _screenReaderEnabled = false;
  bool _highContrastEnabled = false;
  bool _largeTextEnabled = false;
  bool _voiceControlEnabled = false;
  bool _reduceMotionEnabled = false;
  bool _increaseTouchTargetsEnabled = false;
  bool _colorBlindSupportEnabled = false;
  double _textScaleFactor = 1.0;
  bool _hapticNavigationEnabled = false;
  bool _announceNotificationsEnabled = false;

  // Voice control
  Timer? _voiceControlTimer;
  String _lastSpokenText = '';
  
  // Screen reader
  Timer? _screenReaderTimer;
  final List<String> _screenReaderQueue = [];
  
  // Gesture control
  bool _isListeningForGestures = false;
  
  // Color contrast
  ColorScheme? _highContrastColorScheme;
  
  // Storage key
  static const String _settingsKey = 'accessibility_settings';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get highContrastEnabled => _highContrastEnabled;
  bool get largeTextEnabled => _largeTextEnabled;
  bool get voiceControlEnabled => _voiceControlEnabled;
  bool get reduceMotionEnabled => _reduceMotionEnabled;
  bool get increaseTouchTargetsEnabled => _increaseTouchTargetsEnabled;
  bool get colorBlindSupportEnabled => _colorBlindSupportEnabled;
  double get textScaleFactor => _textScaleFactor;
  bool get hapticNavigationEnabled => _hapticNavigationEnabled;
  bool get announceNotificationsEnabled => _announceNotificationsEnabled;

  /// Initialize accessibility service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved settings
      await _loadSettings();
      
      // Setup system accessibility features
      await _setupSystemAccessibility();
      
      // Initialize screen reader if enabled
      if (_screenReaderEnabled) {
        _initializeScreenReader();
      }
      
      // Initialize voice control if enabled
      if (_voiceControlEnabled) {
        _initializeVoiceControl();
      }
      
      // Setup gesture control
      if (_hapticNavigationEnabled) {
        _initializeGestureControl();
      }
      
      _isInitialized = true;
      debugPrint('Accessibility service initialized');
      
    } catch (e) {
      debugPrint('Failed to initialize accessibility service: $e');
    }
  }

  /// Update accessibility settings
  Future<void> updateSettings({
    bool? screenReaderEnabled,
    bool? highContrastEnabled,
    bool? largeTextEnabled,
    bool? voiceControlEnabled,
    bool? reduceMotionEnabled,
    bool? increaseTouchTargetsEnabled,
    bool? colorBlindSupportEnabled,
    double? textScaleFactor,
    bool? hapticNavigationEnabled,
    bool? announceNotificationsEnabled,
  }) async {
    final oldScreenReader = _screenReaderEnabled;
    final oldVoiceControl = _voiceControlEnabled;
    final oldHapticNavigation = _hapticNavigationEnabled;

    _screenReaderEnabled = screenReaderEnabled ?? _screenReaderEnabled;
    _highContrastEnabled = highContrastEnabled ?? _highContrastEnabled;
    _largeTextEnabled = largeTextEnabled ?? _largeTextEnabled;
    _voiceControlEnabled = voiceControlEnabled ?? _voiceControlEnabled;
    _reduceMotionEnabled = reduceMotionEnabled ?? _reduceMotionEnabled;
    _increaseTouchTargetsEnabled = increaseTouchTargetsEnabled ?? _increaseTouchTargetsEnabled;
    _colorBlindSupportEnabled = colorBlindSupportEnabled ?? _colorBlindSupportEnabled;
    _textScaleFactor = textScaleFactor ?? _textScaleFactor;
    _hapticNavigationEnabled = hapticNavigationEnabled ?? _hapticNavigationEnabled;
    _announceNotificationsEnabled = announceNotificationsEnabled ?? _announceNotificationsEnabled;

    // Handle feature state changes
    if (oldScreenReader != _screenReaderEnabled) {
      if (_screenReaderEnabled) {
        _initializeScreenReader();
      } else {
        _stopScreenReader();
      }
    }

    if (oldVoiceControl != _voiceControlEnabled) {
      if (_voiceControlEnabled) {
        _initializeVoiceControl();
      } else {
        _stopVoiceControl();
      }
    }

    if (oldHapticNavigation != _hapticNavigationEnabled) {
      if (_hapticNavigationEnabled) {
        _initializeGestureControl();
      } else {
        _stopGestureControl();
      }
    }

    await _saveSettings();
    await _updateSystemAccessibility();
    notifyListeners();
  }

  /// Announce text to screen reader
  void announceText(String text, {bool interrupt = false}) {
    if (!_screenReaderEnabled) return;

    if (interrupt) {
      _screenReaderQueue.clear();
    }
    
    _screenReaderQueue.add(text);
    _processScreenReaderQueue();
  }

  /// Provide haptic feedback
  Future<void> provideFeedback(AccessibilityFeedbackType type) async {
    if (!_hapticNavigationEnabled) return;

    switch (type) {
      case AccessibilityFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
      case AccessibilityFeedbackType.impact:
        await HapticFeedback.lightImpact();
        break;
      case AccessibilityFeedbackType.notification:
        await HapticFeedback.mediumImpact();
        break;
      case AccessibilityFeedbackType.warning:
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Get accessibility-friendly color scheme
  ColorScheme getAccessibleColorScheme(ColorScheme baseScheme) {
    if (!_highContrastEnabled && !_colorBlindSupportEnabled) {
      return baseScheme;
    }

    if (_highContrastEnabled) {
      return _getHighContrastColorScheme(baseScheme);
    }

    if (_colorBlindSupportEnabled) {
      return _getColorBlindFriendlyScheme(baseScheme);
    }

    return baseScheme;
  }

  /// Get accessible text theme
  TextTheme getAccessibleTextTheme(TextTheme baseTheme) {
    if (!_largeTextEnabled && _textScaleFactor == 1.0) {
      return baseTheme;
    }

    final scaleFactor = _largeTextEnabled ? _textScaleFactor * 1.3 : _textScaleFactor;
    
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: (baseTheme.displayLarge?.fontSize ?? 96) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.displayLarge?.fontWeight,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: (baseTheme.displayMedium?.fontSize ?? 60) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.displayMedium?.fontWeight,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: (baseTheme.displaySmall?.fontSize ?? 48) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.displaySmall?.fontWeight,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.headlineLarge?.fontWeight,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.headlineMedium?.fontWeight,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: (baseTheme.headlineSmall?.fontSize ?? 24) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.headlineSmall?.fontWeight,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: (baseTheme.titleLarge?.fontSize ?? 22) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.titleLarge?.fontWeight,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: (baseTheme.titleMedium?.fontSize ?? 16) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.titleMedium?.fontWeight,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: (baseTheme.titleSmall?.fontSize ?? 14) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.titleSmall?.fontWeight,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: (baseTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: (baseTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.labelLarge?.fontWeight,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: (baseTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.labelMedium?.fontWeight,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: (baseTheme.labelSmall?.fontSize ?? 11) * scaleFactor,
        fontWeight: _largeTextEnabled ? FontWeight.w600 : baseTheme.labelSmall?.fontWeight,
      ),
    );
  }

  /// Get minimum touch target size
  double get minimumTouchTargetSize {
    return _increaseTouchTargetsEnabled ? 48.0 : 44.0;
  }

  /// Get animation duration (reduced if motion sensitivity is enabled)
  Duration getAnimationDuration(Duration baseDuration) {
    if (_reduceMotionEnabled) {
      return Duration(milliseconds: (baseDuration.inMilliseconds * 0.3).round());
    }
    return baseDuration;
  }

  /// Create semantic widget wrapper
  Widget wrapWithSemantics({
    required Widget child,
    required String label,
    String? hint,
    bool? button,
    bool? header,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button ?? false,
      header: header ?? false,
      onTap: onTap,
      child: child,
    );
  }

  /// Setup system accessibility features
  Future<void> _setupSystemAccessibility() async {
    // Configure semantic services
    SemanticsBinding.instance.ensureSemantics();
    
    // Update system accessibility settings
    await _updateSystemAccessibility();
  }

  /// Update system accessibility settings
  Future<void> _updateSystemAccessibility() async {
    // This would integrate with platform-specific accessibility APIs
    debugPrint('Updating system accessibility settings');
  }

  /// Initialize screen reader
  void _initializeScreenReader() {
    _screenReaderTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _processScreenReaderQueue();
    });
    
    announceText('Screen reader enabled', interrupt: true);
  }

  /// Stop screen reader
  void _stopScreenReader() {
    _screenReaderTimer?.cancel();
    _screenReaderTimer = null;
    _screenReaderQueue.clear();
  }

  /// Process screen reader queue
  void _processScreenReaderQueue() {
    if (_screenReaderQueue.isEmpty || _lastSpokenText.isNotEmpty) return;

    final text = _screenReaderQueue.removeAt(0);
    _speakText(text);
  }

  /// Speak text using screen reader
  void _speakText(String text) {
    if (text == _lastSpokenText) return;
    
    _lastSpokenText = text;
    debugPrint('Screen reader: $text');
    
    // Clear last spoken text after delay
    Timer(const Duration(seconds: 2), () {
      _lastSpokenText = '';
    });
  }

  /// Initialize voice control
  void _initializeVoiceControl() {
    _voiceControlTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Voice control would listen for commands here
      _processVoiceCommands();
    });
    
    announceText('Voice control enabled');
  }

  /// Stop voice control
  void _stopVoiceControl() {
    _voiceControlTimer?.cancel();
    _voiceControlTimer = null;
  }

  /// Process voice commands
  void _processVoiceCommands() {
    // This would integrate with speech recognition
    // For now, we'll just simulate the service running
  }

  /// Initialize gesture control
  void _initializeGestureControl() {
    _isListeningForGestures = true;
    provideFeedback(AccessibilityFeedbackType.notification);
  }

  /// Stop gesture control
  void _stopGestureControl() {
    _isListeningForGestures = false;
  }

  /// Get high contrast color scheme
  ColorScheme _getHighContrastColorScheme(ColorScheme baseScheme) {
    return baseScheme.copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.black,
      onSecondary: Colors.white,
      background: Colors.white,
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red.shade900,
      onError: Colors.white,
    );
  }

  /// Get color blind friendly scheme
  ColorScheme _getColorBlindFriendlyScheme(ColorScheme baseScheme) {
    // Adjust colors for color blind users
    return baseScheme.copyWith(
      primary: Colors.blue.shade700,
      secondary: Colors.orange.shade700,
      error: Colors.red.shade800,
    );
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        _screenReaderEnabled = settings['screen_reader_enabled'] ?? false;
        _highContrastEnabled = settings['high_contrast_enabled'] ?? false;
        _largeTextEnabled = settings['large_text_enabled'] ?? false;
        _voiceControlEnabled = settings['voice_control_enabled'] ?? false;
        _reduceMotionEnabled = settings['reduce_motion_enabled'] ?? false;
        _increaseTouchTargetsEnabled = settings['increase_touch_targets_enabled'] ?? false;
        _colorBlindSupportEnabled = settings['color_blind_support_enabled'] ?? false;
        _textScaleFactor = (settings['text_scale_factor'] ?? 1.0).toDouble();
        _hapticNavigationEnabled = settings['haptic_navigation_enabled'] ?? false;
        _announceNotificationsEnabled = settings['announce_notifications_enabled'] ?? false;
      }
    } catch (e) {
      debugPrint('Error loading accessibility settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'screen_reader_enabled': _screenReaderEnabled,
        'high_contrast_enabled': _highContrastEnabled,
        'large_text_enabled': _largeTextEnabled,
        'voice_control_enabled': _voiceControlEnabled,
        'reduce_motion_enabled': _reduceMotionEnabled,
        'increase_touch_targets_enabled': _increaseTouchTargetsEnabled,
        'color_blind_support_enabled': _colorBlindSupportEnabled,
        'text_scale_factor': _textScaleFactor,
        'haptic_navigation_enabled': _hapticNavigationEnabled,
        'announce_notifications_enabled': _announceNotificationsEnabled,
      };
      
      await prefs.setString(_settingsKey, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving accessibility settings: $e');
    }
  }

  @override
  void dispose() {
    _screenReaderTimer?.cancel();
    _voiceControlTimer?.cancel();
    super.dispose();
  }
}

enum AccessibilityFeedbackType {
  selection,
  impact,
  notification,
  warning,
}

/// Accessible button widget
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed != null ? () {
        accessibilityService.provideFeedback(AccessibilityFeedbackType.selection);
        onPressed!();
      } : null,
      child: SizedBox(
        width: accessibilityService.minimumTouchTargetSize,
        height: accessibilityService.minimumTouchTargetSize,
        child: InkWell(
          onTap: onPressed != null ? () {
            accessibilityService.provideFeedback(AccessibilityFeedbackType.selection);
            onPressed!();
          } : null,
          child: child,
        ),
      ),
    );
  }
}

/// Accessible text field widget
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}

/// Accessible card widget
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback? onTap;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      onTap: onTap != null ? () {
        accessibilityService.provideFeedback(AccessibilityFeedbackType.selection);
        onTap!();
      } : null,
      child: Card(
        child: InkWell(
          onTap: onTap != null ? () {
            accessibilityService.provideFeedback(AccessibilityFeedbackType.selection);
            onTap!();
          } : null,
          child: child,
        ),
      ),
    );
  }
}