import 'package:flutter/material.dart';

class Watermark extends StatelessWidget {
  const Watermark({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final asset = brightness == Brightness.dark
        ? 'assets/watermark_dark.png'
        : 'assets/watermark_light.png';

    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.06,
          child: Image.asset(
            asset,
            width: MediaQuery.of(context).size.width * 0.75,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
