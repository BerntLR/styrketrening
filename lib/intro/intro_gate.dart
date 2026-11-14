import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class IntroGate extends StatefulWidget {
  final Widget child;
  const IntroGate({super.key, required this.child});

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate>
    with SingleTickerProviderStateMixin {
  static const _fadeMs = 300;
  static const _holdEmblemMs = 1500;
  static const _holdComicMs = 1500;

  late final AnimationController _c;
  late final Animation<double> _opacity;

  late final String _comicAsset;
  String _asset = 'assets/emblem.png';

  @override
  void initState() {
    super.initState();

    final n = Random().nextInt(3) + 1; // 1..3
    _comicAsset = 'assets/tegneserie_$n.png';

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _fadeMs),
    );
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeInOut);

    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: _holdEmblemMs));
    if (!mounted) return;

    await _c.reverse();
    if (!mounted) return;

    setState(() {
      _asset = _comicAsset;
    });

    await _c.forward();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: _holdComicMs));
    if (!mounted) return;

    await _c.reverse();
    if (!mounted) return;

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => widget.child));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SizedBox(
            width: _asset == 'assets/emblem.png' ? w * 0.55 : w * 0.75,
            child: Image.asset(_asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
