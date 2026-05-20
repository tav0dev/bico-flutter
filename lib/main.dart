import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/bicco_provider.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'screens/inbox_thread_screen.dart';
import 'screens/services_screen.dart';
import 'screens/create_post_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qcvwgsdhwihfaxkvdmur.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjdndnc2Rod2loZmF4a3ZkbXVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2Nzg5MTUsImV4cCI6MjA5NDI1NDkxNX0.yExEjPAnG21MitpejIkfHSdec_rQc8FTnQue6-BQNAY',
  );

  initializeDateFormatting('pt_BR', null).then((_) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    runApp(
      ChangeNotifierProvider(
        create: (_) => BiccoNotifier(),
        child: const BiccoApp(),
      ),
    );
  });
}

class BiccoApp extends StatelessWidget {
  const BiccoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BiccoNotifier>();
    final tokens = notifier.tokens;

    return MaterialApp(
      title: 'Bicco',
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
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/main': (_) => const MainShell(),
        '/inbox-thread': (_) => const InboxThreadScreen(),
        '/services': (_) => const ServicesScreen(),
        '/create-post': (_) => const CreatePostScreen(),
      },
    );
    .
  }
}
