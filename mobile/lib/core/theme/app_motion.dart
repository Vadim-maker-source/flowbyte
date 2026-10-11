import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const tap = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 150);
  static const state = Duration(milliseconds: 190);
  static const page = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 270);
  static const reward = Duration(milliseconds: 480);
  static const traceStep = Duration(milliseconds: 520);
  static const splash = Duration(milliseconds: 720);

  static const standard = Curves.easeOutCubic;
  static const expressive = Curves.easeOutQuart;
}
