import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:atm_project_unic/main.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
   
    Timer(const Duration(milliseconds: 6000), () {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.green.shade900.withOpacity(0.3), Colors.black],
            radius: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
           ClipRRect(
  borderRadius: BorderRadius.circular(180.0), 
  child: Image.asset(
    'assets/finals.png',
    width: 250,
    height: 250,
    fit: BoxFit.cover, 
  ),
)
                .animate()
                .fade(duration: 800.ms)
                .scale(
                  delay: 200.ms, 
                  duration: 600.ms, 
                  curve: Curves.easeOutBack, 
                )
                .shimmer(delay: 1500.ms, duration: 1200.ms, color: Colors.greenAccent)
                .moveY(begin: 0, end: -20, delay: 3000.ms, duration: 1000.ms, curve: Curves.easeInOut),

            const SizedBox(height: 40),

          
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(blurRadius: 10, color: Colors.green, offset: Offset(0, 0))
                ],
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'SECURITY BANK',
                    speed: const Duration(milliseconds: 150),
                  ),
                  FadeAnimatedText('І.Третяк ІСТ23б'),
                ],
                totalRepeatCount: 1,
              ),
            ).animate().fadeIn(delay: 1000.ms),

            const SizedBox(height: 60),

          
            const CircularProgressIndicator(
              color: Colors.greenAccent,
              strokeWidth: 2,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2.seconds, color: Colors.white)
                .scale(duration: 1.seconds, curve: Curves.easeInOut),
          ],
        ),
      ),
    );
  }
}