import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:googleapis/calendar/v3.dart' as google;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/tokens.dart';
import '../services/google_calendar_service.dart';

class BiccoNotifier extends ChangeNotifier {
  bool isDark;
  String accent;
  String density;
  String navStyle;
  String cardStyle;
  String tucoMode;

  final GoogleCalendarService _calendarService = GoogleCalendarService();
  List<google.Event> googleEvents = [];
  bool isLoadingEvents = false;
  String? errorMessage;

  BiccoNotifier({
    this.isDark = true,
    this.accent = 'green',
    this.density = 'comfortable',
    this.navStyle = 'icons-labels',
    this.cardStyle = 'soft',
    this.tucoMode = 'placeholder',
  }) {
    // Escutar mudanças de autenticação do Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchGoogleEvents();
      } else {
        googleEvents = [];
        notifyListeners();
      }
    });
  }

  BiccoTokens get tokens {
    final base = isDark ? BiccoTokens.dark : BiccoTokens.light;
    if (accent == 'purple') {
      return base.copyWith(
        green: base.purple,
        greenDark: const Color(0xFF3730A3),
        greenSoft: base.purpleSoft,
        purple: base.green,
        purpleSoft: base.greenSoft,
      );
    }
    return base;
  }

  bool get isGoogleLoggedIn => Supabase.instance.client.auth.currentSession != null;

  Future<void> signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.bico-flutter://login-callback',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
        scopes: 'https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/calendar.readonly',
      );
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> fetchGoogleEvents() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.providerToken == null) {
      print('Bicco: Sem sessão ou providerToken do Supabase.');
      return false;
    }

    isLoadingEvents = true;
    errorMessage = null;
    notifyListeners();
    try {
      googleEvents = await _calendarService.getEventsWithToken(session.providerToken!);
      if (googleEvents.isEmpty) {
        print('Bicco: Nenhum evento retornado do Google.');
      }
      return googleEvents.isNotEmpty;
    } catch (e) {
      errorMessage = e.toString();
      print('Erro ao carregar eventos: $e');
      return false;
    } finally {
      isLoadingEvents = false;
      notifyListeners();
    }
  }

  Future<void> logoutGoogle() async {
    await Supabase.instance.client.auth.signOut();
    googleEvents = [];
    notifyListeners();
  }

  void setDark(bool v) {
    isDark = v;
    notifyListeners();
  }
  void setAccent(String v) {
    accent = v;
    notifyListeners();
  }
}
