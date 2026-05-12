import 'package:flutter/material.dart';

abstract final class AppColors {
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const cream = Color(0xFFFFF8EF);
  static const creamDark = Color(0xFFFFE8CC);
  static const orange = Color(0xFFFF9F68);
  static const orangeDeep = Color(0xFFFF7A3D);
  static const yellow = Color(0xFFFFF1B8);
  static const mint = Color(0xFFDDF7E3);
  static const sky = Color(0xFFDFF1FF);
  static const skyBlue = Color(0xFFBEE5FF);
  static const pink = Color(0xFFFFE1E8);
  static const brown900 = Color(0xFF3D332B);
  static const brown700 = Color(0xFF5B4636);
  static const brown500 = Color(0xFF7A6250);
  static const brown300 = Color(0xFFB9A999);

  static const primary = orangeDeep;
  static const primarySoft = Color(0xFFFFDCC7);
  static const primaryPressed = Color(0xFFE96631);

  static const surfaceWarm = Color(0xFFFFFBF5);
  static const surfaceSoft = Color(0xFFFFF7EC);
  static const surfaceBlue = sky;
  static const surfaceYellow = yellow;
  static const surfacePink = pink;
  static const surfaceMint = mint;

  static const accentBlue = Color(0xFF78C8FF);
  static const accentBlueSoft = skyBlue;
  static const blue = accentBlue;
  static const blueDeep = Color(0xFF46AEEA);
  static const tertiary = Color(0xFF66B7E8);

  static const textStrong = brown900;
  static const textPrimary = brown700;
  static const textSecondary = brown500;
  static const textMuted = brown300;

  static const borderSoft = Color(0xFFE9D8C8);
  static const borderWarm = creamDark;
  static const outlineVariant = borderSoft;

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF410002);
}
