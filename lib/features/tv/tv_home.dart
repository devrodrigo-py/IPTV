import 'package:flutter/material.dart';
import 'package:nebula_iptv/features/home/home_screen.dart';

/// TV and desktop share the catalogue; the shell owns safe area and focus.
class TvHome extends StatelessWidget {
  const TvHome({super.key});
  @override
  Widget build(BuildContext context) => const HomeScreen();
}
