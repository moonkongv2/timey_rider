import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 28.0;

  static BorderRadius get compactCard => BorderRadius.circular(md);
  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get panel => BorderRadius.circular(xxl);
  static BorderRadius get hero => BorderRadius.circular(32);
  static BorderRadius get button => BorderRadius.circular(lg);
  static BorderRadius get pill => BorderRadius.circular(999);
}
