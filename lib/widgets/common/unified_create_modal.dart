import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/goals_provider.dart';
import '../../models/fitness_goal.dart';
import '../../utils/logger.dart';
import '../activity/enhanced_create_activity_modal.dart';

class UnifiedCreateModal extends StatefulWidget {
  const UnifiedCreateModal({super.key});

  @override
  State<UnifiedCreateModal> createState() => _UnifiedCreateModalState();
}

class _UnifiedCreateModalState extends State<UnifiedCreateModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Something New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'What would you like to create today?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCreateOption(
                  title: 'Activity',
                  subtitle: 'Log a workout',
                  icon: Icons.fitness_center,
                  gradient: [Colors.blue.shade400, Colors.blue.shade600],
                  onTap: () => _showCreateActivity(),
                  isPopular: true,
                ),
                _buildCreateOption(
                  title: 'Goal',
                  subtitle: 'Set new target',
                  icon: Icons.flag,
                  gradient: [Colors.green.shade400, Colors.green.shade600],
                  onTap: () => _showCreateGoal(),
                  isPopular: true,
                ),
                _buildCreateOption(
                  title: 'Post',
                  subtitle: 'Share update',
                  icon: Icons.post_add,
                  gradient: [Colors.pink.shade400, Colors.pink.shade600],
                  onTap: () => _showCreatePost(),
                  isPopular: true,
                ),
                _buildCreateOption(
                  title: 'Event',
                  subtitle: 'Organize meetup',
                  icon: Icons.event,
                  gradient: [Colors.purple.shade400, Colors.purple.shade600],
                  onTap: () => _showCreateEvent(),
                ),
                _buildCreateOption(
                  title: 'Route',
                  subtitle: 'Plan a path',
                  icon: Icons.route,
                  gradient: [Colors.orange.shade400, Colors.orange.shade600],
                  onTap: () => _showCreateRoute(),
                ),
                _buildCreateOption(
                  title: 'Challenge',
                  subtitle: 'Start challenge',
                  icon: Icons.emoji_events,
                  gradient: [Colors.teal.shade400, Colors.teal.shade600],
                  onTap: () => _showCreateChallenge(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isPopular)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⭐',
                    style: TextStyle(
                      fontSize: 12,
                      color: gradient[0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateActivity() {
    Navigator.of(context).pop(); // Close unified modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedCreateActivityModal(),
    );
  }

  void _showCreateGoal() {
    Navigator.of(context).pop();
    _showCreateGoalModal();
  }

  void _showCreateRoute() {
    Navigator.of(context).pop();
    _showCreateRouteModal();
  }

  void _showCreateEvent() {
    Navigator.of(context).pop();
    _showCreateEventModal();
  }

  void _showCreatePost() {
    Navigator.of(context).pop();
    _showCreatePostModal();
  }

  void _showCreateChallenge() {
    Navigator.of(context).pop();
    _showCreateChallengeModal();
  }

  void _showCreateGoalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateGoalModal(),
    );
  }

  void _showCreateRouteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickCreateModal(
        title: 'Create Route',
        icon: Icons.route,
        gradient: [Colors.orange.shade400, Colors.orange.shade600],
        fields: [
          _buildTextField('Route Name', 'e.g., Morning Park Loop'),
          _buildTextField('Start Location', 'e.g., Central Park Entrance'),
          _buildTextField('End Location', 'e.g., Bethesda Fountain'),
          _buildDropdownField('Activity Type', ['Running', 'Cycling', 'Walking', 'Hiking']),
          _buildDropdownField('Difficulty', ['Easy', 'Moderate', 'Hard']),
        ],
        onSave: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route created successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  void _showCreateEventModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickCreateModal(
        title: 'Create Event',
        icon: Icons.event,
        gradient: [Colors.purple.shade400, Colors.purple.shade600],
        fields: [
          _buildTextField('Event Name', 'e.g., Saturday Morning Run'),
          _buildTextField('Description', 'Tell people what to expect...'),
          _buildTextField('Location', 'e.g., Central Park'),
          _buildDateTimeField('Date & Time'),
          _buildDropdownField('Activity Type', ['Running', 'Cycling', 'Yoga', 'Hiking', 'Other']),
        ],
        onSave: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event created successfully!'),
              backgroundColor: Colors.purple,
            ),
          );
        },
      ),
    );
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickCreateModal(
        title: 'Create Post',
        icon: Icons.post_add,
        gradient: [Colors.pink.shade400, Colors.pink.shade600],
        fields: [
          _buildTextField('What\'s on your mind?', 'Share your fitness journey...', maxLines: 4),
          Row(
            children: [
              Expanded(child: _buildActionButton(Icons.image, 'Photo')),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton(Icons.location_on, 'Location')),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton(Icons.emoji_events, 'Achievement')),
            ],
          ),
        ],
        onSave: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post shared successfully!'),
              backgroundColor: Colors.pink,
            ),
          );
        },
      ),
    );
  }

  void _showCreateChallengeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickCreateModal(
        title: 'Create Challenge',
        icon: Icons.emoji_events,
        gradient: [Colors.teal.shade400, Colors.teal.shade600],
        fields: [
          _buildTextField('Challenge Name', 'e.g., 30-Day Running Streak'),
          _buildTextField('Description', 'What\'s the challenge about?'),
          _buildDropdownField('Duration', ['1 Week', '2 Weeks', '1 Month', '3 Months']),
          _buildDropdownField('Type', ['Individual', 'Team', 'Community']),
          _buildTextField('Goal', 'e.g., Run 5km every day'),
        ],
        onSave: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge created successfully!'),
              backgroundColor: Colors.teal,
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickCreateModal({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> fields,
    required VoidCallback onSave,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: fields.map((field) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: field,
                        )).toList(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gradient[0],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create ${title.split(' ')[1]}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          )).toList(),
          onChanged: (value) {},
          hint: Text('Select $label'),
        ),
      ],
    );
  }


  Widget _buildDateTimeField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select date and time',
            suffixIcon: const Icon(Icons.access_time),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null && mounted) {
              await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateGoalModal extends StatefulWidget {
  const _CreateGoalModal();

  @override
  State<_CreateGoalModal> createState() => _CreateGoalModalState();
}

class _CreateGoalModalState extends State<_CreateGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedGoalType = 'Distance';
  int _selectedActivityType = 1; // Default activity type ID (Running)
  DateTime? _targetDate;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _goalTypes = [
    {
      'name': 'Distance',
      'unit': 'km',
      'icon': Icons.straighten,
      'color': Colors.blue,
    },
    {
      'name': 'Duration',
      'unit': 'minutes',
      'icon': Icons.timer,
      'color': Colors.orange,
    },
    {
      'name': 'Calories',
      'unit': 'calories',
      'icon': Icons.local_fire_department,
      'color': Colors.red,
    },
    {
      'name': 'Frequency',
      'unit': 'times',
      'icon': Icons.repeat,
      'color': Colors.green,
    },
  ];

  final List<Map<String, dynamic>> _activityTypes = [
    {'name': 'Running', 'id': 1},
    {'name': 'Cycling', 'id': 2}, 
    {'name': 'Walking', 'id': 3},
    {'name': 'Swimming', 'id': 4},
    {'name': 'Hiking', 'id': 5},
    {'name': 'Yoga', 'id': 6},
    {'name': 'Strength Training', 'id': 7},
  ];

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGoalNameField(),
                            const SizedBox(height: 20),
                            _buildGoalTypeSelection(),
                            const SizedBox(height: 20),
                            _buildActivityTypeSelection(),
                            const SizedBox(height: 20),
                            _buildTargetValueField(),
                            const SizedBox(height: 20),
                            _buildTargetDateField(),
                            const SizedBox(height: 20),
                            _buildDescriptionField(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCreateButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flag, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Create Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _goalNameController,
          decoration: InputDecoration(
            hintText: 'e.g., Run 5K in 30 minutes',
            prefixIcon: const Icon(Icons.edit),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a goal name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGoalTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _goalTypes.map((type) {
            final isSelected = _selectedGoalType == type['name'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGoalType = type['name']),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? type['color'] : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? type['color'] : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected ? Colors.white : type['color'],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedActivityType,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.sports),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: _activityTypes.map((type) => DropdownMenuItem<int>(
            value: type['id'] as int,
            child: Text(type['name'] as String),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedActivityType = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTargetValueField() {
    final selectedType = _goalTypes.firstWhere((type) => type['name'] == _selectedGoalType);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _targetValueController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g., 5',
            suffixText: selectedType['unit'],
            prefixIcon: Icon(selectedType['icon']),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a target value';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTargetDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectTargetDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  _targetDate != null 
                      ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                      : 'Select target date',
                  style: TextStyle(
                    fontSize: 16,
                    color: _targetDate != null ? Colors.grey.shade800 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add details about your goal...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectTargetDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _targetDate = date);
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedType = _goalTypes.firstWhere((type) => type['name'] == _selectedGoalType);
      
      final goal = FitnessGoal(
        id: 0, // Will be assigned by backend
        title: _goalNameController.text.trim(),
        description: _descriptionController.text.trim(),
        goalType: _selectedGoalType.toLowerCase(),
        targetValue: double.parse(_targetValueController.text),
        unit: selectedType['unit'],
        startDate: DateTime.now(),
        endDate: _targetDate!,
        currentProgress: 0.0,
        isActive: true,
        isCompleted: false,
        activityType: _selectedActivityType.toString(),
      );

      AppLogger.info('Creating goal with data: ${goal.toJson()}', 'CreateGoalModal');

      final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
      final success = await goalsProvider.createGoal(goal);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(goalsProvider.error ?? 'Failed to create goal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create goal. Please try again.'),
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
}