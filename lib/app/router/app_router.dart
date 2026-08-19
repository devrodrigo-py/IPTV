import 'package:go_router/go_router.dart';
import 'package:nebula_iptv/features/shell/shell_screen.dart';

/// Application route paths.
abstract final class AppRoutes {
  static const home = '/';
}

/// GoRouter configuration for the application.
///
/// The ShellScreen handles internal navigation between sections.
/// GoRouter is used for top-level routing and deep linking.
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const ShellScreen(),
    ),
  ],
);
