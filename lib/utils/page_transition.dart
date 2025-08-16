import 'package:flutter/material.dart';

class PageTransition {
  // 缩放淡入淡出
  static PageRouteBuilder<T> scale<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 250),
    Duration reverseDuration = const Duration(milliseconds: 200),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: curvedAnimation,
              curve: const Interval(0.0, 0.4),
            ),
          ),
          child: Transform.scale(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation).value,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  // 位移淡入淡出
  static PageRouteBuilder<T> slide<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 250),
    Duration reverseDuration = const Duration(milliseconds: 200),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: curvedAnimation,
              curve: const Interval(0.0, 0.4),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  // 长时间版本的位移淡入淡出，用于第一次导航到EULA
  static PageRouteBuilder<T> initial<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
    Duration reverseDuration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: curvedAnimation,
              curve: const Interval(0.0, 0.5),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  // 高级欢迎页到EULA过渡动画
  static PageRouteBuilder<T> welcomeToEula<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 700),
    Duration reverseDuration = const Duration(milliseconds: 500),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 自定义曲线
        final easeInOutQuintCurve = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.86, 0, 0.07, 1),
        );
        
        final fastInitialCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        );
        
        final scaleCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
        );
        
        final opacityCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        );

        return Stack(
          children: [
            // 背景色过渡
            AnimatedBuilder(
              animation: easeInOutQuintCurve,
              builder: (context, _) {
                return Container(
                  color: Color.lerp(
                    const Color(0xFF2196F3).withOpacity(0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                    easeInOutQuintCurve.value,
                  ),
                );
              },
            ),
            
            // 内容动画
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(fastInitialCurve),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.98,
                  end: 1.0,
                ).animate(scaleCurve),
                child: FadeTransition(
                  opacity: opacityCurve,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }

  // 引导页面间的高级页面过渡
  static PageRouteBuilder<T> onboardingStep<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    Duration reverseDuration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 创建更精细的动画曲线
        // ignore: unused_local_variable
        final slideUpCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
        );
        
        // ignore: unused_local_variable
        final slideSideCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuad),
        );
        
        final fadeInCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
        );
        
        final rotateCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
        );

        // 横向滑动+上升+旋转
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 添加透视效果
            ..rotateY(0.05 * (1.0 - rotateCurve.value)),
          alignment: Alignment.center,
          child: Stack(
            children: [
              // 背景淡入效果
              FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(fadeInCurve),
                child: Container(color: Theme.of(context).scaffoldBackgroundColor),
              ),
              
              // 内容混合动画
              FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(fadeInCurve),
                child: SlideTransition(
                  position: Tween<Offset>(
                    // 同时从右侧和底部滑入
                    begin: const Offset(0.3, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }
  
  // 从引导到主界面的最终过渡动画
  static PageRouteBuilder<T> finalTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 1000),
    Duration reverseDuration = const Duration(milliseconds: 700),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 创建不同阶段的动画曲线
        final firstStageCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        );
        
        final secondStageCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuint),
        );
        
        final colorCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
        );

        // 缓慢上升并带有缩放、旋转和颜色转变效果
        return Stack(
          children: [
            // 背景色渐变
            AnimatedBuilder(
              animation: colorCurve,
              builder: (context, _) {
                return Container(
                  color: Color.lerp(
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                    colorCurve.value,
                  ),
                );
              },
            ),
            
            // 主内容层 - 从小到大缩放效果
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // 添加透视效果
                ..translate(
                  0.0,
                  Tween<double>(
                    begin: 100.0,
                    end: 0.0,
                  ).animate(firstStageCurve).value,
                )
                ..scale(
                  Tween<double>(
                    begin: 0.7,
                    end: 1.0,
                  ).animate(secondStageCurve).value,
                ),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(firstStageCurve),
                child: child,
              ),
            ),
          ],
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }
}

// 保留原来的CustomPageRoute类以保持兼容
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  CustomPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeOutCubic;

            var fadeAnimation = Tween<double>(
              begin: begin,
              end: end,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.3, curve: curve),
            ));

            var scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.3, curve: curve),
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: child,
              ),
            );
          },
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );
}

class CustomScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  CustomScalePageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.95;
            const end = 1.0;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));
            var scaleAnimation = animation.drive(tween);

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

class CustomSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Offset begin;
  final Offset end;

  CustomSlidePageRoute({
    required this.child,
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
  }) : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
} 