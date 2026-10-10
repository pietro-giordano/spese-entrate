import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/enums.dart';
import '../../features/analytics/presentation/charts_screen.dart';
import '../../features/analytics/presentation/compare_screen.dart';
import '../../features/recurring/presentation/recurrence_detail_screen.dart';
import '../../features/recurring/presentation/recurring_list_screen.dart';
import '../../features/settings/presentation/backup_screen.dart';
import '../../features/settings/presentation/categories_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/filters_screen.dart';
import '../../features/transactions/presentation/quick_add_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/wallets/presentation/wallet_detail_screen.dart';
import '../../features/wallets/presentation/wallet_form_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';
import '../widgets/component_catalog_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

part 'app_router.g.dart';

/// Router dell'app. È un provider così in futuro potrà leggere altro stato
/// (es. il blocco biometrico) per i redirect, e ogni test ne ottiene uno nuovo.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Navigatore principale: le schermate qui sopra coprono anche la barra dei tab.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.transactions,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.transactions, builder: (context, state) => const TransactionsScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wallets,
                builder: (context, state) => const WalletsScreen(),
                routes: [
                  // 'new' prima di ':id', altrimenti "new" verrebbe letto come un id.
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const WalletFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => WalletDetailScreen(walletId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => WalletFormScreen(walletId: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.charts, builder: (context, state) => const ChartsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.compare, builder: (context, state) => const CompareScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        pageBuilder: (context, state) => _slideUpPage(
          state,
          QuickAddScreen(
            // Per ora solo spese ed entrate: il trasferimento arriverà in un passo successivo.
            type: state.uri.queryParameters['type'] == 'income' ? TransactionType.income : TransactionType.expense,
          ),
        ),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) => TransactionDetailScreen(transactionId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.filters, builder: (context, state) => const FiltersScreen()),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'categories', builder: (context, state) => const CategoriesScreen()),
          GoRoute(
            path: 'recurring',
            builder: (context, state) => const RecurringListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => RecurrenceDetailScreen(recurrenceId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: 'backup', builder: (context, state) => const BackupScreen()),
        ],
      ),
      if (kDebugMode)
        GoRoute(path: AppRoutes.componentCatalog, builder: (context, state) => const ComponentCatalogScreen()),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
}

/// Pagina modale a schermo intero che entra dal basso (uguale su iOS e Android).
CustomTransitionPage<void> _slideUpPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    fullscreenDialog: true,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}
