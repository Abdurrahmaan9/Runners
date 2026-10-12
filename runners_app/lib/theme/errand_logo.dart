import 'package:material_ui/material_ui.dart';

enum ErrandLogoStyle { lockup, mark, runner }

class ErrandLogo extends StatelessWidget {
  const new({
    super.key,
    this.style = ErrandLogoStyle.lockup,
    this.onBrand = false,
    this.height = 36,
  });

  final ErrandLogoStyle style;
  final bool onBrand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = onBrand || Theme.of(context).brightness == Brightness.dark;
    final asset = switch (style) {
      ErrandLogoStyle.runner =>
        'assets/errand-logo-kit/png/errand-mark-runner-amber-512.png',
      ErrandLogoStyle.mark =>
        dark
            ? 'assets/errand-logo-kit/png/errand-mark-white-512.png'
            : 'assets/errand-logo-kit/png/errand-mark-teal-512.png',
      ErrandLogoStyle.lockup =>
        dark
            ? 'assets/errand-logo-kit/png/errand-lockup-for-dark-bg.png'
            : 'assets/errand-logo-kit/png/errand-lockup-for-light-bg.png',
    };
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Errand',
    );
  }
}
