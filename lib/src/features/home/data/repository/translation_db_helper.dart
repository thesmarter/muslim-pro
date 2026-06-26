import 'dart:async';

import 'package:muslim/src/core/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class TranslationDBHelper {
  static const String dbName = "hisn_elmoslem_translations.db";
  static const int dbVersion = 1;

  /* ************* Singleton Constructor ************* */

  static TranslationDBHelper? _databaseHelper;
  static Database? _database;
  static late DBHelper _dbHelper;

  factory TranslationDBHelper() {
    _dbHelper = DBHelper(dbName: dbName, dbVersion: dbVersion);
    _databaseHelper ??= TranslationDBHelper._createInstance();
    return _databaseHelper!;
  }

  TranslationDBHelper._createInstance();

  Future<Database> get database async {
    _database ??= await _dbHelper.initDatabase();
    return _database!;
  }

  /* ************* Title Translations ************* */

  Future<String?> getTitleTranslation(int titleId, String language) async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT name FROM title_translations WHERE titleId = ? AND language = ?''',
      [titleId, language],
    );

    if (maps.isEmpty) return null;
    return maps.first['name'] as String?;
  }

  Future<Map<int, String>> getAllTitleTranslations(String language) async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT titleId, name FROM title_translations WHERE language = ?''',
      [language],
    );

    final Map<int, String> result = {};
    for (final map in maps) {
      final int titleId = map['titleId'] as int;
      final String name = map['name'] as String;
      result[titleId] = name;
    }
    return result;
  }

  /* ************* Content Translations ************* */

  Future<Map<String, String?>?> getContentTranslation(
    int contentId,
    String language,
  ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT content, transliteration, fadl FROM content_translations WHERE contentId = ? AND language = ?''',
      [contentId, language],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return {
      'content': map['content'] as String?,
      'transliteration': map['transliteration'] as String?,
      'fadl': map['fadl'] as String?,
    };
  }

  Future<Map<int, Map<String, String?>>> getAllContentTranslations(
    String language,
  ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT contentId, content, transliteration, fadl FROM content_translations WHERE language = ?''',
      [language],
    );

    final Map<int, Map<String, String?>> result = {};
    for (final map in maps) {
      final int contentId = map['contentId'] as int;
      result[contentId] = {
        'content': map['content'] as String?,
        'transliteration': map['transliteration'] as String?,
        'fadl': map['fadl'] as String?,
      };
    }
    return result;
  }

  /* ************* Available Languages ************* */

  Future<List<String>> getAvailableLanguages() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT DISTINCT language FROM title_translations''',
    );

    return maps.map((map) => map['language'] as String).toList();
  }

  /* ************* Close database ************* */

  Future close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
