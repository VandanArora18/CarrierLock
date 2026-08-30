import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen for an admin to create a new fleet.
class AdminCreateFleetScreen extends StatefulWidget {
  const AdminCreateFleetScreen({super.key});

  @override
  State<AdminCreateFleetScreen> createState() => _AdminCreateFleetScreenState();
}

class _AdminCreateFleetScreenState extends State<AdminCreateFleetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createFleet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      
      final user = ProviderScope.containerOf(context).read(currentUserProvider);
      if (user == null) throw Exception('No user logged in');
      
      final db = FirebaseFirestore.instance;
      
      // Generate unique 4-digit join code
      final joinCode = (1000 + Random().nextInt(9000)).toString();

      // Create new fleet doc
      final fleetRef = await db.collection('fleets').add({
        'name': name,
        'description': desc,
        'adminIds': [user.uid],
        'driverIds': [],
        'joinCode': joinCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update the user's fleetId to the newly created one
      await db.collection('users').doc(user.uid).update({
        'fleetId': fleetRef.id,
      });
      
      // Refresh AuthProvider so current user reflects the change
      await ProviderScope.containerOf(context).read(authProvider.notifier).checkAuthState();
      
      if (mounted) {
        setState(() => _isLoading = false);
        // Go back to fleet selection - user will tap to enter the fleet
        context.go(AppRoutes.adminFleetSelection);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating fleet: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(title: const Text('Create Fleet')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FLEET NAME', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: AppTextStyles.inputText,
                decoration: const InputDecoration(
                  hintText: 'e.g. Alpha Logistics',
                  prefixIcon: Icon(Icons.business_rounded, size: 18),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Text('DESCRIPTION (OPTIONAL)', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                style: AppTextStyles.inputText,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Brief description of this fleet...',
                ),
              ),
              const SizedBox(height: 40),
              GoldButton(
                label: 'Create Fleet',
                icon: Icons.add_rounded,
                isLoading: _isLoading,
                onPressed: _createFleet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
