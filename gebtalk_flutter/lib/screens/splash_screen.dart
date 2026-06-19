import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/app_state.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  void _navigateNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.authenticated) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(seconds: 1),
      ));
    } else {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Deep Space Particles/Stars Simulation (Simplified with Animate)
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://images.unsplash.com/photo-1534796636912-3652850a3011?auto=format&fit=crop&w=1920&q=80',
                fit: BoxFit.cover,
              ).animate().fade(duration: 2.seconds).scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 10.seconds),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo Orb
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
                      BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 60, spreadRadius: 20),
                    ],
                  ),
                  child: Center(
                    child: Image.network('https://cdn-icons-png.flaticon.com/512/3655/3655554.png', width: 60, color: AppColors.primary)
                      .animate()
                      .shimmer(duration: 2.seconds, color: Colors.white),
                  ),
                )
                .animate()
                .scale(begin: const Offset(0, 0), curve: Curves.easeOutBack, duration: 1.seconds)
                .then()
                .moveY(begin: 0, end: -10, duration: 2.seconds, curve: Curves.easeInOut)
                .then()
                .moveY(begin: -10, end: 0, duration: 2.seconds, curve: Curves.easeInOut),
                
                const SizedBox(height: 40),
                
                // Cinematic Text
                const Text(
                  "GEBTALK X",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    letterSpacing: 8,
                    fontFamily: 'Product Sans'
                  ),
                )
                .animate()
                .fadeIn(delay: 800.ms, duration: 1.seconds)
                .slideY(begin: 0.2, end: 0)
                .shimmer(delay: 2.seconds, duration: 1.seconds, color: AppColors.primary),
                
                const SizedBox(height: 16),
                
                const Text(
                  "DIGITAL HEADQUARTERS ONLINE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                )
                .animate()
                .fadeIn(delay: 1500.ms, duration: 800.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
