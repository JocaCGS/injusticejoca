import 'package:flutter/material.dart';
import 'package:injustice_app/core/di/dependency_injection.dart';
import 'package:injustice_app/domain/models/character_entity.dart';
import 'package:injustice_app/presentation/controllers/characters_state_viewmodel.dart';
import 'package:injustice_app/presentation/controllers/characters_view_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validators/empty_str_validator.dart';
import '../functions/ui_functions.dart';
import '../widgets/account_attribute_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/input_text_field.dart';
import 'package:signals_flutter/signals_flutter.dart';



class CharacterCreateView extends StatefulWidget {
  const CharacterCreateView({super.key});

  @override
  State<CharacterCreateView> createState() => _CharacterCreateViewState();
}


class _CharacterCreateViewState extends State<CharacterCreateView> {
  late final CharactersViewModel _vmCharacter;
  late final void Function() _disposeCharacterEffect;
  late final void Function() _disposeSuccessEffect;
  late final void Function() _disposeErrorEffect;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  late final CharacterFormFieldsController _formFields;
  

  String _selectedClass = 'Poderoso';

  int _level = 1;
  int _rarity = 1;

  DateTime _createdAt = DateTime.now();
  int _attack = 1;
  int _health = 100;
  int _stars = 4;
  int _threat = 2;
  CharacterAlignment _alignment = CharacterAlignment.heroi;


  final List<String> _classes = [
    'Poderoso',
    'Meta-humano',
    'Agilidade',
    'Arcano',
    'Tecnológico',
  ];

