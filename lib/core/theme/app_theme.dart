import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Vibrant Neutral Palette (Zinc / Slate with Electric Accents)
  static const primary = Color(0xFF0066FF); // Electric Blue
  static const primarySurface = Color(0xFFE6F0FF);
  
  static const secondary = Color(0xFF10B981); // Emerald
  static const secondarySurface = Color(0xFFECFDF5);
  
  static const background = Color(0xFFF9FAFB); // Very Light Gray
  static const surface = Colors.white;
  static const surfaceElevated = Color(0xFFF3F4F6); // Same as borderLight
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3F4F6);
  
  static const textPrimary = Color(0xFF0F172A); // Zinc-950
  static const textSecondary = Color(0xFF64748B); // Slate-500
  static const textTertiary = Color(0xFF94A3B8);
  
  static const success = Color(0xFF10B981);
  static const successSurface = Color(0xFFF0FDF4);
  static const error = Color(0xFFEF4444);
  static const danger = error;
  static const dangerSurface = Color(0xFFFEF2F2);
  static const warning = Color(0xFFF59E0B);
  static const warningSurface = Color(0xFFFFFBEB);
  
  static const badgeNew = Color(0xFF3B82F6);
  static const badgeNewSurface = Color(0xFFEFF6FF);
  static const badgeBooked = Color(0xFF8B5CF6);
  static const badgeBookedSurface = Color(0xFFF5F3FF);
  static const badgeLost = Color(0xFF94A3B8);
  static const badgeLostSurface = Color(0xFFF8FAFC);
  static const badgeCompleted = Color(0xFF10B981);
  static const badgeCompletedSurface = Color(0xFFECFDF5);
  
  static const glassBorder = Color(0x33FFFFFF);
  static const glassBackground = Color(0x1AFFFFFF);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}

/// A premium glassmorphism container with refraction border
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: border ?? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
