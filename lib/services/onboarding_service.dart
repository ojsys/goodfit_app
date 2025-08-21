import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService extends ChangeNotifier {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  // Onboarding state
  bool _isFirstLaunch = true;
  bool _hasCompletedInitialSetup = false;
  Set<String> _completedTutorials = <String>{};
  Map<String, dynamic> _userPreferences = {};
  
  // Onboarding steps
  final List<OnboardingStep> _onboardingSteps = [];
  int _currentStepIndex = 0;
  
  // Tutorial state
  bool _isTutorialActive = false;
  String? _activeTutorialId;
  int _currentTutorialStep = 0;

  // Storage keys
  static const String _firstLaunchKey = 'first_launch';
  static const String _setupCompleteKey = 'setup_complete';
  static const String _completedTutorialsKey = 'completed_tutorials';
  static const String _userPreferencesKey = 'user_preferences';

  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get hasCompletedInitialSetup => _hasCompletedInitialSetup;
  Set<String> get completedTutorials => Set.unmodifiable(_completedTutorials);
  bool get isTutorialActive => _isTutorialActive;
  String? get activeTutorialId => _activeTutorialId;
  List<OnboardingStep> get onboardingSteps => List.unmodifiable(_onboardingSteps);
  int get currentStepIndex => _currentStepIndex;
  bool get hasCompletedOnboarding => _currentStepIndex >= _onboardingSteps.length;

  /// Initialize onboarding service
  Future<void> initialize() async {
    await _loadOnboardingState();
    _setupOnboardingSteps();
    notifyListeners();
  }

  /// Start onboarding flow
  Future<void> startOnboarding() async {
    _currentStepIndex = 0;
    notifyListeners();
  }

  /// Complete current onboarding step
  Future<void> completeCurrentStep() async {
    if (_currentStepIndex < _onboardingSteps.length) {
      final step = _onboardingSteps[_currentStepIndex];
      
      // Save step completion
      await _saveStepCompletion(step);
      
      _currentStepIndex++;
      
      // Check if onboarding is complete
      if (hasCompletedOnboarding) {
        await _completeOnboarding();
      }
      
      notifyListeners();
    }
  }

  /// Skip onboarding
  Future<void> skipOnboarding() async {
    _currentStepIndex = _onboardingSteps.length;
    await _completeOnboarding();
    notifyListeners();
  }

  /// Start a specific tutorial
  Future<void> startTutorial(String tutorialId) async {
    if (_completedTutorials.contains(tutorialId)) {
      // Already completed, but allow replay
      debugPrint('Tutorial $tutorialId already completed, replaying...');
    }

    _isTutorialActive = true;
    _activeTutorialId = tutorialId;
    _currentTutorialStep = 0;
    
    notifyListeners();
  }

  /// Complete current tutorial step
  void nextTutorialStep() {
    if (_isTutorialActive) {
      _currentTutorialStep++;
      notifyListeners();
    }
  }

  /// Complete tutorial
  Future<void> completeTutorial() async {
    if (_activeTutorialId != null) {
      _completedTutorials.add(_activeTutorialId!);
      await _saveCompletedTutorials();
    }
    
    _isTutorialActive = false;
    _activeTutorialId = null;
    _currentTutorialStep = 0;
    
    notifyListeners();
  }

  /// Skip tutorial
  void skipTutorial() {
    _isTutorialActive = false;
    _activeTutorialId = null;
    _currentTutorialStep = 0;
    
    notifyListeners();
  }

  /// Check if tutorial should be shown
  bool shouldShowTutorial(String tutorialId) {
    return !_completedTutorials.contains(tutorialId) && 
           _hasCompletedInitialSetup;
  }

  /// Save user preference
  Future<void> saveUserPreference(String key, dynamic value) async {
    _userPreferences[key] = value;
    await _saveUserPreferences();
    notifyListeners();
  }

  /// Get user preference
  T? getUserPreference<T>(String key, {T? defaultValue}) {
    return _userPreferences[key] as T? ?? defaultValue;
  }

  /// Get onboarding progress percentage
  double getOnboardingProgress() {
    if (_onboardingSteps.isEmpty) return 1.0;
    return (_currentStepIndex / _onboardingSteps.length).clamp(0.0, 1.0);
  }

  /// Reset onboarding (for testing/debugging)
  Future<void> resetOnboarding() async {
    _isFirstLaunch = true;
    _hasCompletedInitialSetup = false;
    _completedTutorials.clear();
    _currentStepIndex = 0;
    _isTutorialActive = false;
    _activeTutorialId = null;
    _currentTutorialStep = 0;
    
    await _saveOnboardingState();
    notifyListeners();
  }

  /// Setup onboarding steps
  void _setupOnboardingSteps() {
    _onboardingSteps.clear();
    
    _onboardingSteps.addAll([
      OnboardingStep(
        id: 'welcome',
        title: 'Welcome to GoodFit!',
        description: 'Your personal fitness companion for tracking activities and achieving goals.',
        icon: Icons.fitness_center,
        color: Colors.blue,
        isRequired: true,
      ),
      
      OnboardingStep(
        id: 'permissions',
        title: 'Grant Permissions',
        description: 'We need location access for GPS tracking and storage for saving your data.',
        icon: Icons.security,
        color: Colors.orange,
        isRequired: true,
        action: OnboardingAction.requestPermissions,
      ),
      
      OnboardingStep(
        id: 'profile_setup',
        title: 'Set Up Your Profile',
        description: 'Tell us about yourself to get personalized recommendations.',
        icon: Icons.person,
        color: Colors.green,
        isRequired: true,
        action: OnboardingAction.setupProfile,
      ),
      
      OnboardingStep(
        id: 'goals',
        title: 'Create Your First Goal',
        description: 'Set a fitness goal to start tracking your progress.',
        icon: Icons.flag,
        color: Colors.purple,
        isRequired: false,
        action: OnboardingAction.createGoal,
      ),
      
      OnboardingStep(
        id: 'discover_routes',
        title: 'Discover Routes',
        description: 'Explore routes near you and find your next adventure.',
        icon: Icons.explore,
        color: Colors.teal,
        isRequired: false,
        action: OnboardingAction.discoverRoutes,
      ),
      
      OnboardingStep(
        id: 'notifications',
        title: 'Stay Motivated',
        description: 'Enable notifications to get reminders and celebrate achievements.',
        icon: Icons.notifications,
        color: Colors.amber,
        isRequired: false,
        action: OnboardingAction.setupNotifications,
      ),
    ]);
  }

  /// Load onboarding state from storage
  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
      _hasCompletedInitialSetup = prefs.getBool(_setupCompleteKey) ?? false;
      
      // Load completed tutorials
      final tutorialsJson = prefs.getString(_completedTutorialsKey);
      if (tutorialsJson != null) {
        final List<dynamic> tutorialsList = jsonDecode(tutorialsJson);
        _completedTutorials = tutorialsList.cast<String>().toSet();
      }
      
      // Load user preferences
      final preferencesJson = prefs.getString(_userPreferencesKey);
      if (preferencesJson != null) {
        _userPreferences = Map<String, dynamic>.from(jsonDecode(preferencesJson));
      }
      
    } catch (e) {
      debugPrint('Error loading onboarding state: $e');
    }
  }

  /// Save onboarding state to storage
  Future<void> _saveOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_firstLaunchKey, _isFirstLaunch);
      await prefs.setBool(_setupCompleteKey, _hasCompletedInitialSetup);
      
    } catch (e) {
      debugPrint('Error saving onboarding state: $e');
    }
  }

  /// Save completed tutorials
  Future<void> _saveCompletedTutorials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tutorialsJson = jsonEncode(_completedTutorials.toList());
      await prefs.setString(_completedTutorialsKey, tutorialsJson);
      
    } catch (e) {
      debugPrint('Error saving completed tutorials: $e');
    }
  }

  /// Save user preferences
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = jsonEncode(_userPreferences);
      await prefs.setString(_userPreferencesKey, preferencesJson);
      
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }

  /// Save step completion
  Future<void> _saveStepCompletion(OnboardingStep step) async {
    // Save any step-specific data
    await saveUserPreference('step_${step.id}_completed', true);
    await saveUserPreference('step_${step.id}_completed_at', DateTime.now().toIso8601String());
  }

  /// Complete onboarding
  Future<void> _completeOnboarding() async {
    _isFirstLaunch = false;
    _hasCompletedInitialSetup = true;
    await _saveOnboardingState();
    
    // Save completion timestamp
    await saveUserPreference('onboarding_completed_at', DateTime.now().toIso8601String());
  }
}

