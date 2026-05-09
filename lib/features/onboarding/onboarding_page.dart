import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  const OnboardingPage({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Stack(
            children: [
              // Skip
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: () => _save('You'),
                  child: Text(
                    'Skip',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(
                          colors: [
                            AppColors.accentPrimary,
                            AppColors.accentSecondary,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Nexus',
                          style: AppTypography.pageTitle.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect your goals. Build your life.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 56),

                      // Name input
                      Text(
                        "What's your name?",
                        style: AppTypography.cardTitle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name...',
                        ),
                        onSubmitted: (_) => _save(_nameCtrl.text),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _save(_nameCtrl.text),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Get Started'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(String rawName) async {
    if (_saving) return;
    setState(() => _saving = true);
    final name = rawName.trim().isEmpty ? 'You' : rawName.trim();
    await ref.read(databaseProvider).updateProfile(
          UserProfilesCompanion(
            displayName: Value(name),
            onboardingDone: const Value(1),
          ),
        );
    ref.invalidate(profileProvider);
    widget.onComplete();
  }
}
