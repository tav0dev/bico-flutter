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
  bool _isCheckingProfile = true;
  bool get isCheckingProfile => _isCheckingProfile;

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
      await _handleSession(data.session);
    });
    _handleSession(Supabase.instance.client.auth.currentSession);
  }

  Future<void> _handleSession(Session? session) async {
    if (session != null) {
      _isCheckingProfile = true;
      notifyListeners();
      await _checkProfile(session.user);
      fetchGoogleEvents();
    } else {
      googleEvents = [];
      prestador = null;
      _needsOnboarding = false;
      _isCheckingProfile = false;
      notifyListeners();
    }
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
      _isCheckingProfile = false;
      notifyListeners();
    } catch (e) {
      print('Erro ao checar perfil: $e');
      prestador = null;
      _needsOnboarding = false;
      _isCheckingProfile = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding({
    required String nomeCompleto,
    required String telefone,
    required String categoria,
    required String cidade,
    required String estado,
    String? bio,
    List<Map<String, dynamic>> initialServices = const [],
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final email = user.email ?? 'sem_email@bico.com';
      final slugBase = _slugify(
        nomeCompleto.isNotEmpty ? nomeCompleto : email.split('@').first,
      );
      final existing = await Supabase.instance.client
          .from('prestadores')
          .select('id, slug')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      final dados = {
        'auth_user_id': user.id,
        'email': email,
        'telefone': telefone,
        'nome_completo': nomeCompleto,
        'slug':
            existing?['slug'] ??
            '$slugBase-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'categoria': categoria,
        'bio': bio?.trim().isEmpty == true ? null : bio?.trim(),
        'cidade': cidade,
        'estado': estado,
        'foto_perfil_url': user.userMetadata?['avatar_url'],
      };

      if (existing != null) {
        prestador = await Supabase.instance.client
            .from('prestadores')
            .update(dados)
            .eq('auth_user_id', user.id)
            .select()
            .single();
      } else {
        prestador = await Supabase.instance.client
            .from('prestadores')
            .insert(dados)
            .select()
            .single();
      }

      final prestadorId = prestador?['id'];
      if (prestadorId != null &&
          initialServices.isNotEmpty &&
          existing == null) {
        final serviceRows = initialServices.asMap().entries.map((entry) {
          final service = entry.value;
          return {
            'prestador_id': prestadorId,
            'nome': service['nome'],
            'duracao_minutos': service['duracao_minutos'] ?? 60,
            'preco_centavos': service['preco_centavos'] ?? 0,
            'ativo': service['ativo'] ?? true,
            'ordem': entry.key,
          };
        }).toList();

        await Supabase.instance.client.from('servicos').insert(serviceRows);
      }

      _needsOnboarding = false;
      _isCheckingProfile = false;
      notifyListeners();
    } catch (e) {
      print('Erro ao completar onboarding: $e');
      rethrow;
    }
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  bool get isAuthenticated =>
      Supabase.instance.client.auth.currentSession != null;
  bool get isGoogleLoggedIn => isAuthenticated;
  bool get hasGoogleCalendarToken =>
      Supabase.instance.client.auth.currentSession?.providerToken != null;

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

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
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
        scopes:
            'openid email profile https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/calendar.events.readonly',
        queryParams: {'prompt': 'consent'},
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
      googleEvents = await _calendarService.getEventsWithToken(
        session.providerToken!,
      );
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
