import 'package:flutter/material.dart';

class CustomLogoAuth extends StatelessWidget {
  const CustomLogoAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1), // Jaune très clair pour rappeler le thème Selamty
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          "assets/logo.png",
          height: 60,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}