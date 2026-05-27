import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servico.dart';

class ServicosProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<Servico> _servicos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Servico> get servicos => _servicos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadServicos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('servicos')
          .select()
          .isFilter('deleted_at', null)
          .order('ordem', ascending: true);
          
      _servicos = (response as List).map((data) => Servico.fromJson(data)).toList();
    } catch (e) {
      _errorMessage = 'Erro ao carregar serviços: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addServico(Servico servico) async {
    try {
      // PrestadorId é definido automaticamente na trigger/policy se omitirmos,
      // mas precisamos buscá-lo se a policy exigir exatidão ou passar vazio se o RLS permitir.
      // O Supabase não insere auth.uid() automaticamente se a coluna for diferente, precisamos do prestador_id.
      // Vamos buscar o prestador_id primeiro.
      final prestadorRes = await _supabase
          .from('prestadores')
          .select('id')
          .eq('auth_user_id', _supabase.auth.currentUser!.id)
          .single();
          
      final data = servico.toJson();
      data.remove('id'); // Remove id to let DB generate
      data['prestador_id'] = prestadorRes['id'];

      final response = await _supabase.from('servicos').insert(data).select().single();
      _servicos.add(Servico.fromJson(response));
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao adicionar serviço: $e');
      rethrow;
    }
  }

  Future<bool> toggleAtivo(String id, bool currentStatus) async {
    try {
      final response = await _supabase
          .from('servicos')
          .update({'ativo': !currentStatus})
          .eq('id', id)
          .select()
          .single();
          
      final index = _servicos.indexWhere((s) => s.id == id);
      if (index != -1) {
        _servicos[index] = Servico.fromJson(response);
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Erro ao atualizar serviço: $e');
      rethrow;
    }
  }

  Future<bool> deleteServico(String id) async {
    try {
      await _supabase
          .from('servicos')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
          
      _servicos.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao deletar serviço: $e');
      rethrow;
    }
  }
}
