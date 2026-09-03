/// Simple static callback untuk navigasi antar tab dari mana saja
/// tanpa menyebabkan circular import.
///
/// Cara pakai:
/// 1. Di MainNavigationPage.initState(), set:
///    NavigationTabSwitcher.switchTab = (i) => _onTabTap(i);
/// 2. Di halaman lain, panggil:
///    NavigationTabSwitcher.switchTab?.call(1);
class NavigationTabSwitcher {
  NavigationTabSwitcher._();

  static void Function(int tabIndex)? switchTab;
}
