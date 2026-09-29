import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Komponen AppBar Universal yang konsisten di seluruh halaman aplikasi,
/// menyelaraskan gaya dengan halaman detail perangkat (SensorDetailPage).
class UniversalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBackPressed;

  const UniversalAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.foregroundColor = Colors.black,
    this.elevation = 0,
    this.bottom,
    this.onBackPressed,
  }) : assert(title != null || titleWidget != null, 'title atau titleWidget harus disediakan');

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading && Navigator.canPop(context)) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: foregroundColor,
        tooltip: 'Kembali',
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      );
    }

    return AppBar(
      title: titleWidget ??
          Text(
            title ?? '',
            style: GoogleFonts.inter(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
      leading: leadingWidget,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      iconTheme: IconThemeData(color: foregroundColor),
      actions: actions,
      bottom: bottom,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
