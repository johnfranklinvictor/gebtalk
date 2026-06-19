import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/colors.dart';
import 'utils/error_handler.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const GebTalkApp(),
    ),
  );
}

class GebTalkApp extends StatelessWidget {
  const GebTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEBTALK',
      scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Product Sans',
        fontFamilyFallback: const <String>['ProductSans', 'GoogleSans', 'sans-serif'],
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textMain,
          elevation: 0,
        ),
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          background: AppColors.background,
          surface: AppColors.surface,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onBackground: AppColors.textMain,
          onSurface: AppColors.textMain,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
        ),
        // Enhanced input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        // Enhanced elevation with softer shadows
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          color: AppColors.surface,
        ),
      ),
      builder: (context, child) {
        final double width = MediaQuery.of(context).size.width;
        final bool isMobileDevice = width < 600;

        Widget body;
        if (isMobileDevice) {
          body = Scaffold(
            backgroundColor: AppColors.background,
            body: child,
          );
        } else {
          body = Scaffold(
            backgroundColor: AppColors.deepSpaceBlack,
            body: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                constraints: const BoxConstraints(
                  maxWidth: 450,
                  maxHeight: 820,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(32.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: child,
              ),
            ),
          );
        }

        return body;
      },
      home: const SplashScreen(),
    );
  }
}
