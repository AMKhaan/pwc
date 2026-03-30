import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  final String? password;

  const VerifyEmailScreen({super.key, required this.email, this.password});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _otpCtrl = TextEditingController();
  bool _isResending = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyEmail(
          email: widget.email,
          token: _otpCtrl.text,
        );

    if (!success || !mounted) return;

    // Auto-login if password available
    if (widget.password != null && widget.password!.isNotEmpty) {
      final loggedIn = await ref.read(authProvider.notifier).login(
            email: widget.email,
            password: widget.password!,
          );

      if (!mounted) return;

      if (loggedIn) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
        if (!mounted) return;
        context.go(hasSeenOnboarding ? '/home' : '/onboarding');
        return;
      }
    }

    // Fallback: ask user to sign in manually
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! Please sign in.'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      context.go('/login');
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final success =
        await ref.read(authProvider.notifier).resendOtp(widget.email);
    setState(() => _isResending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Code resent to ${widget.email}' : 'Failed to resend'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.mark_email_read_outlined,
                  size: 56, color: AppTheme.primary),
              const SizedBox(height: 20),
              const Text(
                'Check your inbox',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),

              Pinput(
                controller: _otpCtrl,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                  ),
                ),
                onCompleted: (_) => _verify(),
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Verify',
                isLoading: state.isLoading,
                onPressed: _verify,
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive it? ",
                      style: TextStyle(color: AppTheme.textSecondary)),
                  TextButton(
                    onPressed: _isResending ? null : _resend,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend code'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

