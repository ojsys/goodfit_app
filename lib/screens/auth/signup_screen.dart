import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // User preferences
  String? selectedGoal;
  final List<String> selectedActivities = [];

  @override
  void initState() {
    super.initState();
    // Add listeners to update the UI when text changes
    _firstNameController.addListener(_updateContinueButton);
    _lastNameController.addListener(_updateContinueButton);
    _middleNameController.addListener(_updateContinueButton);
    _emailController.addListener(_updateContinueButton);
    _passwordController.addListener(_updateContinueButton);
    _confirmPasswordController.addListener(_updateContinueButton);
  }

  void _updateContinueButton() {
    setState(() {
      // This will trigger a rebuild and update the button state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with Back Button
            if (_currentStep > 0)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back_ios),
                  color: AppTheme.primaryColor,
                ),
              ),
            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _buildProgressIndicator(),
            ),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildBasicInfoStep(),
                  _buildGoalSelectionStep(),
                  _buildActivityPreferencesStep(),
                  _buildPhotoUploadStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final stepTitles = ['Account', 'Goals', 'Interests', 'Photo'];
    
    return Column(
      children: [
        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;
            
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted 
                          ? AppTheme.primaryColor
                          : isCurrent 
                              ? AppTheme.primaryColor.withValues(alpha: 0.7)
                              : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepTitles[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrent ? AppTheme.primaryColor : Colors.grey.shade600,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Progress bar
        LinearProgressIndicator(
          value: (_currentStep + 1) / 4,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "Let's get started...",
            style: GoogleFonts.poly(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about yourself',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // First Name Field
                  _buildTextField(
                    controller: _firstNameController,
                    hintText: 'First Name',
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Last Name Field
                  _buildTextField(
                    controller: _lastNameController,
                    hintText: 'Last Name',
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Middle Name Field (Optional)
                  _buildTextField(
                    controller: _middleNameController,
                    hintText: 'Middle Name (Optional)',
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Create Password (min. 6 characters)',
                    obscureText: true,
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  _buildConfirmPasswordField(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_canProceedFromBasicInfo()) {
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    final hasText = _confirmPasswordController.text.isNotEmpty;
    final passwordsMatch = _passwordsMatch();
    final showError = hasText && !passwordsMatch;

    return TextField(
      controller: _confirmPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'Confirm Password',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: showError ? Colors.red : AppTheme.primaryColor,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: showError ? Colors.red : Colors.grey.shade300,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        errorText: showError ? 'Passwords do not match' : null,
        suffixIcon: hasText
            ? Icon(
                passwordsMatch ? Icons.check_circle : Icons.error,
                color: passwordsMatch ? Colors.green : Colors.red,
              )
            : null,
      ),
    );
  }

  Widget _buildGoalSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'What brings you here?',
            style: GoogleFonts.poly(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose your main goal',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          
          Expanded(
            child: ListView(
              children: [
                _buildGoalOption(
                  'community',
                  'Community',
                  'Find workout buddies & friends',
                  Icons.group,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildGoalOption(
                  'fitness',
                  'Fitness',
                  'Focus on health & wellness',
                  Icons.favorite,
                  Colors.red,
                ),
                const SizedBox(height: 16),
                _buildGoalOption(
                  'romantic',
                  'Romantic',
                  'Date active & healthy people',
                  Icons.favorite_border,
                  Colors.pink,
                ),
                const SizedBox(height: 16),
                _buildGoalOption(
                  'all',
                  'All of the above',
                  'Keep my options open',
                  Icons.star,
                  Colors.amber,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedGoal != null ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPreferencesStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'What moves you?',
            style: GoogleFonts.poly(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your interests (min. of 3)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final activities = [
                  {'name': 'Running', 'icon': Icons.directions_run},
                  {'name': 'Cycling', 'icon': Icons.directions_bike},
                  {'name': 'Strength', 'icon': Icons.fitness_center},
                  {'name': 'Yoga', 'icon': Icons.self_improvement},
                  {'name': 'Hiking', 'icon': Icons.terrain},
                  {'name': 'More', 'icon': Icons.add},
                ];
                
                final activity = activities[index];
                final isSelected = selectedActivities.contains(activity['name']);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedActivities.remove(activity['name']);
                      } else {
                        selectedActivities.add(activity['name'] as String);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          activity['icon'] as IconData,
                          size: 40,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activity['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.primaryColor : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedActivities.length >= 3 ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Show your best self!',
            style: GoogleFonts.poly(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a profile photo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          
          const Spacer(),
          
          // Photo upload area
          Center(
            child: GestureDetector(
              onTap: () {
                // Handle photo upload
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to add photo',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Upload Photo Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle photo upload
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upload Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Skip Button
          SizedBox(
            width: double.infinity,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return OutlinedButton(
                  onPressed: authProvider.isLoading ? null : () async {
                    await _completeSignup(authProvider);
                  },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        )
                      : const Text(
                          'Complete Signup',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String id, String title, String subtitle, IconData icon, Color color) {
    final isSelected = selectedGoal == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  bool _canProceedFromBasicInfo() {
    return _firstNameController.text.trim().isNotEmpty &&
           _lastNameController.text.trim().isNotEmpty &&
           _isValidEmail(_emailController.text) &&
           _passwordController.text.length >= 6 &&
           _confirmPasswordController.text.isNotEmpty &&
           _passwordsMatch();
  }

  bool _passwordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _completeSignup(AuthProvider authProvider) async {
    authProvider.clearError();
    
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Signup failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}