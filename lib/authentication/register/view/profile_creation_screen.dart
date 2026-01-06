import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/authentication/register/repositories/auth_repository.dart';
import 'package:smart_chaja/authentication/register/viewmodels/auth_viewmodel.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';
import 'package:smart_chaja/utils/custom_dropdown.dart';
import 'package:smart_chaja/utils/image_utils.dart';

/// Simple, minimal profile creation screen
class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  ConsumerState<ProfileCreationScreen> createState() =>
      _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  DropdownOption? _gender;

  final List<DropdownOption> _genderOptions = [
    const DropdownOption(label: 'Male', icon: Icons.male),
    const DropdownOption(label: 'Female', icon: Icons.female),
  ];

  DateTime? _dateOfBirth;
  File? _profilePicture;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Image picking
  Future<void> _pickProfilePicture() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final cropped = await ImageUtils.cropImage(
            File(pickedFile.path), context,
            lockAspectRatio: true);
        if (cropped != null && mounted) {
          setState(() => _profilePicture = cropped);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        TopSnackBar.show(context, 'Failed to pick image. Please try again.',
            color: Colors.red);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Create profile after validation and auth check
  Future<void> _createProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      TopSnackBar.show(context, 'Please fill all required fields',
          color: Colors.red);
      return;
    }
    // Ensure user is authenticated before creating a profile
    final authState = ref.read(authViewModelProvider);
    final currentUser = ref.read(authRepositoryProvider).currentUser;

    if (!authState.isAuthenticated && currentUser == null) {
      TopSnackBar.show(context, 'User not authenticated. Please sign in first.',
          color: Colors.red);
      Navigator.pushReplacementNamed(context, '/send-otp');
      return;
    }
    // Prevent duplicate profile creation
    if (authState.user != null) {
      TopSnackBar.show(context, 'Profile already exists.',
          color: Colors.orange);
      Navigator.pushReplacementNamed(context, '/map');
      return;
    }

    final authViewModel = ref.read(authViewModelProvider.notifier);
    final success = await authViewModel.createUserProfile(
      fullName: _fullNameController.text.trim(),
      gender: _gender!.label,
      dateOfBirth: _dateOfBirth!,
      nationalId: '', // Not required for now
      profilePicture: _profilePicture,
    );

    if (!mounted) return;

    if (success) {
      TopSnackBar.show(context, 'Profile created successfully!',
          color: Colors.green);
      Navigator.pushReplacementNamed(context, '/map');
    } else {
      final error =
          ref.read(authViewModelProvider).error ?? 'Failed to create profile';
      TopSnackBar.show(context, error, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.error != null) {
        TopSnackBar.show(context, next.error!, color: Colors.red);
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    final isLoading =
        ref.watch(authViewModelProvider.select((state) => state.isLoading));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Profile',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Profile Picture
                GestureDetector(
                  onTap: _pickProfilePicture,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundColor,
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: _profilePicture != null
                            ? ClipOval(
                                child: Image.file(
                                  _profilePicture!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person_outline,
                                size: 60,
                                color: AppColors.secondaryTextColor,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add Photo',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Gender
                CustomDropdown<DropdownOption>(
                  options: _genderOptions,
                  selectedOption: _gender,
                  hintText: 'Select Gender',
                  prefixIcon: Icons.wc_outlined,
                  onSelected: (option) {
                    setState(() {
                      _gender = option;
                    });
                  },
                  validator: (option) =>
                      option == null ? 'Please select gender' : null,
                ),
                const SizedBox(height: 20),
                // Date of Birth
                // Date of Birth
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'Select your date of birth',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                  ),
                  validator: (value) {
                    if (_dateOfBirth == null) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _createProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Complete Profile',
                            style: TextStyle(
                              color: Colors.white,
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
      ),
    );
  }
}
