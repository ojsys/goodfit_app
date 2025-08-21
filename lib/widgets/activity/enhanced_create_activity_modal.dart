import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../providers/fitness_provider.dart';
import '../../providers/goals_provider.dart';
import '../../models/fitness_goal.dart';
import '../../models/fitness_activity.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance_calculator.dart';
import '../../utils/logger.dart';

class EnhancedCreateActivityModal extends StatefulWidget {
  const EnhancedCreateActivityModal({super.key});

  @override
  State<EnhancedCreateActivityModal> createState() => _EnhancedCreateActivityModalState();
}

class _EnhancedCreateActivityModalState extends State<EnhancedCreateActivityModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  final PageController _pageController = PageController();
  
  // Activity data
  String _selectedActivityType = 'Running';
  String? _startLocation;
  String? _endLocation;
  double? _startLatitude;
  double? _startLongitude;
  double? _endLatitude;
  double? _endLongitude;
  double? _distance;
  int _estimatedDuration = 30;
  String _activityName = '';
  
  // Goal linking
  List<FitnessGoal> _compatibleGoals = [];
  List<int> _selectedGoalIds = [];
  bool _showGoalSelection = false;
  
  final Location _location = Location();
  bool _isLoadingLocation = false;
  
  final List<Map<String, dynamic>> _activityTypeData = [
    {
      'name': 'Running',
      'icon': Icons.directions_run,
      'color': Colors.red,
      'gradient': [Colors.red.shade400, Colors.red.shade600],
      'description': 'Track your runs and improve your pace',
    },
    {
      'name': 'Cycling',
      'icon': Icons.directions_bike,
      'color': Colors.blue,
      'gradient': [Colors.blue.shade400, Colors.blue.shade600],
      'description': 'Explore routes and track cycling activities',
    },
    {
      'name': 'Walking',
      'icon': Icons.directions_walk,
      'color': Colors.green,
      'gradient': [Colors.green.shade400, Colors.green.shade600],
      'description': 'Stay active with walking activities',
    },
    {
      'name': 'Swimming',
      'icon': Icons.pool,
      'color': Colors.cyan,
      'gradient': [Colors.cyan.shade400, Colors.cyan.shade600],
      'description': 'Track your swimming sessions',
    },
    {
      'name': 'Hiking',
      'icon': Icons.terrain,
      'color': Colors.brown,
      'gradient': [Colors.brown.shade400, Colors.brown.shade600],
      'description': 'Explore trails and track elevation',
    },
    {
      'name': 'Yoga',
      'icon': Icons.self_improvement,
      'color': Colors.purple,
      'gradient': [Colors.purple.shade400, Colors.purple.shade600],
      'description': 'Mindful movement and flexibility',
    },
    {
      'name': 'Strength Training',
      'icon': Icons.fitness_center,
      'color': Colors.orange,
      'gradient': [Colors.orange.shade400, Colors.orange.shade600],
      'description': 'Build strength and muscle',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Updated to 3 tabs for goal selection
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
    
    _animationController.forward();
    
    // Ensure goals are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
      if (goalsProvider.goals.isEmpty && !goalsProvider.isLoading) {
        AppLogger.info('Goals not loaded, loading now...', 'CreateActivity');
        goalsProvider.loadGoals();
      }
      _loadCompatibleGoals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadCompatibleGoals() {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
    
    // Log all available goals first
    AppLogger.info('Total goals available: ${goalsProvider.goals.length}', 'CreateActivity');
    AppLogger.info('Active goals: ${goalsProvider.activeGoals.length}', 'CreateActivity');
    
    for (final goal in goalsProvider.goals) {
      AppLogger.info('Goal: ${goal.title} (Type: ${goal.goalType}, Active: ${goal.isActive}, Completed: ${goal.isCompleted}, ActivityType: ${goal.activityType})', 'CreateActivity');
    }
    
    _compatibleGoals = goalsProvider.getCompatibleGoals(_selectedActivityType);
    
    // Log compatible goals found
    AppLogger.info('Found ${_compatibleGoals.length} compatible goals for $_selectedActivityType', 'CreateActivity');
    for (final goal in _compatibleGoals) {
      AppLogger.info('- ${goal.title} (${goal.goalType}): ${goal.progressDisplay}', 'CreateActivity');
    }
    
    // Force a rebuild to show the goals
    if (mounted) {
      setState(() {});
    }
  }

  void _onActivityTypeChanged(String newActivityType) {
    setState(() {
      _selectedActivityType = newActivityType;
      _selectedGoalIds.clear(); // Clear previous selections
      _loadCompatibleGoals(); // Reload compatible goals
    });
  }

  void _toggleGoalSelection(int goalId) {
    setState(() {
      if (_selectedGoalIds.contains(goalId)) {
        _selectedGoalIds.remove(goalId);
      } else {
        _selectedGoalIds.add(goalId);
      }
    });
    
    AppLogger.info('Selected goals: $_selectedGoalIds', 'CreateActivity');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
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
                        'Create Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Plan your next fitness adventure',
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
    return PageView(
      controller: _pageController,
      children: [
        _buildActivityTypeSelection(),
        _buildGoalSelection(),
        _buildActivityDetails(),
      ],
    );
  }

  Widget _buildActivityTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Choose Activity Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step 1 of 3',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _activityTypeData.length,
              itemBuilder: (context, index) {
                final activity = _activityTypeData[index];
                final isSelected = _selectedActivityType == activity['name'];
                
                return GestureDetector(
                  onTap: () => _onActivityTypeChanged(activity['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: activity['gradient'],
                            )
                          : null,
                      color: isSelected ? null : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.transparent 
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: activity['color'].withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : activity['color'].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              activity['icon'],
                              size: 32,
                              color: isSelected ? Colors.white : activity['color'],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            activity['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity['description'],
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected 
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildActivityDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                'Activity Details & Tracking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step 3 of 3',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSelectedActivityCard(),
                  const SizedBox(height: 24),
                  _buildActivityNameField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildDurationSection(),
                  const SizedBox(height: 24),
                  if (_distance != null) _buildDistanceInfo(),
                ],
              ),
            ),
          ),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedActivityCard() {
    final activity = _activityTypeData.firstWhere(
      (a) => a['name'] == _selectedActivityType,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: activity['gradient'],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activity['icon'],
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  activity['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          onChanged: (value) => setState(() => _activityName = value),
          decoration: InputDecoration(
            hintText: 'e.g., Morning $_selectedActivityType',
            prefixIcon: const Icon(Icons.edit),
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
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add details about your activity...',
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

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLocationField('Start Location', true)),
            const SizedBox(width: 12),
            Expanded(child: _buildLocationField('End Location', false)),
          ],
        ),
        const SizedBox(height: 12),
        _buildCurrentLocationButton(),
      ],
    );
  }

  Widget _buildLocationField(String label, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(
                isStart ? Icons.place : Icons.flag,
                size: 16,
                color: isStart ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isStart 
                      ? (_startLocation ?? 'Tap to set')
                      : (_endLocation ?? 'Tap to set'),
                  style: TextStyle(
                    fontSize: 14,
                    color: (isStart ? _startLocation : _endLocation) != null
                        ? Colors.grey.shade800
                        : Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(_isLoadingLocation ? 'Getting Location...' : 'Use Current Location'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_estimatedDuration minutes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_estimatedDuration > 5) {
                            setState(() => _estimatedDuration -= 5);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _estimatedDuration += 5);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              Slider(
                value: _estimatedDuration.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() => _estimatedDuration = value.round());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.straighten,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Distance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  DistanceCalculator.formatDistance(_distance!),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                'Link to Goals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step 2 of 3',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Select goals to track with this activity',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<GoalsProvider>(
            builder: (context, goalsProvider, child) {
              // Update compatible goals when provider changes
              _compatibleGoals = goalsProvider.getCompatibleGoals(_selectedActivityType);
              
              if (goalsProvider.isLoading) {
                return const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (_compatibleGoals.isEmpty) {
                return _buildNoCompatibleGoals();
              }
              
              return Expanded(
                child: ListView.builder(
                  itemCount: _compatibleGoals.length,
                  itemBuilder: (context, index) {
                  final goal = _compatibleGoals[index];
                  final isSelected = _selectedGoalIds.contains(goal.id);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      elevation: isSelected ? 4 : 1,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _toggleGoalSelection(goal.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected 
                                ? AppTheme.primaryColor.withValues(alpha: 0.05)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getGoalTypeColor(goal.goalType).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getGoalTypeIcon(goal.goalType),
                                  color: _getGoalTypeColor(goal.goalType),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      goal.progressDisplay,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: goal.progressPercentage / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getGoalTypeColor(goal.goalType),
                                      ),
                                      minHeight: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _selectedGoalIds.isEmpty ? 'Skip Goals' : 'Continue (${_selectedGoalIds.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoCompatibleGoals() {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
    final totalGoals = goalsProvider.goals.length;
    final activeGoals = goalsProvider.goals.where((g) => g.isActive && !g.isCompleted).length;
    
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.flag,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Compatible Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any active goals that are compatible with $_selectedActivityType activities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Debug Info',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    'Total goals: $totalGoals\nActive goals: $activeGoals\nActivity: $_selectedActivityType',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to create goal screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Goal creation will be available soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Goal'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGoalTypeColor(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'distance':
        return Colors.blue;
      case 'duration':
        return Colors.green;
      case 'calories':
        return Colors.orange;
      case 'frequency':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getGoalTypeIcon(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'distance':
        return Icons.straighten;
      case 'duration':
        return Icons.timer;
      case 'calories':
        return Icons.local_fire_department;
      case 'frequency':
        return Icons.repeat;
      default:
        return Icons.flag;
    }
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final isValid = _activityName.trim().isNotEmpty;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isValid ? _startLiveTracking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text(
              'Start Live Tracking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isValid ? _createActivityNow : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Create Activity Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      final placemarks = await geo.placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.name}, ${placemark.locality}';
        
        setState(() {
          _startLocation = address;
          _startLatitude = locationData.latitude;
          _startLongitude = locationData.longitude;
        });
      }
    } catch (e) {
      AppLogger.error('Error getting current location: $e', 'CreateActivity');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _startLiveTracking() async {
    if (_activityName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activity name'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Close modal and navigate to live tracking screen
    Navigator.of(context).pop();
    
    // Navigate to live tracking screen with activity data
    Navigator.of(context).pushNamed(
      '/live-tracking',
      arguments: {
        'activityType': _selectedActivityType,
        'activityName': _activityName,
        'estimatedDuration': _estimatedDuration,
        'startLocation': _startLocation,
        'startLatitude': _startLatitude,
        'startLongitude': _startLongitude,
        'linkedGoalIds': _selectedGoalIds,
      },
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting live tracking for "$_activityName"'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createActivityNow() async {
    if (_activityName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activity name'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fitnessProvider = Provider.of<FitnessProvider>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    final success = await fitnessProvider.createActivity(
      activityType: _selectedActivityType,
      durationMinutes: _estimatedDuration,
      distanceKm: _distance,
      caloriesBurned: _estimateCalories(),
      activityName: _activityName,
      startLocation: _startLocation,
      endLocation: _endLocation,
      startLatitude: _startLatitude,
      startLongitude: _startLongitude,
      endLatitude: _endLatitude,
      endLongitude: _endLongitude,
      linkedGoalIds: _selectedGoalIds,
    );
    
    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        // Update goal progress if goals are linked
        if (_selectedGoalIds.isNotEmpty) {
          final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
          
          // Create a temporary activity for progress calculation
          final completedActivity = FitnessActivity(
            id: 0,
            activityType: _selectedActivityType,
            name: _activityName,
            durationMinutes: _estimatedDuration,
            distanceKm: _distance,
            caloriesBurned: _estimateCalories(),
            startTime: DateTime.now(),
            endTime: DateTime.now().add(Duration(minutes: _estimatedDuration)),
            startLocation: _startLocation,
            endLocation: _endLocation,
            startLatitude: _startLatitude,
            startLongitude: _startLongitude,
            endLatitude: _endLatitude,
            endLongitude: _endLongitude,
            linkedGoalIds: _selectedGoalIds,
            isCompleted: true,
          );
          
          // Update goal progress
          try {
            await goalsProvider.updateGoalProgress(completedActivity);
            AppLogger.info('Updated progress for ${_selectedGoalIds.length} linked goals', 'CreateActivity');
          } catch (e) {
            AppLogger.error('Failed to update goal progress: $e', 'CreateActivity');
          }
        }
        
        if (mounted) {
          Navigator.of(context).pop(); // Close modal
        }
        // Trigger a refresh of the fitness data
        await fitnessProvider.loadActivities();
        
        if (mounted) {
          final goalMessage = _selectedGoalIds.isNotEmpty 
              ? ' and updated ${_selectedGoalIds.length} goal(s)!'
              : '!';
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Activity "$_activityName" created successfully$goalMessage'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fitnessProvider.errorMessage ?? 'Failed to create activity. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int? _estimateCalories() {
    // Simple calorie estimation based on activity type and duration
    final caloriesPerMinute = {
      'Running': 10,
      'Cycling': 8,
      'Walking': 4,
      'Swimming': 12,
      'Hiking': 6,
      'Yoga': 3,
      'Strength Training': 5,
    };
    
    final rate = caloriesPerMinute[_selectedActivityType] ?? 5;
    return rate * _estimatedDuration;
  }
}