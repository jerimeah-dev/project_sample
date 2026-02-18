// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_sample/main.dart';
import 'package:project_sample/ui/screens/auth/login_screen.dart';
import 'package:project_sample/services/auth_service.dart';
import 'package:project_sample/services/blog_service.dart';
import 'package:project_sample/services/storage_service.dart';
import 'package:project_sample/repositories/auth_repository.dart';
import 'package:project_sample/repositories/blog_repository.dart';
import 'package:project_sample/notifiers/auth_notifier.dart';

void main() {
  testWidgets('App builds and shows LoginScreen', (WidgetTester tester) async {
    // Initialize Supabase with a dummy client for tests.
    await Supabase.initialize(
      url: 'http://127.0.0.1',
      anonKey: 'test-anon-key',
    );

    // Build our app and trigger a frame.
    final supabaseClient = Supabase.instance.client;
    final authService = AuthService(supabaseClient);
    final blogService = BlogService(supabaseClient);
    final storageService = StorageService(supabaseClient);

    final authRepo = AuthRepository(authService, storageService);
    final blogRepo = BlogRepository(blogService);

    final authNotifier = AuthNotifier(authRepo);
    await authNotifier.initialize();

    await tester.pumpWidget(
      MyApp.withDependencies(
        authService: authService,
        blogService: blogService,
        storageService: storageService,
        authRepository: authRepo,
        blogRepository: blogRepo,
        authNotifier: authNotifier,
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the LoginScreen is shown by default.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
