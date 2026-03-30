import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  String? _gender;
  String _genderPreference = 'ANY';
  bool _isLoading = false;
  String? _error;

  final _genders = ['MALE', 'FEMALE', 'OTHER'];
  final _preferences = ['ANY', 'SAME_GENDER', 'MALE_ONLY', 'FEMALE_ONLY'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _gender = user?.gender;
    _genderPreference = user?.genderPreference ?? 'ANY';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await DioClient.instance.patch('/users/me', data: {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_gender != null) 'gender': _gender,
        'genderPreference': _genderPreference,
      });
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated'),
              backgroundColor: AppTheme.secondary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = extractApiError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppTheme.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              Row(children: [
                Expanded(
                    child: CustomTextField(
                        label: 'First Name',
                        controller: _firstNameCtrl,
                        validator: (v) =>
                            v!.isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(
                    child: CustomTextField(
                        label: 'Last Name',
                        controller: _lastNameCtrl,
                        validator: (v) =>
                            v!.isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: 16),

              CustomTextField(
                  label: 'Phone',
                  hint: '+92 300 1234567',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),

              const Text('Gender',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _genders
                    .map((g) => ChoiceChip(
                          label: Text(g),
                          selected: _gender == g,
                          onSelected: (_) =>
                              setState(() => _gender = g),
                          selectedColor:
                              AppTheme.primary.withOpacity(0.15),
                          labelStyle: TextStyle(
                              color: _gender == g
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontSize: 12),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              const Text('Ride Preference',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              const Text('Who do you prefer to ride with?',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textHint)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _preferences
                    .map((p) => ChoiceChip(
                          label: Text(p.replaceAll('_', ' ')),
                          selected: _genderPreference == p,
                          onSelected: (_) =>
                              setState(() => _genderPreference = p),
                          selectedColor:
                              AppTheme.primary.withOpacity(0.15),
                          labelStyle: TextStyle(
                              color: _genderPreference == p
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontSize: 12),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                  label: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
