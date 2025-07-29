import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme Colors - نظام ألوان موحد لجميع الأدوار
const Color COLOR_PRIMARY = Color(0xFF3b6939);
const Color COLOR_BACKGROUND = Color(0xFFF9F9F9);
const Color COLOR_ACCENT = Color(0xFFFFC107);
const Color COLOR_TEXT_PRIMARY = Color(0xFF333333);
const Color COLOR_TEXT_SECONDARY = Color(0xFF757575);
const Color COLOR_WHITE = Colors.white;
const Color COLOR_SUCCESS = Color(0xFF4CAF50);
const Color COLOR_WARNING = Color(0xFFFF9800);
const Color COLOR_ERROR = Color(0xFFF44336);
const Color COLOR_INFO = Color(0xFF2196F3);

// Role-specific accent colors - ألوان مميزة لكل دور
const Color COLOR_DONOR_ACCENT = Color(0xFF4CAF50);
const Color COLOR_VOLUNTEER_ACCENT = Color(0xFF2196F3);
const Color COLOR_ASSOCIATION_ACCENT = Color(0xFF9C27B0);
const Color COLOR_MANAGER_ACCENT = Color(0xFFFF5722);

// Spacing - نظام مسافات موحد
const double SPACING_UNIT = 8.0;
const double SPACING_XS = SPACING_UNIT * 0.5;
const double SPACING_SM = SPACING_UNIT;
const double SPACING_MD = SPACING_UNIT * 2;
const double SPACING_LG = SPACING_UNIT * 3;
const double SPACING_XL = SPACING_UNIT * 4;

// Border Radius - نظام حواف موحد
const double BORDER_RADIUS_SMALL = 8.0;
const double BORDER_RADIUS_MEDIUM = 12.0;
const double BORDER_RADIUS_LARGE = 16.0;
const double BORDER_RADIUS_XL = 24.0;

// Elevation - نظام ظلال موحد
const double ELEVATION_LOW = 2.0;
const double ELEVATION_MEDIUM = 4.0;
const double ELEVATION_HIGH = 8.0;

