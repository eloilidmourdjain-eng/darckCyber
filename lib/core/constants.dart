import 'package:flutter/material.dart';

// --- Couleurs Principales (Thème Cyber/Dark) ---
const Color kBackgroundColor = Color(0xFF0D0D12); // Fond sombre principal
const Color kSurfaceColor = Color(0xFF1A1A24);    // Fond des cartes et panneaux
const Color kAccentColor = Color(0xFF00FFC2);     // Vert fluo/cyan pour les actions principales
const Color kWarningColor = Color(0xFFFFB020);    // Orange pour les alertes modérées
const Color kErrorColor = Color(0xFFFF3366);      // Rouge pour les menaces/erreurs

// --- Couleurs de Texte ---
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF8F90A6);

// --- Styles de Texte Globaux ---
const TextStyle kHeadingStyle = TextStyle(
  color: kTextPrimary,
  fontSize: 24,
  fontWeight: FontWeight.bold,
  letterSpacing: 1.2,
);

const TextStyle kBodyStyle = TextStyle(
  color: kTextSecondary,
  fontSize: 14,
);

const TextStyle kAccentTextStyle = TextStyle(
  color: kAccentColor,
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

// --- Dimensions et Espacements ---
const double kPaddingDefault = 16.0;
const double kBorderRadius = 12.0;