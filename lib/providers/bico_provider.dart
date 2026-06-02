import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as google;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/tokens.dart';
import '../services/google_calendar_service.dart';

class BicoNotifier extends ChangeNotifier {
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

  bool _needsOnboarding = false;
  bool get needsOnboarding => _needsOnboarding;

  Map<String, dynamic>? prestador;

  BicoNotifier({
    this.isDark = true,
    this.accent = 'green',
    this.density = 'comfortable',
    this.navStyle = 'icons-labels',
    this.cardStyle = 'soft',
    this.tucoMode = 'placeholder',
  }) {
    // Escuta mudanças de autenticação (Login/Logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await _checkProfile(data.session!.user);
        fetchGoogleEvents();
      } else {
        googleEvents = [];
        _needsOnboarding = false;
        notifyListeners();
      }
    });
  }

  Future<void> _checkProfile(User user) async {
    try {
      final supabase = Supabase.instance.client;
      final existing = await supabase
          .from('prestadores')
          .select('*')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        prestador = existing;
        _needsOnboarding = false;
      } else {
        prestador = null;
        _needsOnboarding = true;
      }
      notifyListeners();
    } catch (e) {
      print('Erro ao checar perfil: $e');
      prestador = null;
      _needsOnboarding = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding(String categoria) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final email = user.email ?? 'sem_email@bico.com';
      final fallbackName = email.split('@').first;
      final uniqueSlug = '$fallbackName-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      await Supabase.instance.client.from('prestadores').insert({
        'auth_user_id': user.id,
        'email': email,
        'telefone': null,
        'nome_completo': user.userMetadata?['full_name'] ?? fallbackName,
        'slug': uniqueSlug,
        'categoria': categoria,
        'cidade': null,
        'estado': null,
        'foto_perfil_url': user.userMetadata?['avatar_url'],
      });
      
      _needsOnboarding = false;
      notifyListeners();
    } catch (e) {
      print('Erro ao completar onboarding: $e');
      rethrow;
    }
  }

  bool get isAuthenticated => Supabase.instance.client.auth.currentSession != null;
  bool get isGoogleLoggedIn => isAuthenticated;

  BicoTokens get tokens {
    final base = isDark ? BicoTokens.dark : BicoTokens.light;
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

  Future<AuthResponse> signUpWithEmail(String email, String password, {String? fullName}) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.example.bico_flutter://login-callback',
      );
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'com.example.bico_flutter://login-callback',
      );
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> fetchGoogleEvents() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.providerToken == null) {
      print('Bico: Sem sessão ou providerToken do Supabase.');
      return false;
    }

    isLoadingEvents = true;
    errorMessage = null;
    notifyListeners();
    try {
      googleEvents = await _calendarService.getEventsWithToken(session.providerToken!);
      if (googleEvents.isEmpty) {
        print('Bico: Nenhum evento retornado do Google.');
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
