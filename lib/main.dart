import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/storage_service.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/blog_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/blog_repository.dart';
import 'notifiers/auth_notifier.dart';
import 'notifiers/blog_notifier.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/blog/feed_screen.dart';

// Supabase configuration
const String supabaseUrl =
    'http://study-supabase-20c378-167-88-45-173.traefik.me';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NzA5NTA3ODgsImV4cCI6MTg5MzQ1NjAwMCwicm9sZSI6ImFub24iLCJpc3MiOiJzdXBhYmFzZSJ9.xbUmbbWt1CBMd2JpnkL24A54Sa25OgRCjkcsB-odlh4';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  final supabaseClient = Supabase.instance.client;

  // Pre-create services and repositories
  final authService = AuthService(supabaseClient);
  final blogService = BlogService(supabaseClient);
  final storageService = StorageService(supabaseClient);

  final authRepo = AuthRepository(authService, storageService);
  final blogRepo = BlogRepository(blogService);

  // Create and initialize AuthNotifier before runApp so routing can read state
  final authNotifier = AuthNotifier(authRepo);
  await authNotifier.initialize();

  runApp(
    MyApp.withDependencies(
      authService: authService,
      blogService: blogService,
      storageService: storageService,
      authRepository: authRepo,
      blogRepository: blogRepo,
      authNotifier: authNotifier,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final BlogService blogService;
  final StorageService storageService;
  final AuthRepository authRepository;
  final BlogRepository blogRepository;
  final AuthNotifier authNotifier;

  const MyApp.withDependencies({
    required this.authService,
    required this.blogService,
    required this.storageService,
    required this.authRepository,
    required this.blogRepository,
    required this.authNotifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      initialLocation: '/',
      refreshListenable: authNotifier,
      redirect: (context, state) {
        final loggedIn = authNotifier.isLoggedIn;
        final atLogin =
            state.location == '/login' || state.location == '/register';

        if (!loggedIn) {
          if (!atLogin) return '/login';
          return null;
        }

        // logged in
        if (loggedIn) {
          if (atLogin || state.location == '/') return '/splash';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (ctx, state) => const SizedBox.shrink()),
        GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (ctx, state) => const RegisterScreen(),
        ),
        GoRoute(path: '/feed', builder: (ctx, state) => const FeedScreen()),
        GoRoute(
          path: '/profile',
          builder: (ctx, state) => const ProfileScreen(),
        ),
        GoRoute(path: '/post/:id', builder: (ctx, state) => const FeedScreen()),
      ],
    );

    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>.value(value: authService),
        Provider<BlogService>.value(value: blogService),
        Provider<StorageService>.value(value: storageService),

        // Repositories via ProxyProviders so they can react if services change
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, authSvc, __) => AuthRepository(authSvc, storageService),
        ),
        ProxyProvider<BlogService, BlogRepository>(
          update: (_, blogSvc, __) => BlogRepository(blogSvc),
        ),

        // Notifiers
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        ChangeNotifierProvider<BlogNotifier>(
          create: (ctx) => BlogNotifier(ctx.read<BlogRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Agents App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
