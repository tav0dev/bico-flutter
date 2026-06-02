import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente.dart';

class ClientesProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ClientesProvider() {
    // Carrega clientes automaticamente quando o Provider é instanciado (se houver sessão)
    if (_supabase.auth.currentSession != null) {
      loadClientes();
    }
  }

  Future<void> loadClientes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('clientes')
          .select()
          .isFilter('deleted_at', null)
          .order('nome', ascending: true);
          
      _clientes = (response as List).map((data) => Cliente.fromJson(data)).toList();
    } catch (e) {
      _errorMessage = 'Erro ao carregar clientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCliente(Cliente cliente) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Buscar o ID do prestador correspondente ao usuário logado
      final prestadorRes = await _supabase
          .from('prestadores')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();
          
      final prestadorId = prestadorRes['id'];
      
      final dados = cliente.toJson();
      dados['prestador_id'] = prestadorId;

      await _supabase.from('clientes').insert(dados);
      await loadClientes();
      return true;
    } catch (e) {
      print('Erro ao adicionar cliente: $e');
      rethrow;
    }
  }

  Future<bool> updateCliente(Cliente cliente) async {
    if (cliente.id.isEmpty) return false;
    
    try {
      await _supabase
          .from('clientes')
          .update(cliente.toJson())
          .eq('id', cliente.id);
          
      // Atualiza localmente para ser mais rápido
      final index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = cliente;
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Erro ao atualizar cliente: $e');
      rethrow;
    }
  }

  Future<bool> deleteCliente(String id) async {
    try {
      await _supabase
          .from('clientes')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
          
      // Soft delete local
      _clientes.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao deletar cliente: $e');
      rethrow;
    }
  }
}
