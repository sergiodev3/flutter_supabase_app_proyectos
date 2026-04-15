// lib/core/theme/app_theme.dart
//
// ─── PROPÓSITO ───────────────────────────────────────────────────────────────
// Define el tema visual de la aplicación (colores, tipografía, componentes).
// Centralizar el tema permite cambiar toda la apariencia desde un solo archivo.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores de la aplicación.
/// Accede con: AppColors.primary, AppColors.todo, etc.
class AppColors {
  AppColors._();

  // Marca
  static const Color primary   = Color(0xFF6366F1); // Indigo-500
  static const Color secondary = Color(0xFF8B5CF6); // Violet-500
  static const Color surface   = Color(0xFFF8F9FF);
  static const Color error     = Color(0xFFEF4444);

  // Estados de tarea (usados en chips y bordes de tarjeta)
  static const Color todo       = Color(0xFF94A3B8); // Slate-400
  static const Color inProgress = Color(0xFFF59E0B); // Amber-500
  static const Color done       = Color(0xFF10B981); // Emerald-500

  // Prioridades
  static const Color low    = Color(0xFF10B981); // Verde
  static const Color medium = Color(0xFFF59E0B); // Amarillo
  static const Color high   = Color(0xFFEF4444); // Rojo
}

/// Clase principal del tema. Devuelve un [ThemeData] listo para usar en MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: Color(0xFF1E293B),  // Slate-800
      error: AppColors.error,
      onError: Colors.white,
    );

    // Usamos Inter de Google Fonts como tipografía principal.
    // Es estándar en diseño web moderno y muy legible en pantalla.
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate-100

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),

      // ── Tarjetas ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate-200
        ),
      ),

      // ── Botones elevados ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Campos de texto ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Chips ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
