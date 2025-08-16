import 'package:flutter/material.dart';

/// 响应式布局包装器，用于在宽屏上居中显示内容
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final double wideScreenThreshold;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.maxWidth = 900,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.wideScreenThreshold = 1200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > wideScreenThreshold;

    if (!isWideScreen) {
      return child;
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        padding: padding,
        child: child,
      ),
    );
  }

  /// 判断当前屏幕是否为宽屏
  static bool isWideScreen(BuildContext context, [double threshold = 1200]) {
    return MediaQuery.of(context).size.width > threshold;
  }

  /// 根据屏幕宽度返回响应式尺寸
  /// 例如：responsiveSize(context, 16, 20, 24) 会根据屏幕是手机、平板还是桌面返回不同的尺寸
  static double responsiveSize(
    BuildContext context,
    double mobile,
    double tablet,
    double desktop,
  ) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return mobile;
    if (width < 1200) return tablet;
    return desktop;
  }
} 