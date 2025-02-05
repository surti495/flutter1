import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;
  bool _isEditingName = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await _profileService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
        _nameController.text = profile.name;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final updatedProfile = await _profileService.updateProfile(
        name: _nameController.text.trim(),
      );

      setState(() {
        _userProfile = updatedProfile;
        _isLoading = false;
        _error = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        if (_userProfile != null) {
          _nameController.text = _userProfile!.name;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name')),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);
      await _profileService.updateProfilePicture(image.path);
      await _loadProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture'),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _buildNameField() {
    if (_isEditingName) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: Colors.white60),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade200),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.check, color: Colors.green.shade300),
            onPressed: _updateName,
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade300),
            onPressed: () {
              setState(() {
                _isEditingName = false;
                _nameController.text = _userProfile?.name ?? '';
              });
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.person_rounded, size: 24, color: Colors.blue.shade200),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade100.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 4),
              Text(
                _userProfile?.name ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue.shade200),
          onPressed: () {
            setState(() {
              _isEditingName = true;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Your existing build method content
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black,
                  Colors.blueGrey.shade900,
                  Colors.indigo.shade900,
                ],
              ),
            ),
          ),
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassButton(
                    onPressed: _loadProfile,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  _buildGlassAppBar(),
                  // Profile Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Picture
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white10,
                                  backgroundImage: _userProfile
                                              ?.profilePictureFullUrl !=
                                          null
                                      ? NetworkImage(
                                          _userProfile!.profilePictureFullUrl!)
                                      : null,
                                  onBackgroundImageError:
                                      (exception, stackTrace) {
                                    print(
                                        'Error loading profile picture: $exception');
                                    print(
                                        'URL attempted: ${_userProfile?.profilePictureFullUrl}');
                                  },
                                  child: _userProfile?.profilePictureFullUrl ==
                                          null
                                      ? Icon(Icons.person,
                                          size: 60, color: Colors.white70)
                                      : null,
                                ),
                              ),
                              _buildGlassIconButton(
                                onPressed: _updateProfilePicture,
                                icon: Icons.camera_alt,
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                          // Profile Details
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildProfileItem(
                                  'Name',
                                  _userProfile?.name ?? '',
                                  Icons.person_rounded,
                                ),
                                Divider(color: Colors.white24),
                                _buildProfileItem(
                                  'Email',
                                  _userProfile?.email ?? '',
                                  Icons.email_rounded,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title with gradient effect
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [Colors.white, Colors.blue.shade200],
                  ).createShader(bounds);
                },
                child: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Enhanced refresh button
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Add refresh animation
                          final icon =
                              (context.findRenderObject() as RenderBox?)
                                  ?.localToGlobal(Offset.zero);
                          if (icon != null) {
                            _loadProfile();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Refresh',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    if (label == 'Name') {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: _buildNameField(),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue.shade200),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade100.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: MaterialButton(
            onPressed: onPressed,
            height: 50,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
