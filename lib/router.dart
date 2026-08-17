import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/admin/admin.dart';
import 'pages/client/about_page.dart';
import 'pages/client/cemetery_page.dart';
import 'pages/client/contact_page.dart';
import 'pages/client/donate_page.dart';
import 'pages/client/famous_page.dart';
import 'pages/client/gallery_page.dart';
import 'pages/client/history_page.dart';
import 'pages/client/home_page.dart';
import 'pages/client/library_page.dart';
import 'pages/client/news_page.dart';
import 'pages/client/programs_page.dart';
import 'pages/client/store_page.dart';
import 'pages/client/zmanim_page.dart';
import 'widgets/site_scaffold.dart';

GoRoute _route(String path, Widget Function(GoRouterState state) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      child: builder(state),
    ),
  );
}

String? _h(GoRouterState state) => state.uri.queryParameters['h'];

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final path = state.uri.path;
        return SiteShell(
          currentRoute: path,
          child: child,
        );
      },
      routes: [
        _route('/', (_) => const HomePage()),
        _route('/news', (s) => NewsPage(highlightId: _h(s))),
        GoRoute(
          path: '/news/:id',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: NewsArticlePage(id: state.pathParameters['id'] ?? ''),
          ),
        ),
        _route('/zmanim', (_) => const ZmanimPage()),
        _route('/programs', (s) => ProgramsPage(highlightId: _h(s))),
        GoRoute(
          path: '/programs/:id',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: ProgramDetailPage(id: state.pathParameters['id'] ?? ''),
          ),
        ),
        _route('/gallery', (_) => const GalleryPage()),
        GoRoute(
          path: '/gallery/:id',
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: GalleryAlbumPage(id: state.pathParameters['id'] ?? ''),
          ),
        ),
        _route('/cemetery', (s) => CemeteryPage(highlightId: _h(s))),
        _route('/famous', (s) => FamousPage(highlightId: _h(s))),
        _route('/history', (_) => const HistoryPage()),
        _route('/store', (s) => StorePage(highlightId: _h(s))),
        _route('/library', (s) => LibraryPage(highlightId: _h(s))),
        _route('/donate', (_) => const DonatePage()),
        _route('/contact', (s) => ContactPage(
              programId: s.uri.queryParameters['p'],
            )),
        _route('/about', (_) => const AboutPage()),
      ],
    ),
    _route('/admin', (_) => const AdminPage()),
  ],
);
