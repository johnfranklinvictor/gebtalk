import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/ebi_bot.dart';
import '../widgets/animations.dart';
import '../theme/colors.dart';
import 'chat_list_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';
import '../utils/countries.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  Country _selectedCountry = Countries.list[0]; // Sri Lanka as default
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool _otpSent = false;
  bool _isCelebrating = false;
  String _errorMessage = '';

  // --- Animation controllers ---
  late AnimationController _bgController;
  late AnimationController _floatController1;
  late AnimationController _floatController2;
  late AnimationController _floatController3;
  late AnimationController _logoController;
  late AnimationController _celebrationController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _celebrationScale;

  // OTP digit scale animations (one per box)
  final List<double> _otpScales = [1.0, 1.0, 1.0, 1.0];

  @override
  void initState() {
    super.initState();

    // Background gradient shift – 8 second loop
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Floating decorative circles – three different periods
    _floatController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _floatController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _floatController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Logo entrance – elastic bounce
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Celebration overlay bounce
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    // Kick off logo entrance after a tiny delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _bgController.dispose();
    _floatController1.dispose();
    _floatController2.dispose();
    _floatController3.dispose();
    _logoController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  // ----- Business logic (unchanged) -----

  void _sendOtpCode() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your full name';
      });
      return;
    }

    final phoneNum = _phoneController.text.trim();
    if (phoneNum.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    final digits = phoneNum.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(_selectedCountry.regexPattern).hasMatch(digits)) {
      setState(() {
        _errorMessage = 'Invalid format for ${_selectedCountry.name}';
      });
      return;
    }

    final fullPhone = '${_selectedCountry.code} $phoneNum';

    final appState = Provider.of<AppState>(context, listen: false);
    appState.setPhoneNumber(fullPhone);

    setState(() {
      _errorMessage = '';
    });

    // Try sending OTP via API, proceed to verification screen in any case
    await ApiService.sendOtp(fullPhone);
    setState(() {
      _otpSent = true;
    });
  }

  void _verifyOtpCode() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      setState(() {
        _errorMessage = 'Please enter the 4-digit code';
      });
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.verifyOtpCode(
      otp,
      name: _nameController.text.trim(),
      countryCode: _selectedCountry.code,
      countryName: _selectedCountry.name,
      countryFlag: _selectedCountry.flag,
    );

    if (success) {
      // Trigger EBI Celebration Overlay
      setState(() {
        _isCelebrating = true;
        _errorMessage = '';
      });
      _celebrationController.forward();

      // Automatically redirect to Home screen after 2 seconds
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid validation code. Try again!';
      });
    }
  }

  // Animate an OTP box when user types a digit
  void _animateOtpBox(int index) {
    setState(() => _otpScales[index] = 1.18);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _otpScales[index] = 1.0);
    });
  }

  void _showServerSettingsDialog() {
    final TextEditingController urlController = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: AppColors.midnightNavy.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.dns_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'SERVER_SETTINGS',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API BASE URL:',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'http://10.0.2.2:5000/api',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: AppColors.deepSpaceBlack.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '• Emulator: http://10.0.2.2:5000/api\n'
                  '• Local PC: http://127.0.0.1:5000/api\n'
                  '• Physical Phone: Use host IP (e.g. http://192.168.1.X:5000/api)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.deepSpaceBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  String newUrl = urlController.text.trim();
                  if (newUrl.isNotEmpty) {
                    setState(() {
                      ApiService.baseUrl = newUrl;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('API base URL updated to: $newUrl'),
                        backgroundColor: AppColors.electricBlue,
                      ),
                    );
                  }
                },
                child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----- Build helpers -----

  /// Animated gradient background
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final t = _bgController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(sin(t * pi), cos(t * pi)),
              radius: 1.5 + (sin(t * pi) * 0.2),
              colors: [
                AppColors.deepSpaceBlack,
                AppColors.midnightNavy,
                Color.lerp(AppColors.midnightNavy, AppColors.electricBlue.withOpacity(0.2), t)!,
              ],
              stops: const [0.2, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Grid overlay for futuristic feel
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPainter(
                    color: AppColors.electricBlue.withOpacity(0.05),
                    spacing: 40.0,
                    offset: Offset(0, t * 40),
                  ),
                ),
              ),
              // Floating light orbs
              Positioned.fill(
                child: Stack(
                  children: [
                    _buildFloatingCircle(
                      controller: _floatController1,
                      baseX: MediaQuery.of(context).size.width * 0.2,
                      baseY: MediaQuery.of(context).size.height * 0.3,
                      radiusX: 60, radiusY: 40, size: 200,
                      color: AppColors.electricBlue.withOpacity(0.15),
                    ),
                    _buildFloatingCircle(
                      controller: _floatController2,
                      baseX: MediaQuery.of(context).size.width * 0.8,
                      baseY: MediaQuery.of(context).size.height * 0.6,
                      radiusX: 80, radiusY: 100, size: 300,
                      color: AppColors.darkTeal.withOpacity(0.15),
                    ),
                    _buildFloatingCircle(
                      controller: _floatController3,
                      baseX: MediaQuery.of(context).size.width * 0.5,
                      baseY: MediaQuery.of(context).size.height * 0.8,
                      radiusX: 50, radiusY: 70, size: 150,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingCircle({
    required AnimationController controller,
    required double baseX,
    required double baseY,
    required double radiusX,
    required double radiusY,
    required double size,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final angle = controller.value * 2 * pi;
        final dx = baseX + sin(angle) * radiusX;
        final dy = baseY + cos(angle) * radiusY;
        return Positioned(
          left: dx,
          top: dy,
          child: Transform.translate(
            offset: Offset(sin(angle * 1.3) * 8, cos(angle * 0.7) * 8),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The glassmorphic card that holds all inputs
  Widget _buildGlassCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
      decoration: BoxDecoration(
        color: AppColors.midnightNavy.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepSpaceBlack.withValues(alpha: 0.8),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 60,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                _otpSent ? "SYSTEM_VERIFICATION" : "ACCESS_PORTAL",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'ProductSans',
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? "ENTER 4-DIGIT SECURITY CLEARANCE SENT TO ${_phoneController.text}"
                    : "ENTER CREDENTIALS TO INITIALIZE SECURE CONNECTION",
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                _buildNameInput(),
                const SizedBox(height: 16),
                _buildPhoneInput(),
              ] else ...[
                _buildOtpBoxes(),
              ],

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // CTA Button
              _buildCtaButton(isLoading),

              if (_otpSent) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                      for (var c in _otpControllers) {
                        c.clear();
                      }
                    });
                  },
                  child: const Text(
                    "[ ABORT_VERIFICATION ]",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final TextEditingController searchController = TextEditingController();
            List<Country> filteredCountries = List.from(Countries.list);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppColors.midnightNavy.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Column(
                    children: [
                      // Pull bar
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "SELECT COUNTRY CODE",
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            setModalState(() {
                              filteredCountries = Countries.list.where((c) {
                                final nameMatch = c.name.toLowerCase().contains(val.toLowerCase());
                                final codeMatch = c.code.contains(val);
                                return nameMatch || codeMatch;
                              }).toList();
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                            hintText: "Search by country name or code...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: AppColors.deepSpaceBlack.withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: filteredCountries.length,
                          itemBuilder: (context, index) {
                            final c = filteredCountries[index];
                            final isSelected = c.code == _selectedCountry.code && c.name == _selectedCountry.name;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCountry = c;
                                  _errorMessage = '';
                                  // Format current text under new rules
                                  final formatted = Countries.formatNumber(_phoneController.text, c);
                                  _phoneController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(c.flag, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        style: TextStyle(
                                          color: isSelected ? AppColors.primaryLight : Colors.white,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      c.code,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Glassmorphic text input for full name
  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.deepSpaceBlack.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3), width: 1.0),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
            ),
            Container(
              width: 1,
              height: 32,
              color: AppColors.borderLight.withValues(alpha: 0.3),
            ),
            Expanded(
              child: TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: "Enter Full Name",
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.0,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill-shaped phone input with country selector and text field inside
  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.deepSpaceBlack.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3), width: 1.0),
        ),
        child: Row(
          children: [
            // Country flag & code dropdown button
            InkWell(
              onTap: _showCountryPicker,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedCountry.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCountry.code,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: AppColors.borderLight.withValues(alpha: 0.3),
            ),
            // Phone Number Input
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                onChanged: (value) {
                  final formatted = Countries.formatNumber(value, _selectedCountry);
                  if (formatted != value) {
                    _phoneController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  // Clear error messages as user corrects input
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: _selectedCountry.formatPlaceholder,
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Animated OTP digit boxes
  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _otpScales[index]),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 55,
                height: 65,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _otpFocusNodes[index].hasFocus ? 0.3 : 0.05),
                      blurRadius: _otpFocusNodes[index].hasFocus ? 20 : 5,
                      spreadRadius: _otpFocusNodes[index].hasFocus ? 2 : 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryLight,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    filled: true,
                    fillColor: AppColors.deepSpaceBlack.withValues(alpha: 0.6),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.electricBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty) {
                      _animateOtpBox(index);
                      if (index < 3) {
                        FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
                      } else {
                        FocusScope.of(context).unfocus();
                        _verifyOtpCode();
                      }
                    } else if (val.isEmpty && index > 0) {
                      FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
                    }
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Call to action button
  Widget _buildCtaButton(bool isLoading) {
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setStateLocal(() => isHovered = true),
          onExit: (_) => setStateLocal(() => isHovered = false),
          child: GestureDetector(
            onTap: isLoading ? null : (_otpSent ? _verifyOtpCode : _sendOtpCode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    isHovered ? AppColors.primaryLight : AppColors.primaryDark,
                    AppColors.electricBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isHovered ? 0.6 : 0.3),
                    blurRadius: isHovered ? 25 : 15,
                    spreadRadius: isHovered ? 5 : 2,
                  ),
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.4),
                    blurRadius: isHovered ? 30 : 10,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(
                  color: AppColors.softWhite.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.deepSpaceBlack,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _otpSent ? "INITIALIZE" : "CONNECT",
                            style: const TextStyle(
                              color: AppColors.deepSpaceBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.deepSpaceBlack,
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      }
    );
  }

  /// Celebration overlay with brand gradient and golden ring
  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deepSpaceBlack.withValues(alpha: 0.97),
                AppColors.midnightNavy.withValues(alpha: 0.95),
                AppColors.electricBlue.withValues(alpha: 0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Celebratory icon with golden ring
                ScaleTransition(
                  scale: _celebrationScale,
                  child: Container(
                    padding: const EdgeInsets.all(36.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.electricBlue,
                          AppColors.primary.withValues(alpha: 0.9),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.secondaryLight,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryLight.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.thumb_up,
                      color: AppColors.secondaryLight,
                      size: 72,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  "EBI VERIFIED!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                    fontFamily: 'ProductSans',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Launching secure workspace...",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.secondaryLight.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----- Main build -----

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AppState>(context).isLoading;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.deepSpaceBlack,
      body: Stack(
        children: [
          // 1. Animated gradient background
          _buildAnimatedBackground(),

          // 2. Floating decorative shapes
          _buildFloatingCircle(
            controller: _floatController1,
            baseX: screenSize.width * 0.7,
            baseY: -60,
            radiusX: 40,
            radiusY: 30,
            size: 220,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
          _buildFloatingCircle(
            controller: _floatController2,
            baseX: -80,
            baseY: screenSize.height * 0.6,
            radiusX: 30,
            radiusY: 50,
            size: 280,
            color: AppColors.secondary.withValues(alpha: 0.06),
          ),
          _buildFloatingCircle(
            controller: _floatController3,
            baseX: screenSize.width * 0.3,
            baseY: screenSize.height * 0.15,
            radiusX: 25,
            radiusY: 20,
            size: 120,
            color: AppColors.tealGlow.withValues(alpha: 0.07),
          ),

          // 3. Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with entrance animation
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - _logoOpacity.value) * -30),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AnimatedListItem(
                    index: 0,
                    child: Text(
                      "GEBTALK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        fontFamily: 'Product Sans',
                        fontFamilyFallback: ['ProductSans', 'GoogleSans', 'sans-serif'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedListItem(
                    index: 1,
                    child: Text(
                      "Premium Business Communication Hub",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphic input card
                  AnimatedListItem(
                    index: 2,
                    child: _buildGlassCard(isLoading),
                  ),
                ],
              ),
            ),
          ),

          // 4. Celebration overlay
          if (_isCelebrating) _buildCelebrationOverlay(),

          // 5. Server Connection Settings (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: const Icon(
                Icons.settings_suggest_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              onPressed: _showServerSettingsDialog,
              tooltip: 'Server Connection Settings',
            ),
          ),

          // 6. EbiBot
          const EbiBot(screen: 'auth'),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final Offset offset;

  GridPainter({required this.color, required this.spacing, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = offset.dx % spacing; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = offset.dy % spacing; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.color != color;
  }
}
