import 'package:flutter/material.dart';

class AppPageScaffold extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool center;

  const AppPageScaffold({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            );

            return center
                ? Center(
                    child: SingleChildScrollView(child: content),
                  )
                : SingleChildScrollView(child: content);
          },
        ),
      ),
    );
  }
}
