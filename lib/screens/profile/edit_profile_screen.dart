import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/logger.dart';

class EditProfileScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const EditProfileScreen({super.key, this.initialTabIndex = 0});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _basicFormKey = GlobalKey<FormState>();
  final _fitnessFormKey = GlobalKey<FormState>();
  final _preferencesFormKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  
  // Basic Profile Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Image handling
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Profile Data
  DateTime? _birthDate;
  String? _selectedGender;
  List<String> _interests = [];
  String? _datingIntentions;
  
  // Fitness Profile Data
  String? _activityLevel;
  List<String> _fitnessGoals = [];
  List<String> _favoriteActivities = [];
  int? _workoutFrequency;
  String? _preferredWorkoutTime;
  String? _gymMembership;
  final _injuriesController = TextEditingController();
  
  // Privacy Settings
  bool _showProfilePublicly = true;
  bool _showFitnessData = true;
  bool _showLocation = true;
  bool _showOnlineStatus = true;
  bool _allowMessagesFromStrangers = true;
  bool _showInDiscovery = true;
  bool _shareWorkoutData = true;
  bool _showAge = true;
  bool _showDistance = true;

  // Constants for dropdowns
  static const List<String> _genderOptions = ['M', 'F', 'NB', 'O', 'P'];
  static const Map<String, String> _genderLabels = {
    'M': 'Male',
    'F': 'Female', 
    'NB': 'Non-binary',
    'O': 'Other',
    'P': 'Prefer not to say'
  };

  static const List<String> _datingIntentionOptions = [
    'serious', 'casual', 'fitness_buddy', 'friends', 'networking'
  ];
  static const Map<String, String> _datingIntentionLabels = {
    'serious': 'Serious relationship',
    'casual': 'Casual dating',
    'fitness_buddy': 'Fitness buddy',
    'friends': 'Friends',
    'networking': 'Networking'
  };

  static const List<String> _activityLevelOptions = [
    'sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active'
  ];
  static const Map<String, String> _activityLevelLabels = {
    'sedentary': 'Sedentary (little to no exercise)',
    'lightly_active': 'Lightly active (1-3 days/week)',
    'moderately_active': 'Moderately active (3-5 days/week)',
    'very_active': 'Very active (6-7 days/week)',
    'extremely_active': 'Extremely active (2x/day)'
  };

  static const List<String> _workoutTimeOptions = [
    'early_morning', 'morning', 'afternoon', 'evening', 'night', 'flexible'
  ];
  static const Map<String, String> _workoutTimeLabels = {
    'early_morning': 'Early morning (5-7 AM)',
    'morning': 'Morning (7-11 AM)',
    'afternoon': 'Afternoon (11 AM-5 PM)',
    'evening': 'Evening (5-9 PM)',
    'night': 'Night (9 PM-12 AM)',
    'flexible': 'Flexible'
  };

  static const List<String> _availableFitnessGoals = [
    'weight_loss', 'muscle_gain', 'endurance', 'strength', 'flexibility',
    'health_maintenance', 'sport_specific', 'rehabilitation'
  ];

  static const List<String> _availableActivities = [
    'running', 'cycling', 'swimming', 'gym', 'yoga', 'pilates', 'hiking',
    'tennis', 'basketball', 'soccer', 'climbing', 'dancing', 'boxing', 'crossfit'
  ];

  static const List<String> _availableInterests = [
    'travel', 'music', 'movies', 'books', 'cooking', 'photography', 'art',
    'technology', 'gaming', 'nature', 'animals', 'volunteering', 'spirituality',
    'fashion', 'food', 'wine', 'coffee', 'adventure', 'meditation', 'wellness'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: widget.initialTabIndex,
    );
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _injuriesController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final userProfile = authProvider.userProfile;

    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
    }

    if (userProfile != null) {
      // Basic profile data
      _bioController.text = userProfile.bio ?? '';
      _birthDate = userProfile.birthDate;
      _selectedGender = userProfile.gender;
      _interests = List.from(userProfile.interests);
      _datingIntentions = userProfile.datingIntentions;
      _phoneController.text = userProfile.phoneNumber ?? '';
      
      // Fitness profile data
      _activityLevel = userProfile.activityLevel;
      _fitnessGoals = List.from(userProfile.fitnessGoals ?? []);
      _favoriteActivities = List.from(userProfile.favoriteActivities ?? []);
      _workoutFrequency = userProfile.workoutFrequency;
      _preferredWorkoutTime = userProfile.preferredWorkoutTime;
      _gymMembership = userProfile.gymMembership;
      _injuriesController.text = userProfile.injuriesLimitations ?? '';
      
      // Privacy settings
      _showProfilePublicly = userProfile.showProfilePublicly ?? true;
      _showFitnessData = userProfile.showFitnessData ?? true;
      _showLocation = userProfile.showLocation ?? true;
      _showOnlineStatus = userProfile.showOnlineStatus ?? true;
      _allowMessagesFromStrangers = userProfile.allowMessagesFromStrangers ?? true;
      _showInDiscovery = userProfile.showInDiscovery ?? true;
      _shareWorkoutData = userProfile.shareWorkoutData ?? true;
      _showAge = userProfile.showAge ?? true;
      _showDistance = userProfile.showDistance ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Fitness'),
            Tab(text: 'Privacy'),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildFitnessTab(),
          _buildPrivacyTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Form(
      key: _basicFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              'Profile Photo',
              Icons.photo_camera,
              [
                _buildProfileImageSection(),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Personal Information',
              Icons.person_outline,
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _firstNameController,
                        label: 'First Name',
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _bioController,
                  label: 'Bio',
                  maxLines: 3,
                  maxLength: 500,
                  hint: 'Tell others about yourself...',
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Personal Details',
              Icons.info_outline,
              [
                _buildDatePicker(
                  'Birth Date',
                  _birthDate,
                  (date) => setState(() => _birthDate = date),
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  'Gender',
                  _selectedGender,
                  _genderOptions.map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(_genderLabels[value] ?? value),
                  )).toList(),
                  (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  'Dating Intentions',
                  _datingIntentions,
                  _datingIntentionOptions.map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(_datingIntentionLabels[value] ?? value),
                  )).toList(),
                  (value) => setState(() => _datingIntentions = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Interests',
              Icons.favorite_outline,
              [
                _buildMultiSelectChips(
                  'Select your interests',
                  _availableInterests,
                  _interests,
                  (selected) => setState(() => _interests = selected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessTab() {
    return Form(
      key: _fitnessFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard(
              'Activity Level',
              Icons.fitness_center,
              [
                _buildDropdownField<String>(
                  'Current Activity Level',
                  _activityLevel,
                  _activityLevelOptions.map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(_activityLevelLabels[value] ?? value),
                  )).toList(),
                  (value) => setState(() => _activityLevel = value),
                ),
                const SizedBox(height: 16),
                _buildSliderField(
                  'Weekly Workout Frequency',
                  _workoutFrequency?.toDouble() ?? 0,
                  0,
                  7,
                  '${_workoutFrequency ?? 0} times per week',
                  (value) => setState(() => _workoutFrequency = value.toInt()),
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  'Preferred Workout Time',
                  _preferredWorkoutTime,
                  _workoutTimeOptions.map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(_workoutTimeLabels[value] ?? value),
                  )).toList(),
                  (value) => setState(() => _preferredWorkoutTime = value),
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: TextEditingController(text: _gymMembership ?? ''),
                  label: 'Gym Membership',
                  hint: 'e.g., Planet Fitness, LA Fitness',
                  onChanged: (value) => _gymMembership = value,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Fitness Goals',
              Icons.flag_outlined,
              [
                _buildMultiSelectChips(
                  'What are your fitness goals?',
                  _availableFitnessGoals.map((goal) => goal.replaceAll('_', ' ').toLowerCase()).toList(),
                  _fitnessGoals,
                  (selected) => setState(() => _fitnessGoals = selected),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Favorite Activities',
              Icons.sports,
              [
                _buildMultiSelectChips(
                  'What activities do you enjoy?',
                  _availableActivities.map((activity) => activity.toLowerCase()).toList(),
                  _favoriteActivities,
                  (selected) => setState(() => _favoriteActivities = selected),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Health & Safety',
              Icons.health_and_safety_outlined,
              [
                _buildTextFormField(
                  controller: _injuriesController,
                  label: 'Injuries or Limitations',
                  maxLines: 3,
                  maxLength: 500,
                  hint: 'Any injuries or physical limitations to be aware of...',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return Form(
      key: _preferencesFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard(
              'Profile Visibility',
              Icons.visibility_outlined,
              [
                _buildSwitchTile(
                  'Show profile publicly',
                  'Allow others to see your profile',
                  _showProfilePublicly,
                  (value) => setState(() => _showProfilePublicly = value),
                ),
                _buildSwitchTile(
                  'Show fitness data',
                  'Display your workout stats and activities',
                  _showFitnessData,
                  (value) => setState(() => _showFitnessData = value),
                ),
                _buildSwitchTile(
                  'Show location',
                  'Allow others to see your general location',
                  _showLocation,
                  (value) => setState(() => _showLocation = value),
                ),
                _buildSwitchTile(
                  'Show age',
                  'Display your age on your profile',
                  _showAge,
                  (value) => setState(() => _showAge = value),
                ),
                _buildSwitchTile(
                  'Show distance',
                  'Display distance from other users',
                  _showDistance,
                  (value) => setState(() => _showDistance = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Discovery & Messaging',
              Icons.explore_outlined,
              [
                _buildSwitchTile(
                  'Show in discovery',
                  'Appear in other users\' discovery feed',
                  _showInDiscovery,
                  (value) => setState(() => _showInDiscovery = value),
                ),
                _buildSwitchTile(
                  'Show online status',
                  'Let others know when you\'re online',
                  _showOnlineStatus,
                  (value) => setState(() => _showOnlineStatus = value),
                ),
                _buildSwitchTile(
                  'Allow messages from strangers',
                  'Receive messages from users you haven\'t matched with',
                  _allowMessagesFromStrangers,
                  (value) => setState(() => _allowMessagesFromStrangers = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSectionCard(
              'Data Sharing',
              Icons.share_outlined,
              [
                _buildSwitchTile(
                  'Share workout data',
                  'Allow sharing of workout details with matches',
                  _shareWorkoutData,
                  (value) => setState(() => _shareWorkoutData = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    void Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    selectedDate != null
                        ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                        : 'Select date',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderField(
    String label,
    double value,
    double min,
    double max,
    String valueText,
    void Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(valueText, style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppTheme.primaryColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips(
    String label,
    List<String> options,
    List<String> selected,
    void Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option.replaceAll('_', ' ').toUpperCase()),
              selected: isSelected,
              onSelected: (isSelected) {
                final newSelected = List<String>.from(selected);
                if (isSelected) {
                  newSelected.add(option);
                } else {
                  newSelected.remove(option);
                }
                onChanged(newSelected);
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Validate current tab form
      bool isValid = true;
      if (_tabController.index == 0) {
        isValid = _basicFormKey.currentState?.validate() ?? false;
      } else if (_tabController.index == 1) {
        isValid = _fitnessFormKey.currentState?.validate() ?? false;
      } else {
        isValid = _preferencesFormKey.currentState?.validate() ?? false;
      }

      if (!isValid) {
        setState(() => _isLoading = false);
        return;
      }

      AppLogger.info('Saving profile data...', 'EditProfileScreen');
      
      bool success = false;
      
      // Upload profile image first if one was selected
      if (_profileImage != null) {
        AppLogger.info('Uploading profile image...', 'EditProfileScreen');
        final imageSuccess = await authProvider.uploadProfileImage(_profileImage!);
        if (!imageSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Failed to upload profile image'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // Continue with other updates even if image upload fails
        }
      }
      
      if (_tabController.index == 0) {
        // Update basic profile
        success = await authProvider.updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          birthDate: _birthDate,
          gender: _selectedGender,
          interests: _interests,
          datingIntentions: _datingIntentions,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
      } else if (_tabController.index == 1) {
        // Update fitness profile
        success = await authProvider.updateFitnessProfile(
          activityLevel: _activityLevel,
          fitnessGoals: _fitnessGoals,
          favoriteActivities: _favoriteActivities,
          workoutFrequency: _workoutFrequency,
          preferredWorkoutTime: _preferredWorkoutTime,
          gymMembership: _gymMembership?.isEmpty ?? true ? null : _gymMembership,
          injuriesLimitations: _injuriesController.text.trim().isEmpty ? null : _injuriesController.text.trim(),
        );
      } else {
        // Update privacy settings
        success = await authProvider.updatePrivacySettings(
          showProfilePublicly: _showProfilePublicly,
          showFitnessData: _showFitnessData,
          showLocation: _showLocation,
          showOnlineStatus: _showOnlineStatus,
          allowMessagesFromStrangers: _allowMessagesFromStrangers,
          showInDiscovery: _showInDiscovery,
          shareWorkoutData: _shareWorkoutData,
          showAge: _showAge,
          showDistance: _showDistance,
        );
      }
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getSuccessMessage()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
    } catch (e) {
      AppLogger.error('Failed to save profile', 'EditProfileScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileImageSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _profileImage != null 
                ? FileImage(_profileImage!) 
                : null,
            child: _profileImage == null 
                ? (user != null 
                    ? Text(
                        '${user.firstName[0]}${user.lastName[0]}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: IconButton(
                onPressed: _showImagePickerDialog,
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 24,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildImageOptionCard(
                      'Camera',
                      Icons.camera_alt,
                      () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageOptionCard(
                      'Gallery',
                      Icons.photo_library,
                      () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (_profileImage != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildImageOptionCard(
                    'Remove Photo',
                    Icons.delete_outline,
                    _removeImage,
                    color: Colors.red.shade100,
                    iconColor: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOptionCard(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (iconColor ?? AppTheme.primaryColor).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: iconColor ?? AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: iconColor ?? AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.of(context).pop(); // Close the bottom sheet
      
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        AppLogger.info('Profile image selected from $source', 'EditProfileScreen');
      }
    } catch (e) {
      AppLogger.error('Error picking image: $e', 'EditProfileScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    Navigator.of(context).pop(); // Close the bottom sheet
    setState(() {
      _profileImage = null;
    });
    AppLogger.info('Profile image removed', 'EditProfileScreen');
  }

  String _getSuccessMessage() {
    switch (_tabController.index) {
      case 0:
        return 'Profile updated successfully!';
      case 1:
        return 'Fitness profile updated successfully!';
      case 2:
        return 'Privacy settings updated successfully!';
      default:
        return 'Profile updated successfully!';
    }
  }
}