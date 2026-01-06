import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/reusable_widgets/custom_text_field.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';
import 'package:smart_chaja/utils/image_utils.dart';


class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  String? _gender;
  DateTime? _dateOfBirth;
  File? _newProfilePicture;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _nationalIdController.text = user.nationalId;
      _gender = user.gender;
      _dateOfBirth = user.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File? cropped = await ImageUtils.cropImage(File(pickedFile.path), context, lockAspectRatio: true);
      if (cropped != null) {
        File? processed = await ImageUtils.processImage(cropped);
        if (processed != null) {
          setState(() {
            _newProfilePicture = processed;
          });
        }
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate() && _gender != null && _dateOfBirth != null) {
      final authViewModel = ref.read(authViewModelProvider.notifier);
      final success = await authViewModel.updateUserProfile(
        fullName: _fullNameController.text,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        nationalId: _nationalIdController.text,
        profilePicture: _newProfilePicture,
        removeProfilePicture: _newProfilePicture == null && ref.read(authViewModelProvider).user?.profilePictureUrl != null,
      );
      if (success) {
        TopSnackBar.show(context, 'Profile updated successfully!', iconData: Icons.check_circle, color: Colors.green);
        setState(() {
          _isEditing = false;
          _newProfilePicture = null;
        });
      } else {
        TopSnackBar.show(context, ref.read(authViewModelProvider).error ?? 'Failed to update profile', iconData: Icons.error, color: Colors.red);
      }
    } else {
      TopSnackBar.show(context, 'Please fill all fields', iconData: Icons.error, color: Colors.red);
    }
  }

  void _logout() async {
    final authViewModel = ref.read(authViewModelProvider.notifier);
    await authViewModel.signOut();
    TopSnackBar.show(context, 'Logged out successfully!', iconData: Icons.check_circle, color: Colors.green);
    Navigator.pushReplacementNamed(context, '/send-otp');
  }

  void _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final authViewModel = ref.read(authViewModelProvider.notifier);
      final success = await authViewModel.deleteAccount();
      if (success) {
        TopSnackBar.show(context, 'Account deleted successfully!', iconData: Icons.check_circle, color: Colors.green);
        Navigator.pushReplacementNamed(context, '/send-otp');
      } else {
        TopSnackBar.show(context, ref.read(authViewModelProvider).error ?? 'Failed to delete account', iconData: Icons.error, color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final isLoading = authState.isLoading;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _isEditing ? _pickProfilePicture : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _newProfilePicture != null
                            ? FileImage(_newProfilePicture!)
                            : user.profilePictureUrl != null
                                ? NetworkImage(user.profilePictureUrl!)
                                : null,
                        child: user.profilePictureUrl == null && _newProfilePicture == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      if (_isEditing)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EnhancedCustomTextField(
                controller: TextEditingController(text: user.phoneNumber),
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                enabled: false,
              ),
              EnhancedCustomTextField(
                controller: _fullNameController,
                label: 'Full Name',
                prefixIcon: Icons.person,
                enabled: _isEditing,
                validator: _isEditing ? (value) => value!.isEmpty ? 'Enter your full name' : null : null,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                ),
                items: ['Male', 'Female', 'Other'].map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                onChanged: _isEditing ? (value) => setState(() => _gender = value) : null,
                validator: _isEditing ? (value) => value == null ? 'Select a gender' : null : null,
              ),
              const SizedBox(height: 16),
              EnhancedCustomTextField(
                controller: TextEditingController(text: _dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!) : ''),
                label: 'Date of Birth',
                prefixIcon: Icons.calendar_today,
                readOnly: true,
                enabled: _isEditing,
                onTap: _isEditing ? _selectDateOfBirth : null,
                validator: _isEditing ? (value) => _dateOfBirth == null ? 'Select a date of birth' : null : null,
              ),
              EnhancedCustomTextField(
                controller: _nationalIdController,
                label: 'National ID',
                prefixIcon: Icons.person,
                enabled: _isEditing,
                validator: _isEditing ? (value) => value!.isEmpty ? 'Enter your national ID' : null : null,
              ),
              EnhancedCustomTextField(
                controller: TextEditingController(text: user.role),
                label: 'Role',
                prefixIcon: Icons.security,
                enabled: false,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _updateProfile,
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel'),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _logout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Logout'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : _deleteAccount,
                child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}