  @override
  void initState() {
    super.initState();
    _formFields = CharacterFormFieldsController();
    _vmCharacter = injector.get<CharactersViewModel>();
    _vmCharacter.charactersState.clearMessage();
    _vmCharacter.charactersState.clearFilters();

    _disposeCharacterEffect = effect(()  {
      final character = _vmCharacter.charactersState.selectedCharacter.value;
      if (character != null) {
        _preencherCampos(character);
        } else{
          _limparCampos();
        }
    });

    _disposeErrorEffect = effect(() {
      final errorMessage = _vmCharacter.charactersState.message.value;

      if (errorMessage != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          // );
          showSnackBar(context, errorMessage, backgroundColor: Colors.red);

          _vmCharacter.charactersState.clearMessage();
        });
      }
    });

    _disposeSuccessEffect = effect(() {
      final event = _vmCharacter.charactersState.successEvent.value;

      if (event != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          String message;
          Color color;

          switch (event) {
            case CharacterSuccessEvent.created:
              message = 'Personagem criado com sucesso!';
              color = Colors.green;

            case CharacterSuccessEvent.updated:
              message = 'Personagem atualizado com sucesso!';
              color = Colors.green;

          }

          showSnackBar(context, message, backgroundColor: color);

          _vmCharacter.charactersState.clearSuccessEvent();
        });
      }
    });
  }

  @override
  void dispose() {
    _disposeCharacterEffect();
    _disposeSuccessEffect();
    _disposeErrorEffect();
    _scrollController.dispose();
    _formFields.dispose();
    super.dispose();
  }

  bool _validateForm() {
    return _formKey.currentState!.validate();
  }

  static CharacterClass _selectedClassToEnum(String selectedClass) {
    switch (selectedClass) {
      case 'Poderoso':
        return CharacterClass.poderoso;
      case 'Meta-humano':
        return CharacterClass.metaHumano;
      case 'Agilidade':
        return CharacterClass.agilidade;
      case 'Arcano':
        return CharacterClass.arcano;
      case 'Tecnológico':
        return CharacterClass.tecnologico;
      default:
        throw ArgumentError('Classe de personagem inválida: $selectedClass');
    }
  }

  static String _enumToSelectedClass(CharacterClass selectedClass) {
    switch (selectedClass) {
      case CharacterClass.poderoso:
        return 'Poderoso';
      case CharacterClass.metaHumano:
        return 'Meta-humano';
      case CharacterClass.agilidade:
        return 'Agilidade';
      case CharacterClass.arcano:
        return 'Arcano';
      case CharacterClass.tecnologico:
        return 'Tecnológico';
    }
  }

  static CharacterRarity _rarityToEnum(int rarity) {
    switch (rarity) {
      case 1:
        return CharacterRarity.prata;
      case 2:
        return CharacterRarity.ouro;
      case 3:
        return CharacterRarity.lendario;
      default:
        throw ArgumentError('Raridade de personagem inválida: $rarity');
    }
  }

  void _salvar() {
    if (!_validateForm()) return;

    Character newCharacter = Character(
      id: _vmCharacter.charactersState.isEditing.value ? _vmCharacter.charactersState.selectedCharacter.value!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _formFields.name.controller.text.trim(),
      characterClass: _selectedClassToEnum(_selectedClass),
      level: _level,
      rarity: _rarityToEnum(_rarity),
      threat: _threat,
      attack: _attack,
      health: _health,
      stars: _stars,
      alignment: _alignment,
      createdAt: _createdAt,
      updatedAt: DateTime.now(), 
    );

    if(_vmCharacter.charactersState.isEditing.value) {
      _vmCharacter.commands.updateCharacter(newCharacter);
    } else {
      _vmCharacter.commands.addCharacter(newCharacter);
    }

    print('Personagem salvo: ${newCharacter.name}, Classe: ${newCharacter.characterClass.displayName}, Nível: ${newCharacter.level}, Raridade: ${newCharacter.rarity.displayName}');

    _resetFormView();
    Navigator.pop(context);
  }

  void _resetFormView() {
    // Remove foco de qualquer TextField
    FocusScope.of(context).unfocus();

    // Rola para o topo
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _preencherCampos(Character character) {
    _formFields.name.controller.text = character.name;
    _selectedClass = _enumToSelectedClass(character.characterClass);
    _level = character.level;
    _rarity = character.rarity.index + 1;

    _attack = character.attack;
    _health = character.health;
    _stars = character.stars;
    _alignment = character.alignment;
    _createdAt = character.createdAt;
    
    setState(() {});
  }

  void _limparCampos() {
    _formKey.currentState?.reset();
    _formFields.clear();
    // _clearForm();

    _createdAt = DateTime.now();
    _attack = 1;
    _health = 100;
    _stars = 4;
    _threat = 2;
    _alignment = CharacterAlignment.heroi;
    //temporario viu, mas tem que colocar os campos


    setState(() {});
  }

  void _cancelar() {

    _vmCharacter.charactersState.selectedCharacter.value = null;
    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Watch((_) => Text(_vmCharacter.charactersState.labelEditMode.value)),
      ),
      drawer: AppDrawer(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: AppSpacing.paddingLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_add,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Crie seu personagem',
                  style: context.textStyles.bodyMedium?.withColor(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // NOME
                InputTextField(
                  fieldKey: _formFields.name.key,
                  controller: _formFields.name.controller,
                  focusNode: _formFields.name.focus,
                  label: 'Nome',
                  hint: 'Digite o nome do personagem',
                  prefixIcon: Icons.badge,
                  validator: (value) =>
                      validateField(value, [EmptyStrValidator()]),
                ),

                const SizedBox(height: AppSpacing.md),

                // CLASSE
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: InputDecoration(
                    labelText: 'Classe',
                    prefixIcon: const Icon(Icons.shield),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _classes
                      .map((classe) => DropdownMenuItem(
                            value: classe,
                            child: Text(classe),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedClass = value!),
                ),

                const SizedBox(height: AppSpacing.md),

                // LEVEL
                AccountAttributeCard(
                  icon: Icons.star,
                  iconColor: Theme.of(context).colorScheme.primary,
                  label: 'Nível',
                  hint: '[1, 80]',
                  minValue: 1,
                  maxValue: 80,
                  value: _level,
                  onChanged: (value) => setState(() => _level = value),
                ),

                const SizedBox(height: 1),

                // RARIDADE
                AccountAttributeCard(
                  icon: Icons.workspace_premium,
                  iconColor: Colors.purple,
                  label: 'Raridade',
                  hint: '[1, 5]',
                  minValue: 1,
                  maxValue: 5,
                  value: _rarity,
                  onChanged: (value) => setState(() => _rarity = value),
                ),

                const SizedBox(height: AppSpacing.md),

                // CRIAR
                ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: Text(
                    'CRIAR',
                    style: context.textStyles.titleMedium?.bold,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // CANCELAR
                ElevatedButton(
                  onPressed: _cancelar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'CANCELAR',
                    style: context.textStyles.titleMedium?.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


typedef FormFieldControl = ({
  GlobalKey<FormFieldState> key,
  FocusNode focus,
  TextEditingController controller,
});

class CharacterFormFieldsController {
  // Campos de Texto/Números
  final FormFieldControl name = _createField();
  final FormFieldControl classe = _createField();
  final FormFieldControl level = _createField();
  final FormFieldControl rarity = _createField();
  // final FormFieldControl attack = _createField();
  // final FormFieldControl threat = _createField();
  // final FormFieldControl health = _createField();
  // final FormFieldControl stars = _createField();
  // final FormFieldControl createdAt = _createField();
  // final FormFieldControl updatedAt = _createField();
  
  
  CharacterAlignment? selectedAlignment;

  // List<FormFieldControl> get fields => [name, level, attack, classe, rarity, threat, health, stars, createdAt, updatedAt];
  List<FormFieldControl> get fields => [name, level, classe, rarity];

  static FormFieldControl _createField() {
    return (
      key: GlobalKey<FormFieldState>(),
      focus: FocusNode(),
      controller: TextEditingController(),
    );
  }

void clear() {
    for (final field in fields) {
      field.controller.clear();
    }
  }
  
  void dispose() {
    for (final field in fields) {
      field.focus.dispose();
      field.controller.dispose();
    }
  }
}