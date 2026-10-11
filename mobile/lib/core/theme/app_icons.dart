import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

abstract final class AppIcons {
  static const home = FontAwesomeIcons.house;
  static const lessons = FontAwesomeIcons.listCheck;
  static const assistant = FontAwesomeIcons.message;
  static const settings = FontAwesomeIcons.gear;
  static const back = FontAwesomeIcons.chevronLeft;
  static const next = FontAwesomeIcons.chevronRight;
  static const lock = FontAwesomeIcons.lock;
  static const check = FontAwesomeIcons.check;
  static const close = FontAwesomeIcons.xmark;
  static const play = FontAwesomeIcons.play;
  static const lightbulb = FontAwesomeIcons.lightbulb;
  static const bolt = FontAwesomeIcons.bolt;
  static const rotate = FontAwesomeIcons.rotateLeft;
  static const grip = FontAwesomeIcons.gripLines;
  static const up = FontAwesomeIcons.chevronUp;
  static const down = FontAwesomeIcons.chevronDown;
  static const wifiOff = FontAwesomeIcons.wifi;
  static const info = FontAwesomeIcons.circleInfo;
  static const map = FontAwesomeIcons.route;
  static const flag = FontAwesomeIcons.flagCheckered;
  static const trophy = FontAwesomeIcons.trophy;
  static const profile = FontAwesomeIcons.userAstronaut;
  static const tasks = FontAwesomeIcons.clipboardCheck;
  static const certificate = FontAwesomeIcons.certificate;
  static const code = FontAwesomeIcons.code;
  static const book = FontAwesomeIcons.bookOpen;
  static const question = FontAwesomeIcons.circleQuestion;
  static const send = FontAwesomeIcons.paperPlane;
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 22, this.color, this.label});

  final FaIconData icon;
  final double size;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: FaIcon(icon, size: size, color: color),
  );
}
