import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared
  final _linkedinCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Professional
  final _officeNameCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _officeLinkedinCtrl = TextEditingController();
  String? _cnicPhotoUrl;
  String? _avatarUrl;
  File? _cnicPhotoFile;
  File? _avatarFile;

  // Student
  final _universityNameCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  String _staffType = 'STUDENT';
  String? _idCardPhotoUrl;
  File? _idCardPhotoFile;

  bool _isSubmitting = false;
  bool _uploadingCnic = false;
  bool _uploadingIdCard = false;
  bool _uploadingAvatar = false;

  String? _linkedinValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!v.trim().toLowerCase().contains('linkedin.com')) {
      return 'Must be a LinkedIn URL (linkedin.com/...)';
    }
    return null;
  }

  String? _cnicValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final digits = v.trim().replaceAll('-', '').replaceAll(' ', '');
    if (digits.length != 13 || !RegExp(r'^\d+$').hasMatch(digits)) {
      return 'CNIC must be exactly 13 digits';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _linkedinCtrl.text = user.linkedinUrl ?? '';
      _phoneCtrl.text = user.phone ?? '';
      _officeNameCtrl.text = user.officeName ?? '';
      _jobTitleCtrl.text = user.jobTitle ?? '';
      _cnicCtrl.text = user.cnicNumber ?? '';
      _officeLinkedinCtrl.text = user.officeLinkedinUrl ?? '';
      _cnicPhotoUrl = user.cnicPhotoUrl;
      _avatarUrl = user.avatarUrl;
      _universityNameCtrl.text = user.universityName ?? '';
      _degreeCtrl.text = user.degreeDesignation ?? '';
      _staffType = user.staffType ?? 'STUDENT';
      _idCardPhotoUrl = user.idCardPhotoUrl;
    }
  }

  @override
  void dispose() {
    _linkedinCtrl.dispose();
    _phoneCtrl.dispose();
    _officeNameCtrl.dispose();
    _jobTitleCtrl.dispose();
    _cnicCtrl.dispose();
    _officeLinkedinCtrl.dispose();
    _universityNameCtrl.dispose();
    _degreeCtrl.dispose();
    super.dispose();
  }

  Future<String?> _uploadPhoto({
    required File file,
    required String fieldName,
    required void Function(bool) setLoading,
  }) async {
    setLoading(true);
    try {
      final fileName = file.path.split('/').last;
      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final isAvatar = fieldName == 'avatar';
      final endpoint =
          isAvatar ? ApiConstants.avatarUploadUrl : ApiConstants.idDocumentUploadUrl;

      final res = await DioClient.instance.post(endpoint, data: {
        'fileName': fileName,
        'mimeType': mimeType,
      });

      final uploadUrl = res.data['data']['uploadUrl'] as String;
      final publicUrl = res.data['data']['publicUrl'] as String;

      final bytes = await file.readAsBytes();
      final rawDio = Dio();
      await rawDio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {'Content-Type': mimeType},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      return publicUrl;
    } catch (e) {
      final msg = extractApiError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $msg'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _pickPhoto({
    required String fieldName,
    required void Function(File) onFilePicked,
    required void Function(String) onUrlSaved,
    required void Function(bool) setLoading,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final file = File(picked.path);
    onFilePicked(file);

    final url = await _uploadPhoto(
      file: file,
      fieldName: fieldName,
      setLoading: setLoading,
    );
    if (url != null) onUrlSaved(url);
  }

  /// Sends OTP then shows the verification sheet.
  /// Returns true = verified, false = cancelled/change number (submit should stop).
  Future<bool> _showOtpSheet(String phoneNumber) async {
    try {
      await DioClient.instance.post(
        ApiConstants.sendPhoneOtp,
        data: {'phoneNumber': phoneNumber},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractApiError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return false;
    }

    if (!mounted) return false;

    // Sheet returns true = verified, 'change' = user wants to edit number
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _OtpBottomSheet(phoneNumber: phoneNumber),
    );

    return result == true;
  }

  void _showSubmittedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppTheme.secondary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Phone Verified!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your profile has been submitted for review.\nOur team will verify and update your status within 24 hours.',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Phone verification gate
    if (!user.isPhoneVerified) {
      final phoneNumber = _phoneCtrl.text.trim();
      final verified = await _showOtpSheet(phoneNumber);
      if (!verified) {
        // User tapped "Change Number" — let them edit the field and resubmit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Update your phone number and tap Submit again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }
      // Refresh user so isPhoneVerified is updated before submitting
      await ref.read(authProvider.notifier).refreshUser();
    }

    setState(() => _isSubmitting = true);
    try {
      final Map<String, dynamic> body = {
        'linkedinUrl': _linkedinCtrl.text.trim(),
      };

      if (user.isProfessional) {
        body['officeName'] = _officeNameCtrl.text.trim();
        body['jobTitle'] = _jobTitleCtrl.text.trim();
        body['cnicNumber'] = _cnicCtrl.text.trim().replaceAll('-', '').replaceAll(' ', '');
        body['officeLinkedinUrl'] = _officeLinkedinCtrl.text.trim();
        if (_cnicPhotoUrl != null) body['cnicPhotoUrl'] = _cnicPhotoUrl;
        if (_avatarUrl != null) body['avatarUrl'] = _avatarUrl;
      } else {
        body['universityName'] = _universityNameCtrl.text.trim();
        body['degreeDesignation'] = _degreeCtrl.text.trim();
        body['staffType'] = _staffType;
        if (_idCardPhotoUrl != null) body['idCardPhotoUrl'] = _idCardPhotoUrl;
        if (_avatarUrl != null) body['avatarUrl'] = _avatarUrl;
      }

      await DioClient.instance.patch(ApiConstants.myProfile, data: body);
      await DioClient.instance.post(ApiConstants.submitVerification);
      await ref.read(authProvider.notifier).refreshUser();

      if (mounted) _showSubmittedDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractApiError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            // ─── Rejection reason (if resubmitting) ──────────────────────
            if (user.isRejected && user.rejectionReason != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.error, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Reason for Decline',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.rejectionReason!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    user.isProfessional
                        ? Icons.business_center_outlined
                        : Icons.school_outlined,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isProfessional
                              ? 'Professional Verification'
                              : 'Student Verification',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.isRejected
                              ? 'Update your details and resubmit for review.'
                              : 'Fill in your details. Our team reviews within 24 hours.',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Profile Photo ────────────────────────────────────────────
            _SectionHeader(label: 'Profile Photo'),
            const SizedBox(height: 10),
            _PhotoPickerTile(
              label: 'Your Photo',
              hint: 'Clear face photo (optional)',
              file: _avatarFile,
              existingUrl: _avatarUrl,
              isLoading: _uploadingAvatar,
              onTap: () => _pickPhoto(
                fieldName: 'avatar',
                onFilePicked: (f) => setState(() => _avatarFile = f),
                onUrlSaved: (url) => setState(() => _avatarUrl = url),
                setLoading: (v) => setState(() => _uploadingAvatar = v),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Phone Number ─────────────────────────────────────────────
            _SectionHeader(label: 'Phone Number'),
            const SizedBox(height: 10),
            _AppTextField(
              controller: _phoneCtrl,
              label: 'Mobile Number',
              hint: '+92 300 1234567',
              required: true,
              enabled: !user.isPhoneVerified,
              keyboardType: TextInputType.phone,
              suffixIcon: user.isPhoneVerified
                  ? const Icon(Icons.check_circle, color: AppTheme.secondary, size: 20)
                  : null,
              extraValidator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),
            if (user.isPhoneVerified) ...[
              const SizedBox(height: 4),
              const Text(
                'Phone number verified and locked',
                style: TextStyle(fontSize: 11, color: AppTheme.secondary),
              ),
            ],

            const SizedBox(height: 20),

            // ─── Professional Fields ──────────────────────────────────────
            if (user.isProfessional) ...[
              _SectionHeader(label: 'LinkedIn'),
              const SizedBox(height: 10),
              _AppTextField(
                controller: _linkedinCtrl,
                label: 'Your LinkedIn Profile',
                hint: 'https://linkedin.com/in/yourname',
                required: true,
                keyboardType: TextInputType.url,
                extraValidator: _linkedinValidator,
              ),
              const SizedBox(height: 12),
              _AppTextField(
                controller: _officeLinkedinCtrl,
                label: 'Company LinkedIn Page',
                hint: 'https://linkedin.com/company/...',
                required: true,
                keyboardType: TextInputType.url,
                extraValidator: _linkedinValidator,
              ),
              const SizedBox(height: 20),
              _SectionHeader(label: 'Work Information'),
              const SizedBox(height: 10),
              _AppTextField(
                controller: _officeNameCtrl,
                label: 'Company / Office Name',
                hint: 'e.g. Engro Corporation',
                required: true,
              ),
              const SizedBox(height: 12),
              _AppTextField(
                controller: _jobTitleCtrl,
                label: 'Job Title',
                hint: 'e.g. Software Engineer',
                required: true,
              ),
              const SizedBox(height: 20),
              _SectionHeader(label: 'Identity Document'),
              const SizedBox(height: 10),
              _AppTextField(
                controller: _cnicCtrl,
                label: 'CNIC Number',
                hint: '3520112345671',
                required: true,
                keyboardType: TextInputType.number,
                maxLength: 13,
                extraValidator: _cnicValidator,
              ),
              const SizedBox(height: 12),
              _PhotoPickerTile(
                label: 'CNIC Photo',
                hint: 'Front side of your CNIC (optional)',
                file: _cnicPhotoFile,
                existingUrl: _cnicPhotoUrl,
                isLoading: _uploadingCnic,
                onTap: () => _pickPhoto(
                  fieldName: 'cnic',
                  onFilePicked: (f) => setState(() => _cnicPhotoFile = f),
                  onUrlSaved: (url) => setState(() => _cnicPhotoUrl = url),
                  setLoading: (v) => setState(() => _uploadingCnic = v),
                ),
              ),
            ],

            // ─── Student Fields ───────────────────────────────────────────
            if (user.isStudent) ...[
              _SectionHeader(label: 'LinkedIn'),
              const SizedBox(height: 10),
              _AppTextField(
                controller: _linkedinCtrl,
                label: 'Your LinkedIn Profile',
                hint: 'https://linkedin.com/in/yourname',
                required: true,
                keyboardType: TextInputType.url,
                extraValidator: _linkedinValidator,
              ),
              const SizedBox(height: 20),
              _SectionHeader(label: 'University Information'),
              const SizedBox(height: 10),
              _AppTextField(
                controller: _universityNameCtrl,
                label: 'University Name',
                hint: 'e.g. LUMS, NUST, UET',
                required: true,
              ),
              const SizedBox(height: 12),
              _AppTextField(
                controller: _degreeCtrl,
                label: 'Degree / Designation',
                hint: 'e.g. BS Computer Science',
                required: true,
              ),
              const SizedBox(height: 12),
              _ToggleField(
                label: 'Are you a Student or Staff?',
                options: const ['STUDENT', 'STAFF'],
                labels: const ['Student', 'Staff'],
                value: _staffType,
                onChanged: (v) => setState(() => _staffType = v),
              ),
              const SizedBox(height: 20),
              _SectionHeader(label: 'Identity Document'),
              const SizedBox(height: 10),
              _PhotoPickerTile(
                label: 'University Card / ID',
                hint: 'Photo of your university ID card (optional)',
                file: _idCardPhotoFile,
                existingUrl: _idCardPhotoUrl,
                isLoading: _uploadingIdCard,
                onTap: () => _pickPhoto(
                  fieldName: 'idCard',
                  onFilePicked: (f) => setState(() => _idCardPhotoFile = f),
                  onUrlSaved: (url) => setState(() => _idCardPhotoUrl = url),
                  setLoading: (v) => setState(() => _uploadingIdCard = v),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
          ),
          // ─── Sticky submit button (part of normal layout, no jank) ─────
          Container(
            color: AppTheme.surface,
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        user.isRejected ? 'Update & Resubmit' : 'Submit for Review',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OTP Bottom Sheet ─────────────────────────────────────────────────────────

class _OtpBottomSheet extends StatefulWidget {
  final String phoneNumber;
  const _OtpBottomSheet({required this.phoneNumber});

  @override
  State<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<_OtpBottomSheet> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  String? _resendMessage;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; _resendMessage = null; });
    try {
      await DioClient.instance.post(ApiConstants.sendPhoneOtp, data: {
        'phoneNumber': widget.phoneNumber,
      });
      _clearBoxes();
      setState(() => _resendMessage = 'New code sent!');
    } catch (e) {
      setState(() => _error = extractApiError(e));
    } finally {
      setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      await DioClient.instance.post(ApiConstants.verifyPhoneOtp, data: {
        'phoneNumber': widget.phoneNumber,
        'otp': _otp,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = extractApiError(e);
        _verifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textHint.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Icon(Icons.phone_android_outlined,
              color: AppTheme.primary, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Verify Your Phone',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-digit code sent to\n${widget.phoneNumber}',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 44,
                height: 52,
                child: TextFormField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                    setState(() { _error = null; _resendMessage = null; });
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          // Error / success message
          if (_error != null)
            Text(_error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 13),
                textAlign: TextAlign.center),
          if (_resendMessage != null)
            Text(_resendMessage!,
                style: const TextStyle(color: AppTheme.secondary, fontSize: 13),
                textAlign: TextAlign.center),

          const SizedBox(height: 20),

          // Verify button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Verify',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 12),

          // Resend + Change Number row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _resending ? null : _resend,
                child: _resending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Resend Code',
                        style: TextStyle(
                            color: AppTheme.primary, fontSize: 13)),
              ),
              const Text('·',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 16)),
              TextButton(
                onPressed: () => Navigator.pop(context, 'change'),
                child: const Text('Change Number',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final bool enabled;
  final TextInputType keyboardType;
  final String? Function(String?)? extraValidator;
  final Widget? suffixIcon;
  final int? maxLength;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.extraValidator,
    this.suffixIcon,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLength: maxLength,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        suffixIcon: suffixIcon,
        counterText: maxLength != null ? '' : null,
        filled: !enabled,
        fillColor: !enabled ? AppTheme.background : null,
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Required';
        if (extraValidator != null) return extraValidator!(v);
        return null;
      },
    );
  }
}

class _PhotoPickerTile extends StatelessWidget {
  final String label;
  final String hint;
  final File? file;
  final String? existingUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _PhotoPickerTile({
    required this.label,
    required this.hint,
    required this.file,
    required this.existingUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = file != null || existingUrl != null;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasPhoto
                ? AppTheme.secondary
                : AppTheme.textHint.withOpacity(0.5),
            width: hasPhoto ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasPhoto ? AppTheme.secondary.withOpacity(0.05) : AppTheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasPhoto
                    ? AppTheme.secondary.withOpacity(0.1)
                    : AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : file != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(file!, fit: BoxFit.cover))
                      : Icon(
                          hasPhoto
                              ? Icons.check_circle_outline
                              : Icons.add_photo_alternate_outlined,
                          color: hasPhoto ? AppTheme.secondary : AppTheme.textHint,
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color:
                          hasPhoto ? AppTheme.secondary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPhoto ? 'Tap to change' : hint,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ToggleField extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> labels;
  final String value;
  final void Function(String) onChanged;

  const _ToggleField({
    required this.label,
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(options.length, (i) {
            final selected = value == options[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(options[i]),
                child: Container(
                  margin: EdgeInsets.only(
                      right: i < options.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textHint.withOpacity(0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
