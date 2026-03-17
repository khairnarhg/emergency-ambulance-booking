import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE53935);
  static const Color accent = Color(0xFF2563EB);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);

  static const Color statusCreated = Color(0xFFF59E0B);
  static const Color statusDispatching = Color(0xFFF59E0B);
  static const Color statusAssigned = Color(0xFF3B82F6);
  static const Color statusEnroute = Color(0xFF3B82F6);
  static const Color statusReached = Color(0xFF6366F1);
  static const Color statusPickedUp = Color(0xFF6366F1);
  static const Color statusEnrouteHospital = Color(0xFF6366F1);
  static const Color statusArrived = Color(0xFF22C55E);
  static const Color statusCompleted = Color(0xFF22C55E);
  static const Color statusCancelled = Color(0xFFEF4444);

  static Color forStatus(String status) {
    switch (status) {
      case 'CREATED':
      case 'DISPATCHING':
        return statusCreated;
      case 'AMBULANCE_ASSIGNED':
      case 'DRIVER_ENROUTE_TO_PATIENT':
        return statusAssigned;
      case 'REACHED_PATIENT':
      case 'PICKED_UP':
      case 'ENROUTE_TO_HOSPITAL':
        return statusReached;
      case 'ARRIVED_AT_HOSPITAL':
      case 'COMPLETED':
        return statusCompleted;
      case 'CANCELLED':
        return statusCancelled;
      default:
        return textSecondary;
    }
  }

  static Color forCriticality(String criticality) {
    switch (criticality.toUpperCase()) {
      case 'CRITICAL':
        return error;
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'MEDIUM':
        return warning;
      case 'LOW':
        return textSecondary;
      default:
        return textSecondary;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cardWhite,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
