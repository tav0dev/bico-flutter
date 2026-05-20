import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  // Novo método para buscar eventos usando o token vindo do Supabase
  Future<List<Event>> getEventsWithToken(String accessToken) async {
    final client = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken('Bearer', accessToken, DateTime.now().add(const Duration(hours: 1)).toUtc()),
        null, // No refresh token needed as Supabase handles session
        [
          CalendarApi.calendarEventsReadonlyScope,
          CalendarApi.calendarReadonlyScope,
        ],
      ),
    );

    final calendarApi = CalendarApi(client);
    final now = DateTime.now();
    final startSearch = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

    List<Event> allEvents = [];
    try {
      final calendarList = await calendarApi.calendarList.list();
      if (calendarList.items != null) {
        for (var cal in calendarList.items!) {
          final events = await calendarApi.events.list(
            cal.id!,
            timeMin: startSearch.toUtc(),
            maxResults: 50,
            singleEvents: true,
          );
          if (events.items != null) allEvents.addAll(events.items!);
        }
      }
    } catch (e) {
      print('Bico: Erro ao listar agendas no Supabase Flow: $e');
      final events = await calendarApi.events.list('primary', timeMin: startSearch.toUtc(), maxResults: 50, singleEvents: true);
      allEvents = events.items ?? [];
    }

    return allEvents;
  }
}
