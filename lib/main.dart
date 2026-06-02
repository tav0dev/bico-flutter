import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/bico_provider.dart';
import 'providers/servicos_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/agendamentos_provider.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'screens/inbox_thread_screen.dart';
import 'screens/services_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wzychmshebmznjfducug.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6eWNobXNoZWJtem5qZmR1Y3VnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzOTkxNTksImV4cCI6MjA5NDk3NTE1OX0.MWz4GjhNuElOqLq27SfUfmlnNjAy8H78UDkICN_5rZw',
  );

  initializeDateFormatting('pt_BR', null).then((_) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BicoNotifier()),
          ChangeNotifierProvider(create: (_) => ServicosProvider()),
          ChangeNotifierProvider(create: (_) => ClientesProvider()),
          ChangeNotifierProvider(create: (_) => AgendamentosProvider()),
        ],
        child: const BicoApp(),
      ),
    );
  });
}

class BicoApp extends StatelessWidget {
  const BicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BicoNotifier>();
    final tokens = notifier.tokens;

    return MaterialApp(
      title: 'Bico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: notifier.isDark ? Brightness.dark : Brightness.light,
          primary: tokens.green,
          onPrimary: Colors.white,
          secondary: tokens.purple,
          onSecondary: Colors.white,
          error: tokens.red,
          onError: Colors.white,
          surface: tokens.bg,
          onSurface: tokens.text,
        ),
        scaffoldBackgroundColor: tokens.bg,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: notifier.isDark ? Brightness.dark : Brightness.light).textTheme,
        ).apply(
          bodyColor: tokens.text,
          displayColor: tokens.text,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: tokens.bg,
          foregroundColor: tokens.text,
          elevation: 0,
        ),
      ),
      home: notifier.isAuthenticated 
          ? (notifier.needsOnboarding ? const OnboardingScreen() : const MainShell())
          : const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/main': (_) => const MainShell(),
        '/inbox-thread': (_) => const InboxThreadScreen(),
        '/services': (_) => const ServicesScreen(),
        '/create-post': (_) => const CreatePostScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
