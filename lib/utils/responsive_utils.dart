import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double mobileBreakPoint = 600;
  static const double tabletBreakPoint = 900;
  static const double desktopBreakPoint = 1200;

  // Các hàm kiểm tra loại màn hình
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobileBreakPoint;
  
    static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakPoint && MediaQuery.of(context).size.width < desktopBreakPoint;

    static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= desktopBreakPoint;

  // Hàm tính toán độ rộng tối đa của Card Đăng nhập để không bị kéo giãn quá đà trên màn hình to
  static double getLoginCardWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakPoint) return 520;
    if (width >= tabletBreakPoint) return 440;
    return width;
  }

  static double getContentMaxWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakPoint) return 1100;
    if (width >= tabletBreakPoint) return 840;
    return width;
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 32);
    }
    return const EdgeInsets.symmetric(horizontal: 48, vertical: 40);
  }
}