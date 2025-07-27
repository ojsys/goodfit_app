import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                const Color(0xFFF5EBDC).withValues(alpha: 0.3), // #708238 at 0% with 50% opacity
                const Color(0xFFF5EBDC).withValues(alpha: 0.3), // #707859 at 100% with 50% opacity
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
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
                          color: const Color(0xFF708238),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'Good',
                        style: GoogleFonts.poly(
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF708238),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'Fit',
                        style: GoogleFonts.poly(
                          fontSize: 84,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF708238),
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
                      color: const Color(0xFF708238),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF708238)),
                        foregroundColor: const Color(0xFF708238),
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.poly(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF708238),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poly(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}