import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('oshi_app.db');
    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        note TEXT,
        logo_path TEXT,
        sns_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE idols (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo_path TEXT,
        start_date TEXT,
        note TEXT,
        color TEXT,
        birthday TEXT,
        sns_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE idol_groups (
        idol_id INTEGER,
        group_id INTEGER,
        PRIMARY KEY (idol_id, group_id),
        FOREIGN KEY (idol_id) REFERENCES idols(id),
        FOREIGN KEY (group_id) REFERENCES groups(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lives (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        venue TEXT,
        date TEXT,
        time TEXT,
        photo_path TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE live_idols (
        live_id INTEGER,
        idol_id INTEGER,
        PRIMARY KEY (live_id, idol_id),
        FOREIGN KEY (live_id) REFERENCES lives(id),
        FOREIGN KEY (idol_id) REFERENCES idols(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE live_groups (
        live_id INTEGER,
        group_id INTEGER,
        PRIMARY KEY (live_id, group_id),
        FOREIGN KEY (live_id) REFERENCES lives(id),
        FOREIGN KEY (group_id) REFERENCES groups(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cheki (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idol_id INTEGER,
        live_id INTEGER,
        photo_path TEXT,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (idol_id) REFERENCES idols(id),
        FOREIGN KEY (live_id) REFERENCES lives(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE filter_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        params_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE idols ADD COLUMN birthday TEXT');
      await db.execute('ALTER TABLE idols ADD COLUMN sns_twitter TEXT');
      await db.execute('ALTER TABLE idols ADD COLUMN sns_instagram TEXT');
      await db.execute('ALTER TABLE idols ADD COLUMN sns_tiktok TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE idols ADD COLUMN sns_json TEXT');
      await db.execute('ALTER TABLE groups ADD COLUMN logo_path TEXT');
      await db.execute('ALTER TABLE groups ADD COLUMN sns_json TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE filter_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          params_json TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // lives 表加 time 字段
      await db.execute('ALTER TABLE lives ADD COLUMN time TEXT');
      // 新增 live_groups 表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS live_groups (
          live_id INTEGER,
          group_id INTEGER,
          PRIMARY KEY (live_id, group_id),
          FOREIGN KEY (live_id) REFERENCES lives(id),
          FOREIGN KEY (group_id) REFERENCES groups(id)
        )
      ''');
      // lives.name 原来是 NOT NULL，SQLite 无法直接修改约束，
      // 已在 _createDB 中改为可空，旧数据不受影响。
    }
  }
}
