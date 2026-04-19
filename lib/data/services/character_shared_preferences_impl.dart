import 'dart:convert';

import '../../core/failure/failure.dart';
import '../../core/typedefs/types_defs.dart';
import 'character_local_storage_interface.dart';
import '../../domain/models/character_entity.dart';
import '../../domain/models/character_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/patterns/result.dart';

final class CharacterSharedPreferencesService
    implements ICharacterLocalStorage {
  // Chave de armazenamento para os personagens
  static const String _storageKey = 'characters';

  @override
  Future<CharacterResult> deleteCharacter(String id) async{
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = prefs.getString(_storageKey);

      if (result == null) {
        return Error(EmptyResultFailure());
      }

      final decoded = jsonDecode(result) as List<dynamic>;

      final characters = decoded
          .map((e) => CharacterMapper.fromMap(e as Map<String, dynamic>))
          .toList();

      Character removedCharacter = characters.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Error(EmptyResultFailure())
        );        

      characters.removeWhere((c) => c.id == id);

      await _saveCharacters(characters);

      return Success(removedCharacter);
    } catch (e) {
      return Error(
        ApiLocalFailure('Shared Preferences - Erro ao deletar personagem: $e'),
      );
    }
  }


  @override
  Future<ListCharacterResult> getAllCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = prefs.getString(_storageKey);

      if (result == null || result.isEmpty) {
        // return Error(EmptyResultFailure());
        return Success([]); // Retorna lista vazia se não houver dados
      }

      final decoded = jsonDecode(result) as List<dynamic>;

      final characters = decoded
          .map((e) => CharacterMapper.fromMap(e as Map<String, dynamic>))
          .toList();

      return Success(characters);
    } catch (e) {
      return Error(
        ApiLocalFailure('Shared Preferences - Erro ao obter personagens: $e'),
      );
    }
  }

  @override
  Future<CharacterResult> getCharacterById(String id) {
    // TODO: implement getCharacterById
    throw UnimplementedError();
  }

  @override
  Future<CharacterResult> saveCharacter(Character character) async {
    try {
      final currentResult = await getAllCharacters();

      return await currentResult.fold(
        onSuccess: (characters) async {
          final updatedCharacters = [...characters, character];
          print('Salvando personagem: ${character.name}, ID: ${character.id}');
          await _saveCharacters(updatedCharacters);
          return Success(character);
        },
        onFailure: (failure) async {
          if (failure is EmptyResultFailure) {
            await _saveCharacters([character]);
            return Success(character);
          }

          return Error(ApiLocalFailure());
        },
      );
      
    } catch (e) {
      return Error(
        ApiLocalFailure('Shared Preferences - Erro ao salvar personagem: $e'),
      );
    }
  }

  /// Salva os personagens no storage
  Future<void> _saveCharacters(List<Character> characters) async {
    print("GRAVANDO NO STORAGE: ${characters.length} personagens.");
    try {
      final prefs = await SharedPreferences.getInstance();  
      final jsonString = json.encode(
        characters.map((c) => CharacterMapper.toMap(c)).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      throw ApiLocalFailure('Erro ao salvar personagens: $e');
    }
  }

  @override
Future<CharacterResult> updateCharacter(Character character) async {
  try {
    final currentResult = await getAllCharacters();
    
    return await currentResult.fold(
      onSuccess: (characters) async {
        // Mapeia a lista trocando o antigo pelo novo
        final updatedList = characters.map((c) => c.id == character.id ? character : c).toList();

        await _saveCharacters(updatedList);
        return Success(character);
      },
      onFailure: (failure) async => Error(failure),
    );
  } catch (e) {
    return Error(ApiLocalFailure('Erro ao atualizar: $e'));
  }
}
} 

