import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/bico_provider.dart';
import '../widgets/tuco_slot.dart';
import '../widgets/bico_button.dart';
import '../widgets/bico_field.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _total = 4;
  static const _professions = [
    'Personal trainer',
    'Manicure',
    'Cabeleireiro',
    'Faxineira',
    'Eletricista',
    'Encanador',
    'Fotografo',
    'Confeiteira',
    'Pintor',
    'Designer',
    'Massoterapeuta',
    'Outro',
  ];
  static const _states = [
    _BrazilState('AC', 12, 'Acre'),
    _BrazilState('AL', 27, 'Alagoas'),
    _BrazilState('AP', 16, 'Amapa'),
    _BrazilState('AM', 13, 'Amazonas'),
    _BrazilState('BA', 29, 'Bahia'),
    _BrazilState('CE', 23, 'Ceara'),
    _BrazilState('DF', 53, 'Distrito Federal'),
    _BrazilState('ES', 32, 'Espirito Santo'),
    _BrazilState('GO', 52, 'Goias'),
    _BrazilState('MA', 21, 'Maranhao'),
    _BrazilState('MT', 51, 'Mato Grosso'),
    _BrazilState('MS', 50, 'Mato Grosso do Sul'),
    _BrazilState('MG', 31, 'Minas Gerais'),
    _BrazilState('PA', 15, 'Para'),
    _BrazilState('PB', 25, 'Paraiba'),
    _BrazilState('PR', 41, 'Parana'),
    _BrazilState('PE', 26, 'Pernambuco'),
    _BrazilState('PI', 22, 'Piaui'),
    _BrazilState('RJ', 33, 'Rio de Janeiro'),
    _BrazilState('RN', 24, 'Rio Grande do Norte'),
    _BrazilState('RS', 43, 'Rio Grande do Sul'),
    _BrazilState('RO', 11, 'Rondonia'),
    _BrazilState('RR', 14, 'Roraima'),
    _BrazilState('SC', 42, 'Santa Catarina'),
    _BrazilState('SP', 35, 'Sao Paulo'),
    _BrazilState('SE', 28, 'Sergipe'),
    _BrazilState('TO', 17, 'Tocantins'),
  ];

  int _step = 0;
  String _selectedCategory = 'Personal trainer';
  int _selectedServiceDuration = 60;
  String? _selectedState;
  String? _selectedCity;
  bool _isLoading = false;
  bool _isLoadingCities = false;
  String? _citiesError;
  List<String> _cities = [];
  final List<_InitialServiceDraft> _initialServices = [];

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _stateSearchCtrl = TextEditingController();
  final _citySearchCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _stateFocus = FocusNode();
  final _cityFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    _nameCtrl.text = metadata?['full_name'] ?? metadata?['name'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _stateSearchCtrl.dispose();
    _citySearchCtrl.dispose();
    _customCategoryCtrl.dispose();
    _bioCtrl.dispose();
    _stateFocus.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BicoNotifier>();
    final tokens = notifier.tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _step > 0
                            ? () => setState(() => _step--)
                            : null,
                        icon: Icon(
                          Icons.arrow_back,
                          size: 22,
                          color: _step > 0 ? tokens.text : tokens.textFaint,
                        ),
                      ),
                      Text(
                        '${_step + 1} de $_total',
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(
                      _total,
                      (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(left: i > 0 ? 5 : 0),
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? tokens.green
                                : tokens.borderSoft,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _buildStep(tokens),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: BicoButton(
                variant: BtnVariant.primary,
                full: true,
                onPressed: _isLoading ? () {} : _next,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _step < _total - 1
                                ? 'Continuar'
                                : 'Finalizar cadastro',
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(dynamic tokens) {
    switch (_step) {
      case 0:
        return _StepScaffold(
          tokens: tokens,
          title: 'Vamos montar seu perfil',
          subtitle:
              'Esses dados aparecem no app e ajudam seus clientes a reconhecerem voce.',
          child: Column(
            children: [
              BicoField(
                label: 'Nome completo',
                placeholder: 'Joao da Silva',
                controller: _nameCtrl,
                leadingIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              BicoField(
                label: 'WhatsApp',
                placeholder: '11999998888',
                controller: _phoneCtrl,
                leadingIcon: Icons.phone_outlined,
                hint: 'Pode digitar com DDD. Exemplo salvo: +5511999998888',
              ),
            ],
          ),
        );
      case 1:
        return _StepScaffold(
          tokens: tokens,
          title: 'O que voce faz?',
          subtitle:
              'Escolha sua principal area de trabalho. Voce pode mudar isso depois.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _professions.map((profession) {
                  final selected = profession == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = profession),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? tokens.green : tokens.bgSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? tokens.green : tokens.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            profession,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : tokens.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _selectedCategory == 'Outro'
                    ? Padding(
                        key: const ValueKey('custom-category'),
                        padding: const EdgeInsets.only(top: 16),
                        child: BicoField(
                          label: 'Qual area?',
                          placeholder: 'Exemplo: Montador de moveis',
                          controller: _customCategoryCtrl,
                          leadingIcon: Icons.work_outline,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-category')),
              ),
              const SizedBox(height: 18),
              Text(
                'Duracao deste servico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 60, 90, 120, 150, 180, 240, 300, 360, 480].map((
                  minutes,
                ) {
                  final selected = minutes == _selectedServiceDuration;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedServiceDuration = minutes),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? tokens.green : tokens.bgSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? tokens.green : tokens.border,
                        ),
                      ),
                      child: Text(
                        _durationLabel(minutes),
                        style: TextStyle(
                          color: selected ? Colors.white : tokens.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addInitialService,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar servico'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.green,
                  side: BorderSide(color: tokens.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_initialServices.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  children: _initialServices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final service = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.bgSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.borderSoft),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.design_services_outlined,
                            size: 18,
                            color: tokens.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${service.name} - ${_durationLabel(service.durationMinutes)}',
                              style: TextStyle(
                                color: tokens.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(
                              () => _initialServices.removeAt(index),
                            ),
                            icon: Icon(Icons.close, color: tokens.textMuted),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      case 2:
        return _StepScaffold(
          tokens: tokens,
          title: 'Onde voce atende?',
          subtitle:
              'Use sua cidade base. Isso ajuda o app a organizar agenda, clientes e perfil.',
          child: Column(
            children: [
              _BicoAutocomplete<_BrazilState>(
                label: 'UF',
                placeholder: 'Digite UF ou estado',
                controller: _stateSearchCtrl,
                focusNode: _stateFocus,
                leadingIcon: Icons.map_outlined,
                optionsBuilder: (text) => _filteredStates(text),
                displayStringForOption: _stateLabel,
                onTextChanged: _handleStateTextChanged,
                onSelected: _selectState,
              ),
              const SizedBox(height: 14),
              _BicoAutocomplete<String>(
                label: 'Cidade',
                placeholder: _cityPlaceholder(),
                controller: _citySearchCtrl,
                focusNode: _cityFocus,
                enabled:
                    _selectedState != null &&
                    !_isLoadingCities &&
                    _cities.isNotEmpty,
                leadingIcon: Icons.location_city_outlined,
                error: _citiesError,
                optionsBuilder: (text) => _filteredCities(text),
                displayStringForOption: (city) => city,
                onTextChanged: _handleCityTextChanged,
                onSelected: (city) {
                  setState(() => _selectedCity = city);
                },
              ),
              if (_isLoadingCities) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 3,
                  color: tokens.green,
                  backgroundColor: tokens.borderSoft,
                ),
              ],
              if (_citiesError != null && _selectedState != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      final state = _states.firstWhere(
                        (item) => item.uf == _selectedState,
                      );
                      _loadCitiesForState(state);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Tentar novamente'),
                  ),
                ),
              ],
            ],
          ),
        );
      default:
        return _StepScaffold(
          tokens: tokens,
          title: 'Conte um pouco sobre seu trabalho',
          subtitle:
              'Uma frase curta ja basta. Ela fica salva no seu perfil profissional.',
          child: Column(
            children: [
              BicoField(
                label: 'Bio',
                placeholder: 'Atendo com horario marcado e foco em qualidade.',
                controller: _bioCtrl,
                leadingIcon: Icons.edit_note_outlined,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TucoSlot(size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Depois do onboarding, o dashboard e o perfil usam estes dados automaticamente.',
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.text,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _next() async {
    final error = _validateCurrentStep();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (_step < _total - 1) {
      setState(() => _step++);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<BicoNotifier>().completeOnboarding(
        nomeCompleto: _nameCtrl.text.trim(),
        telefone: _normalizedPhone(),
        categoria: _categoryToSave(),
        cidade: _selectedCity!,
        estado: _selectedState!,
        bio: _bioCtrl.text,
        initialServices: _servicesToSave(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar cadastro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateCurrentStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().length < 3) return 'Informe seu nome completo.';
      if (!_isValidPhone(_normalizedPhone())) {
        return 'Informe um WhatsApp valido com DDD.';
      }
    }
    if (_step == 1 && _selectedCategory == 'Outro') {
      if (_customCategoryCtrl.text.trim().length < 2) {
        return 'Informe sua area de trabalho.';
      }
    }
    if (_step == 2) {
      if (_selectedState == null) return 'Selecione a UF.';
      if (_isLoadingCities) return 'Aguarde as cidades carregarem.';
      if (_citiesError != null) return 'Carregue a lista de cidades novamente.';
      if (_selectedCity == null) return 'Selecione sua cidade.';
    }
    return null;
  }

  Iterable<_BrazilState> _filteredStates(String text) {
    final query = _normalizeSearch(text);
    if (query.isEmpty) return _states;
    return _states
        .where((state) {
          return _normalizeSearch(state.uf).contains(query) ||
              _normalizeSearch(state.name).contains(query) ||
              _normalizeSearch(_stateLabel(state)).contains(query);
        })
        .take(8);
  }

  Iterable<String> _filteredCities(String text) {
    final query = _normalizeSearch(text);
    final options = query.isEmpty
        ? _cities
        : _cities.where((city) => _normalizeSearch(city).contains(query));
    return options.take(12);
  }

  void _handleStateTextChanged(String text) {
    final match = _matchingState(text);
    if (match != null) {
      if (_selectedState != match.uf) _selectState(match);
      return;
    }

    if (_selectedState == null &&
        _selectedCity == null &&
        _cities.isEmpty &&
        _citiesError == null) {
      return;
    }

    setState(() {
      _selectedState = null;
      _selectedCity = null;
      _cities = [];
      _citiesError = null;
      _isLoadingCities = false;
    });
    _citySearchCtrl.clear();
  }

  void _handleCityTextChanged(String text) {
    final match = _matchingCity(text);
    if (_selectedCity == match) return;
    setState(() => _selectedCity = match);
  }

  void _selectState(_BrazilState state) {
    final label = _stateLabel(state);
    if (_stateSearchCtrl.text != label) {
      _stateSearchCtrl.text = label;
      _stateSearchCtrl.selection = TextSelection.collapsed(
        offset: _stateSearchCtrl.text.length,
      );
    }
    _citySearchCtrl.clear();
    _loadCitiesForState(state);
  }

  _BrazilState? _matchingState(String text) {
    final query = _normalizeSearch(text);
    if (query.isEmpty) return null;
    for (final state in _states) {
      if (query == _normalizeSearch(state.uf) ||
          query == _normalizeSearch(state.name) ||
          query == _normalizeSearch(_stateLabel(state))) {
        return state;
      }
    }
    return null;
  }

  String? _matchingCity(String text) {
    final query = _normalizeSearch(text);
    if (query.isEmpty) return null;
    for (final city in _cities) {
      if (query == _normalizeSearch(city)) return city;
    }
    return null;
  }

  String _stateLabel(_BrazilState state) => '${state.uf} - ${state.name}';

  String _normalizeSearch(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  Future<void> _loadCitiesForState(_BrazilState state) async {
    setState(() {
      _selectedState = state.uf;
      _selectedCity = null;
      _cities = [];
      _citiesError = null;
      _isLoadingCities = true;
    });

    try {
      final uri = Uri.https(
        'servicodados.ibge.gov.br',
        '/api/v1/localidades/estados/${state.code}/municipios',
        {'orderBy': 'nome'},
      );
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      final cities = data
          .map((item) => (item as Map<String, dynamic>)['nome'] as String)
          .toList();

      if (!mounted || _selectedState != state.uf) return;
      setState(() {
        _cities = cities;
        _citiesError = cities.isEmpty ? 'Nenhuma cidade encontrada.' : null;
        _isLoadingCities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _citiesError = 'Nao consegui carregar as cidades desta UF.';
        _isLoadingCities = false;
      });
    }
  }

  String _cityPlaceholder() {
    if (_selectedState == null) return 'Escolha uma UF primeiro';
    if (_isLoadingCities) return 'Carregando cidades...';
    if (_citiesError != null) return 'Erro ao carregar';
    return 'Selecione a cidade';
  }

  String _categoryToSave() {
    if (_selectedCategory == 'Outro') {
      return _customCategoryCtrl.text.trim();
    }
    return _selectedCategory;
  }

  void _addInitialService() {
    final name = _categoryToSave();
    if (name.length < 2) return;
    final exists = _initialServices.any(
      (service) => _normalizeSearch(service.name) == _normalizeSearch(name),
    );
    if (exists) return;
    setState(() {
      _initialServices.add(
        _InitialServiceDraft(name, _selectedServiceDuration),
      );
    });
  }

  List<Map<String, dynamic>> _servicesToSave() {
    final services = _initialServices.isEmpty
        ? [_InitialServiceDraft(_categoryToSave(), _selectedServiceDuration)]
        : _initialServices;
    return services
        .map(
          (service) => {
            'nome': service.name,
            'duracao_minutos': service.durationMinutes,
            'preco_centavos': 0,
            'ativo': true,
          },
        )
        .toList();
  }

  String _durationLabel(int minutes) {
    if (minutes == 30) return '30 min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final hourText = hours == 1 ? '1 hora' : '$hours horas';
    if (rest == 0) return hourText;
    if (rest == 30) return '$hourText e meia';
    return '$hourText e $rest min';
  }

  String _normalizedPhone() {
    final raw = _phoneCtrl.text.trim();
    if (raw.startsWith('+')) return '+${raw.replaceAll(RegExp(r'[^0-9]'), '')}';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('55')) return '+$digits';
    return '+55$digits';
  }

  bool _isValidPhone(String value) {
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value) && value.length >= 13;
  }
}

class _BrazilState {
  final String uf;
  final int code;
  final String name;

  const _BrazilState(this.uf, this.code, this.name);
}

class _InitialServiceDraft {
  final String name;
  final int durationMinutes;

  const _InitialServiceDraft(this.name, this.durationMinutes);
}

class _BicoAutocomplete<T extends Object> extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Iterable<T> Function(String text) optionsBuilder;
  final String Function(T option) displayStringForOption;
  final ValueChanged<T> onSelected;
  final ValueChanged<String>? onTextChanged;
  final IconData? leadingIcon;
  final bool enabled;
  final String? error;

  const _BicoAutocomplete({
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    required this.optionsBuilder,
    required this.displayStringForOption,
    required this.onSelected,
    this.onTextChanged,
    this.leadingIcon,
    this.enabled = true,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<BicoNotifier>().tokens;
    final borderColor = error != null ? tokens.red : tokens.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.text,
          ),
        ),
        const SizedBox(height: 6),
        RawAutocomplete<T>(
          textEditingController: controller,
          focusNode: focusNode,
          displayStringForOption: displayStringForOption,
          optionsBuilder: (editingValue) {
            if (!enabled) return const Iterable.empty();
            return optionsBuilder(editingValue.text);
          },
          onSelected: onSelected,
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                return Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: enabled ? tokens.bgSoft : tokens.borderSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      if (leadingIcon != null) ...[
                        Icon(
                          leadingIcon,
                          size: 18,
                          color: enabled ? tokens.textMuted : tokens.textFaint,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          enabled: enabled,
                          onChanged: onTextChanged,
                          style: TextStyle(fontSize: 16, color: tokens.text),
                          decoration: InputDecoration(
                            hintText: placeholder,
                            hintStyle: TextStyle(color: tokens.textMuted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: enabled ? tokens.textMuted : tokens.textFaint,
                      ),
                    ],
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: tokens.bgSoft,
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    minWidth: 280,
                    maxWidth: 420,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            displayStringForOption(option),
                            style: TextStyle(fontSize: 15, color: tokens.text),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error!, style: TextStyle(fontSize: 12, color: tokens.red)),
        ],
      ],
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final dynamic tokens;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: TucoSlot(size: 72)),
        const SizedBox(height: 18),
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: tokens.text,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 15, color: tokens.textMuted, height: 1.45),
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}
