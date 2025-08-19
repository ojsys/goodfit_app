import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    // Wait for splash screen display (2 seconds minimum)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Test connection first
    await authProvider.testConnection();
    
    if (!mounted) return;
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      // User is logged in, go to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User not logged in, go to welcome screen
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF708238).withValues(alpha: 0.5), // #708238 at 0% with 80% opacity
                const Color(0xFF707859).withValues(alpha: 0.5), // #707859 at 100% with 80% opacity
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Navigation icon
                Positioned(
                  top: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/welcome'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  
                  // Logo block - centered overall but logo text left-aligned within block
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo text - left aligned within centered block using Poly font
                      Text(
                        'A',
                        style: GoogleFonts.poly(
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'Good',
                        style: GoogleFonts.poly(
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'Fit',
                        style: GoogleFonts.poly(
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tagline - centered
                  Text(
                    'Wellness. Connections. Community',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}