// Animation Duration - مدة الحركات الموحدة
const Duration ANIMATION_DURATION_SHORT = Duration(milliseconds: 200);
const Duration ANIMATION_DURATION_MEDIUM = Duration(milliseconds: 300);
const Duration ANIMATION_DURATION_LONG = Duration(milliseconds: 500);

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.cairoTextTheme(baseTheme.textTheme).apply(
      bodyColor: COLOR_TEXT_PRIMARY,
      displayColor: COLOR_TEXT_PRIMARY,
    );

    return baseTheme.copyWith(
      primaryColor: COLOR_PRIMARY,
      scaffoldBackgroundColor: COLOR_BACKGROUND,
      colorScheme: const ColorScheme.light(
        primary: COLOR_PRIMARY,
        secondary: COLOR_ACCENT,
        tertiary: COLOR_INFO,
        surface: COLOR_WHITE,
        onPrimary: COLOR_WHITE,
        onSecondary: COLOR_TEXT_PRIMARY,
        onTertiary: COLOR_WHITE,
        onSurface: COLOR_TEXT_PRIMARY,
        error: COLOR_ERROR,
        onError: COLOR_WHITE,
        brightness: Brightness.light,
        outline: COLOR_TEXT_SECONDARY,
        surfaceContainerHighest: COLOR_BACKGROUND,
        onSurfaceVariant: COLOR_TEXT_SECONDARY,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: COLOR_WHITE,
        elevation: ELEVATION_LOW,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        iconTheme: const IconThemeData(color: COLOR_PRIMARY),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: COLOR_TEXT_PRIMARY,
        ),
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: COLOR_WHITE,
        selectedItemColor: COLOR_PRIMARY,
        unselectedItemColor: COLOR_TEXT_SECONDARY,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: ELEVATION_MEDIUM,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: COLOR_PRIMARY,
          foregroundColor: COLOR_WHITE,
          elevation: ELEVATION_LOW,
          shadowColor: COLOR_PRIMARY.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: SPACING_MD,
            horizontal: SPACING_LG,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: COLOR_PRIMARY,
          side: const BorderSide(color: COLOR_PRIMARY, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: SPACING_MD,
            horizontal: SPACING_LG,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: COLOR_PRIMARY,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: SPACING_SM,
            horizontal: SPACING_MD,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: COLOR_WHITE,
        elevation: ELEVATION_LOW,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: SPACING_XS,
          horizontal: SPACING_SM,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: COLOR_WHITE,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide:
              BorderSide(color: COLOR_TEXT_SECONDARY.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide:
              BorderSide(color: COLOR_TEXT_SECONDARY.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide: const BorderSide(color: COLOR_PRIMARY, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide: const BorderSide(color: COLOR_ERROR, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: SPACING_MD,
          horizontal: SPACING_MD,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: COLOR_TEXT_SECONDARY),
        hintStyle: textTheme.bodyMedium?.copyWith(color: COLOR_TEXT_SECONDARY),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: COLOR_WHITE,
        elevation: ELEVATION_HIGH,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(BORDER_RADIUS_LARGE),
            bottomRight: Radius.circular(BORDER_RADIUS_LARGE),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SPACING_MD,
          vertical: SPACING_XS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_SMALL),
        ),
        iconColor: COLOR_TEXT_SECONDARY,
        textColor: COLOR_TEXT_PRIMARY,
      ),
      dividerTheme: DividerThemeData(
        color: COLOR_TEXT_SECONDARY.withValues(alpha: 0.2),
        thickness: 1,
        space: SPACING_MD,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: COLOR_BACKGROUND,
        selectedColor: COLOR_PRIMARY.withValues(alpha: 0.2),
        labelStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_XL),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SPACING_SM,
          vertical: SPACING_XS,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.cairoTextTheme(baseTheme.textTheme).apply(
      bodyColor: const Color(0xFFE0E0E0),
      displayColor: const Color(0xFFE0E0E0),
    );

    return baseTheme.copyWith(
      primaryColor: COLOR_PRIMARY,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: COLOR_PRIMARY,
        secondary: COLOR_ACCENT,
        tertiary: COLOR_INFO,
        surface: Color(0xFF1E1E1E),
        onPrimary: COLOR_WHITE,
        onSecondary: const Color(0xFFE0E0E0),
        onTertiary: COLOR_WHITE,
        onSurface: const Color(0xFFE0E0E0),
        error: COLOR_ERROR,
        onError: COLOR_WHITE,
        brightness: Brightness.dark,
        outline: const Color(0xFF424242),
        surfaceContainerHighest: const Color(0xFF212121),
        onSurfaceVariant: const Color(0xFFBDBDBD),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: ELEVATION_LOW,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        iconTheme: const IconThemeData(color: COLOR_ACCENT),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE0E0E0),
        ),
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: COLOR_ACCENT,
        unselectedItemColor: const Color(0xFF757575),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: ELEVATION_MEDIUM,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodySmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: COLOR_PRIMARY,
          foregroundColor: COLOR_WHITE,
          elevation: ELEVATION_LOW,
          shadowColor: COLOR_PRIMARY.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: SPACING_MD,
            horizontal: SPACING_LG,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: COLOR_ACCENT,
          side: const BorderSide(color: COLOR_ACCENT, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: SPACING_MD,
            horizontal: SPACING_LG,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: COLOR_ACCENT,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: SPACING_SM,
            horizontal: SPACING_MD,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: ELEVATION_LOW,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: SPACING_XS,
          horizontal: SPACING_SM,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide: const BorderSide(color: COLOR_ACCENT, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
          borderSide: const BorderSide(color: COLOR_ERROR, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: SPACING_MD,
          horizontal: SPACING_MD,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFFBDBDBD)),
        hintStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFFBDBDBD)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: ELEVATION_HIGH,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(BORDER_RADIUS_LARGE),
            bottomRight: Radius.circular(BORDER_RADIUS_LARGE),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SPACING_MD,
          vertical: SPACING_XS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_SMALL),
        ),
        iconColor: const Color(0xFFBDBDBD),
        textColor: const Color(0xFFE0E0E0),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF424242),
        thickness: 1,
        space: SPACING_MD,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedColor: COLOR_PRIMARY.withValues(alpha: 0.4),
        labelStyle: textTheme.bodySmall?.copyWith(color: const Color(0xFFE0E0E0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_XL),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SPACING_SM,
          vertical: SPACING_XS,
        ),
      ),
    );
  }

  // Helper method to get role-specific color
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'donor':
        return COLOR_DONOR_ACCENT;
      case 'volunteer':
        return COLOR_VOLUNTEER_ACCENT;
      case 'association':
        return COLOR_ASSOCIATION_ACCENT;
      case 'manager':
        return COLOR_MANAGER_ACCENT;
      default:
        return COLOR_PRIMARY;
    }
  }

  // Helper method to create consistent shadows
  static List<BoxShadow> getElevationShadow(double elevation) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }

  // Helper method for consistent gradients
  static LinearGradient getPrimaryGradient() {
    return LinearGradient(
      colors: [
        COLOR_PRIMARY,
        COLOR_PRIMARY.withValues(alpha: 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// مكونات مشتركة للثيم
class ThemeComponents {
  // بطاقة إحصائيات موحدة
  static Widget buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cardColor = color ?? COLOR_PRIMARY;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        child: Padding(
          padding: const EdgeInsets.all(SPACING_MD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: cardColor.withValues(alpha: 0.1),
                radius: 24,
                child: Icon(icon, color: cardColor, size: 24),
              ),
              const SizedBox(height: SPACING_SM),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: COLOR_TEXT_SECONDARY,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // عنوان قسم موحد
  static Widget buildSectionTitle({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_SM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: SPACING_XS),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: COLOR_TEXT_SECONDARY,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // بطاقة عنصر قائمة موحدة
  static Widget buildListCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? accentColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SPACING_MD,
        vertical: SPACING_XS,
      ),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BORDER_RADIUS_MEDIUM),
        ),
      ),
    );
  }

  // شريط تطبيق موحد
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    Color? backgroundColor,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor,
    );
  }

  // زر عائم موحد
  static Widget buildFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
    Color? backgroundColor,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? COLOR_PRIMARY,
      child: Icon(icon, color: COLOR_WHITE),
    );
  }
}
