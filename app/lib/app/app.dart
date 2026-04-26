import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_dashboard_screen.dart';
import 'package:jansetu/features/home/screens/home_screen.dart';
import 'package:jansetu/features/onboarding/data/onboarding_repository.dart';
import 'package:jansetu/features/onboarding/domain/models/user_role.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:jansetu/features/onboarding/presentation/screens/language_select_screen.dart';
import 'package:jansetu/features/onboarding/presentation/screens/role_select_screen.dart';

import 'package:easy_localization/easy_localization.dart';

class JansetuApp extends StatelessWidget {
  const JansetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(
        repository: OnboardingRepository(),
      )..add(const OnboardingStatusChecked()),
      child: MaterialApp(
        title: 'Jansetu — Aarogya Sentinel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const _OnboardingRouter(),
      ),
    );
  }
}

/// Internal router that listens to [OnboardingBloc] status
/// and shows the correct screen.
class _OnboardingRouter extends StatelessWidget {
  const _OnboardingRouter();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        // Nothing extra for now — navigation is handled by builder.
      },
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _screenForState(state),
        );
      },
    );
  }

  Widget _screenForState(OnboardingState state) {
    switch (state.status) {
      case OnboardingStatus.initial:
        return const _SplashPlaceholder(key: ValueKey('splash'));
      case OnboardingStatus.languageSelect:
        return const LanguageSelectScreen(key: ValueKey('language'));
      case OnboardingStatus.roleSelect:
        return const RoleSelectScreen(key: ValueKey('role'));
      case OnboardingStatus.completed:
        if (state.selectedRole == UserRole.healthWorker) {
          return const AshaDashboardScreen(key: ValueKey('asha_home'));
        }
        return const HomeScreen(key: ValueKey('home'));
      case OnboardingStatus.error:
        return const LanguageSelectScreen(key: ValueKey('language_error'));
    }
  }
}

/// Minimal splash shown while checking secure storage on first launch.
class _SplashPlaceholder extends StatelessWidget {
  const _SplashPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Same concentric ring logo as language screen
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aarogya Sentinel',
              style: AppTextStyles.appTitle.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
