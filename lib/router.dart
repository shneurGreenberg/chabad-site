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
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(path: '/news', builder: (context, state) => const NewsPage()),
        GoRoute(path: '/zmanim', builder: (context, state) => const ZmanimPage()),
        GoRoute(
            path: '/programs',
            builder: (context, state) => const ProgramsPage()),
        GoRoute(
            path: '/gallery', builder: (context, state) => const GalleryPage()),
        GoRoute(
            path: '/cemetery',
            builder: (context, state) => const CemeteryPage()),
        GoRoute(path: '/famous', builder: (context, state) => const FamousPage()),
        GoRoute(
            path: '/history', builder: (context, state) => const HistoryPage()),
        GoRoute(path: '/store', builder: (context, state) => const StorePage()),
        GoRoute(
            path: '/library', builder: (context, state) => const LibraryPage()),
        GoRoute(path: '/donate', builder: (context, state) => const DonatePage()),
        GoRoute(
            path: '/contact', builder: (context, state) => const ContactPage()),
        GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      ],
    ),
    GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
  ],
);
