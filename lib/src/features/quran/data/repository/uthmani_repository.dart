import 'dart:io';

import 'package:flutter/services.dart';
import 'package:muslim/src/features/quran/data/models/verse_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class UthmaniRepository {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "quran.ar.uthmani.v2.db");

    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      final data = await rootBundle.load(join("assets", "db", "quran.ar.uthmani.v2.db"));
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  Future<String> getArabicText({
    required int sura,
    required int startAyah,
    required int endAyah,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'arabic_text',
      columns: ['text'],
      where: 'sura = ? AND ayah >= ? AND ayah <= ?',
      whereArgs: [sura, startAyah, endAyah],
      orderBy: 'ayah ASC',
    );

    return maps.map((e) => e['text'] as String).join(" ");
  }

  Future<List<Verse>> getVerses({
    required int sura,
    required int startAyah,
    required int endAyah,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'arabic_text',
      where: 'sura = ? AND ayah >= ? AND ayah <= ?',
      whereArgs: [sura, startAyah, endAyah],
      orderBy: 'ayah ASC',
    );

    return List.generate(maps.length, (i) {
      return Verse.fromMap(maps[i]);
    });
  }
}
