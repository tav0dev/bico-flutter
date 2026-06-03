import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agendamento.dart';

class AgendamentosProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Agendamento> _agendamentos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Agendamento> get agendamentos => _agendamentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AgendamentosProvider() {
    if (_supabase.auth.currentSession != null) {
      loadAgendamentos();
    }
  }

  Future<void> loadAgendamentos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startRange = DateTime(now.year, 1, 1);
      final endRange = DateTime(now.year + 1, 1, 1);

      // Fazemos o fetch já puxando o nome do cliente e do serviço via foreign key
      final response = await _supabase
          .from('agendamentos')
          .select('*, clientes(nome), servicos(nome)')
          .gte('inicio', startRange.toUtc().toIso8601String())
          .lt('inicio', endRange.toUtc().toIso8601String())
          .order('inicio', ascending: true);

      _agendamentos = (response as List)
          .map((data) => Agendamento.fromJson(data))
          .toList();
    } catch (e) {
      _errorMessage = 'Erro ao carregar agendamentos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAgendamento(Agendamento agendamento) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final prestadorRes = await _supabase
          .from('prestadores')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();

      final prestadorId = prestadorRes['id'];

      final dados = agendamento.toJson();
      dados['prestador_id'] = prestadorId;

      await _supabase.from('agendamentos').insert(dados);
      await loadAgendamentos();
      return true;
    } catch (e) {
      print('Erro ao criar agendamento: $e');
      rethrow;
    }
  }

  Future<bool> updateAgendamento(Agendamento agendamento) async {
    if (agendamento.id.isEmpty) return false;

    try {
      final dados = agendamento.toJson();
      dados.remove('id');

      await _supabase
          .from('agendamentos')
          .update(dados)
          .eq('id', agendamento.id);

      await loadAgendamentos();
      return true;
    } catch (e) {
      print('Erro ao atualizar agendamento: $e');
      rethrow;
    }
  }

  Future<bool> deleteAgendamento(String id) async {
    try {
      await _supabase.from('agendamentos').delete().eq('id', id);

      _agendamentos.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao deletar agendamento: $e');
      rethrow;
    }
  }

  Future<bool> updateStatus(String id, String novoStatus) async {
    try {
      await _supabase
          .from('agendamentos')
          .update({'status': novoStatus})
          .eq('id', id);

      final index = _agendamentos.indexWhere((a) => a.id == id);
      if (index != -1) {
        // Criar uma cópia mutável
        final a = _agendamentos[index];
        _agendamentos[index] = Agendamento(
          id: a.id,
          prestadorId: a.prestadorId,
          clienteId: a.clienteId,
          servicoId: a.servicoId,
          dataHoraInicio: a.dataHoraInicio,
          dataHoraFim: a.dataHoraFim,
          status: novoStatus,
          precoCobradoCentavos: a.precoCobradoCentavos,
          clienteNome: a.clienteNome,
          servicoNome: a.servicoNome,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Erro ao atualizar status do agendamento: $e');
      rethrow;
    }
  }

  // Pegar o próximo agendamento válido
  Agendamento? get nextAgendamento {
    final now = DateTime.now();
    try {
      return _agendamentos.firstWhere(
        (a) =>
            (a.status == 'pendente' || a.status == 'confirmado') &&
            a.dataHoraFim.isAfter(now),
      );
    } catch (e) {
      return null;
    }
  }

  // Agendamentos de hoje
  List<Agendamento> get agendamentosHoje {
    final now = DateTime.now();
    return _agendamentos
        .where(
          (a) =>
              a.dataHoraInicio.year == now.year &&
              a.dataHoraInicio.month == now.month &&
              a.dataHoraInicio.day == now.day &&
              a.status != 'cancelado',
        )
        .toList();
  }
}
