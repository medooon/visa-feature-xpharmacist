import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/localization/app_localization_cubit.dart';
import 'package:flutterquiz/features/localization/quiz_language_cubit.dart';
import 'package:flutterquiz/features/settings/settings_cubit.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/widgets/custom_image.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:flutterquiz/utils/gdpr_helper.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleUpAnimation;
  late Animation<double> _logoScaleDownAnimation;

  bool _systemConfigLoaded = false;

  final _appLogoPath = Assets.splashLogo;
  final _orgLogoPath = Assets.orgLogo;
  final showCompanyLogo = true;

  @override
  void initState() {
    super.initState();
    _initLanguage();
    _initAnimations();
    _fetchSystemConfig();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initLanguage() async {
    await context.read<AppLocalizationCubit>().init();
  }

  void _initAnimations() {
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        if (_logoAnimationController.isCompleted) {
          _navigateToNextScreen();
        }
      });
    _logoScaleUpAnimation = Tween<double>(begin: 0, end: 1.1).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0, 0.4, curve: Curves.ease),
      ),
    );
    _logoScaleDownAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.4, 1, curve: Curves.easeInOut),
      ),
    );

    _logoAnimationController.forward();
  }

  Future<void> _initUnityAds() async {
    await UnityAds.init(
      gameId: context.read<SystemConfigCubit>().unityGameId,
      testMode: true,
      onComplete: () => log('Initialized', name: 'Unity Ads'),
      onFailed: (err, msg) =>
          log('Initialization Failed: $err $msg', name: 'Unity Ads'),
    );
  }

  Future<void> _fetchSystemConfig() async {
    await context.read<SystemConfigCubit>().getSystemConfig();
    await GdprHelper.initialize();
  }

  Future<void> _navigateToNextScreen() async {
    if (!_systemConfigLoaded) return;

    await _initUnityAds();

    final showIntroSlider =
        context.read<SettingsCubit>().state.settingsModel!.showIntroSlider;
    final currAuthState = context.read<AuthCubit>().state;

    if (showIntroSlider) {
      if (context.read<SystemConfigCubit>().isLanguageModeEnabled) {
        final defaultQuizLanguage = context
            .read<SystemConfigCubit>()
            .supportedQuizLanguages
            .firstWhere((e) => e.isDefault);

        context.read<QuizLanguageCubit>().languageId = defaultQuizLanguage.id;
      }

      if (context.read<AppLocalizationCubit>().state.systemLanguages.length >
          1) {
        await Navigator.of(context).pushReplacementNamed(Routes.languageSelect);
      } else {
        await Navigator.of(context).pushReplacementNamed(Routes.introSlider);
      }
      return;
    }

    if (currAuthState is Authenticated) {
      await Navigator.of(context).pushReplacementNamed(
        Routes.home,
        arguments: false,
      );
    } else {
      await Navigator.of(context).pushReplacementNamed(
        Routes.home,
        arguments: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SystemConfigCubit, SystemConfigState>(
      bloc: context.read<SystemConfigCubit>(),
      listener: (context, state) {
        if (state is SystemConfigFetchSuccess) {
          if (!_systemConfigLoaded) {
            _systemConfigLoaded = true;
          }

          if (_logoAnimationController.isCompleted) {
            _navigateToNextScreen();
          }
        }
      },
      builder: (context, state) {
        if (state is SystemConfigFetchFailure) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                Center(
                  key: const Key('errorContainer'),
                  child: ErrorContainer(
                    showBackButton: true,
                    errorMessageColor: Theme.of(context).colorScheme.onTertiary,
                    errorMessage: convertErrorCodeToLanguageKey(state.errorCode),
                    onTapRetry: () {
                      setState(_initAnimations);
                      _fetchSystemConfig();
                    },
                    showErrorImage: true,
                  ),
                ),

                /// Egypt Drug Index Button at Bottom
                Positioned(
                  bottom: 20, // Adjust bottom padding
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16), // Add side padding
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(Routes.guessTheWord);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink, // Button color
                        padding: const EdgeInsets.symmetric(vertical: 16), // Increase height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // Optional rounded corners
                        ),
                      ),
                      child: const Text(
                        'Drug Index',
                        style: TextStyle(
                          color: Colors.white, // White text
                          fontWeight: FontWeight.bold, // Bold font
                          fontSize: 18, // Larger font size
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          body: SizedBox.expand(
            child: Stack(
              children: [
                Align(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    child: AnimatedBuilder(
                      animation: _logoAnimationController,
                      builder: (_, __) => Transform.scale(
                        scale: _logoScaleUpAnimation.value -
                            _logoScaleDownAnimation.value,
                        child: QImage(
                          imageUrl: _appLogoPath,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                if (showCompanyLogo)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: QImage(imageUrl: _orgLogoPath),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
