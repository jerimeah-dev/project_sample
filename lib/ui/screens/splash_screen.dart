import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../notifiers/blog_notifier.dart';
import '../../notifiers/auth_notifier.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startInit();
      });
    }
  }

  Future<void> _startInit() async {
    final auth = context.read<AuthNotifier>();
    final blog = context.read<BlogNotifier>();

    // If not logged in, send to login
    if (!auth.isLoggedIn) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      await blog.loadPosts();
      if (mounted) context.go('/feed');
    } catch (_) {
      if (mounted) context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
