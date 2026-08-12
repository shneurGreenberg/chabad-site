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

GoRoute _route(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      child: child,
    ),
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return SiteShell(
          currentRoute: state.uri.path,
          child: child,
        );
      },
      routes: [
        _route('/', const HomePage()),
        _route('/news', const NewsPage()),
        _route('/zmanim', const ZmanimPage()),
        _route('/programs', const ProgramsPage()),
        _route('/gallery', const GalleryPage()),
        _route('/cemetery', const CemeteryPage()),
        _route('/famous', const FamousPage()),
        _route('/history', const HistoryPage()),
        _route('/store', const StorePage()),
        _route('/library', const LibraryPage()),
        _route('/donate', const DonatePage()),
        _route('/contact', const ContactPage()),
        _route('/about', const AboutPage()),
      ],
    ),
    _route('/admin', const AdminPage()),
  ],
);
