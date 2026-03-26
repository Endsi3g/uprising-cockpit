import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cockpit/cockpit_screen.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/lead_detail/lead_detail_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/clients/clients_screen.dart';
import '../../features/clients/client_detail_screen.dart';
import '../../features/ai_chat/ai_chat_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/invoices/invoices_screen.dart';
import '../../features/shared/screens/error_404_screen.dart';
import '../../features/shared/screens/under_maintenance_screen.dart';
import '../../features/shared/screens/welcome_screen.dart';
import 'shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const Error404Screen(),
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _noTransitionPage(
              state, const CockpitScreen(),
            ),
          ),
          GoRoute(
            path: '/jobs',
            pageBuilder: (context, state) => _noTransitionPage(
              state, const JobsScreen(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => _noTransitionPage(
              state, const CalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => _noTransitionPage(
              state, const StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/clients',
            pageBuilder: (context, state) => _noTransitionPage(
              state, const ClientsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const UnderMaintenanceScreen(),
      ),
      // Full-screen routes (outside shell)
      GoRoute(
        path: '/leads/:id',
        builder: (context, state) =>
            LeadDetailScreen(leadId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) =>
            ClientDetailScreen(clientId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ai',
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoicesScreen(),
      ),
    ],
  );
});

CustomTransitionPage _noTransitionPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, c) => c,
  );
}
