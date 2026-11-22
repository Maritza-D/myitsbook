import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSymbolLogo extends StatelessWidget {
  const AppSymbolLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      isDark
          ? 'assets/logo/myitsbook-symbol-on-dark.svg'
          : 'assets/logo/myitsbook-symbol.svg',
      width: size,
      height: size,
      semanticsLabel: 'Logo MyITSBook',
    );
  }
}

class AppHorizontalLogo extends StatelessWidget {
  const AppHorizontalLogo({super.key, this.height = 36});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      isDark
          ? 'assets/logo/myitsbook-horizontal-on-dark.svg'
          : 'assets/logo/myitsbook-horizontal.svg',
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: 'MyITSBook',
    );
  }
}
