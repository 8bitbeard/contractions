import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contraction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'contractions.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contractions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time INTEGER NOT NULL,
            end_time INTEGER
          )
        ''');
      },
    );
  }

  Future<Contraction> insert(Contraction contraction) async {
    final db = await database;
    final id = await db.insert('contractions', contraction.toMap()..remove('id'));
    return contraction.copyWith(id: id);
  }

  Future<void> update(Contraction contraction) async {
    final db = await database;
    await db.update(
      'contractions',
      contraction.toMap(),
      where: 'id = ?',
      whereArgs: [contraction.id],
    );
  }

  Future<List<Contraction>> getAll() async {
    final db = await database;
    final maps = await db.query('contractions', orderBy: 'start_time DESC');
    return maps.map(Contraction.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('contractions', where: 'id = ?', whereArgs: [id]);
  }
}