enum OnboardingAction {
  none,
  requestPermissions,
  setupProfile,
  createGoal,
  discoverRoutes,
  setupNotifications,
}

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isRequired;
  final OnboardingAction action;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isRequired = false,
    this.action = OnboardingAction.none,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'is_required': isRequired,
      'action': action.name,
    };
  }
}

class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final String tutorialId;
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;

  const TutorialOverlay({
    super.key,
    required this.child,
    required this.tutorialId,
    required this.steps,
    this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late OnboardingService _onboardingService;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _onboardingService = OnboardingService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    // Start tutorial if this is the active one
    if (_onboardingService.activeTutorialId == widget.tutorialId) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingService>(
      builder: (context, service, child) {
        final isActive = service.activeTutorialId == widget.tutorialId;
        
        if (!isActive) {
          return widget.child;
        }

        return Stack(
          children: [
            widget.child,
            
            // Tutorial overlay
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTutorialOverlay(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTutorialOverlay() {
    if (_currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];
    
    return Container(
      color: Colors.black54,
      child: Stack(
        children: [
          // Backdrop tap to skip
          GestureDetector(
            onTap: _skipTutorial,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          
          // Tutorial content
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    Row(
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of ${widget.steps.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _skipTutorial,
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Title and description
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      step.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _skipTutorial,
                          child: const Text('Skip'),
                        ),
                        
                        ElevatedButton(
                          onPressed: _nextStep,
                          child: Text(_currentStep == widget.steps.length - 1 ? 'Done' : 'Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _onboardingService.nextTutorialStep();
    } else {
      _completeTutorial();
    }
  }

  void _skipTutorial() {
    _onboardingService.skipTutorial();
    _animationController.reverse();
  }

  void _completeTutorial() {
    _onboardingService.completeTutorial();
    widget.onComplete?.call();
    _animationController.reverse();
  }
}

class TutorialStep {
  final String title;
  final String description;
  final GlobalKey? targetKey;

  const TutorialStep({
    required this.title,
    required this.description,
    this.targetKey,
  });
}

// Provider for easy access
class Consumer<T extends ChangeNotifier> extends AnimatedBuilder {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  Consumer({
    super.key,
    required this.builder,
    this.child,
  }) : super(
    animation: OnboardingService() as Listenable,
    builder: (context, child) => builder(context, OnboardingService() as T, child),
  );
}