// offline_repository.dart — SQLite persistence layer untuk Android offline.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../app_data.dart';

class OfflineRepository {
  OfflineRepository._internal();
  static final OfflineRepository instance = OfflineRepository._internal();

  // RIWAYAT VERSI:
  // v1: trx + keu (tanpa user_id)
  // v2: tambah tabel users
  // v3: tambah kolom user_id di trx & keu via ALTER TABLE
  // v4: recreate trx & keu dengan user_id sejak awal (lebih andal dari ALTER)
  //     Solusi ini memastikan device Android lama yang masih di v2/v3
  //     tidak crash karena kolom NOT NULL tidak ada.
  static const int _dbVersion = 4;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'offline_app.db');

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, _) async {
        // Install baru: buat semua tabel dengan skema lengkap
        await _createUsersTable(db);
        await _createTrxTable(db);
        await _createKeuTable(db);
        await _createAllIndexes(db);
        debugPrint('[DB] onCreate v$_dbVersion selesai.');
      },
      onUpgrade: (db, oldV, newV) async {
        debugPrint('[DB] onUpgrade v$oldV → v$newV');

        // v1 → tambah tabel users
        if (oldV < 2) {
          try {
            await _createUsersTable(db);
          } catch (e) {
            debugPrint('[DB] users exists: $e');
          }
        }

        // v2/v3 → v4: strategi DROP + recreate untuk trx dan keu
        // Strategi ALTER TABLE ADD COLUMN ... NOT NULL tidak andal di semua
        // versi SQLite Android. DROP + recreate lebih aman.
        if (oldV < 4) {
          // Backup data lama ke tabel sementara
          try {
            await db.execute('ALTER TABLE trx RENAME TO trx_old');
            await _createTrxTable(db);
            // Salin data lama, isi user_id dengan 'USR_DEMO_MITRA' (akun demo)
            await db.execute('''
              INSERT INTO trx (id, user_id, tanggal, kategori, items_json)
              SELECT id,
                     COALESCE(user_id, 'USR_DEMO_MITRA'),
                     tanggal,
                     kategori,
                     COALESCE(items_json, '[]')
              FROM trx_old
            ''');
            await db.execute('DROP TABLE trx_old');
            debugPrint('[DB] trx migrated.');
          } catch (e) {
            // Jika gagal (trx sudah benar / tabel tidak ada), abaikan
            debugPrint('[DB] trx migration note: $e');
            try {
              await _createTrxTable(db);
            } catch (_) {}
          }

          try {
            await db.execute('ALTER TABLE keu RENAME TO keu_old');
            await _createKeuTable(db);
            await db.execute('''
              INSERT INTO keu (id, user_id, keterangan, jumlah, tanggal, jenis)
              SELECT id,
                     COALESCE(user_id, 'USR_DEMO_MITRA'),
                     keterangan,
                     jumlah,
                     tanggal,
                     jenis
              FROM keu_old
            ''');
            await db.execute('DROP TABLE keu_old');
            debugPrint('[DB] keu migrated.');
          } catch (e) {
            debugPrint('[DB] keu migration note: $e');
            try {
              await _createKeuTable(db);
            } catch (_) {}
          }

          await _createAllIndexes(db);
        }
      },
    );
  }

  // ── DDL ───────────────────────────────────────────────────────────────────

  Future<void> _createUsersTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id        TEXT NOT NULL PRIMARY KEY,
      name      TEXT NOT NULL,
      email     TEXT NOT NULL UNIQUE,
      password  TEXT NOT NULL,
      join_date TEXT NOT NULL
    )
  ''');

  Future<void> _createTrxTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS trx (
      id         TEXT NOT NULL PRIMARY KEY,
      user_id    TEXT NOT NULL DEFAULT 'USR_DEMO_MITRA',
      tanggal    TEXT NOT NULL,
      kategori   TEXT NOT NULL,
      items_json TEXT NOT NULL DEFAULT '[]'
    )
  ''');

  Future<void> _createKeuTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS keu (
      id         TEXT    NOT NULL PRIMARY KEY,
      user_id    TEXT    NOT NULL DEFAULT 'USR_DEMO_MITRA',
      keterangan TEXT    NOT NULL,
      jumlah     REAL    NOT NULL CHECK (jumlah > 0),
      tanggal    TEXT    NOT NULL,
      jenis      INTEGER NOT NULL CHECK (jenis IN (0, 1))
    )
  ''');

  Future<void> _createAllIndexes(Database db) async {
    for (final sql in [
      'CREATE INDEX IF NOT EXISTS idx_trx_user    ON trx (user_id)',
      'CREATE INDEX IF NOT EXISTS idx_trx_tanggal ON trx (tanggal DESC)',
      'CREATE INDEX IF NOT EXISTS idx_keu_user    ON keu (user_id)',
      'CREATE INDEX IF NOT EXISTS idx_keu_tanggal ON keu (tanggal DESC)',
      'CREATE INDEX IF NOT EXISTS idx_keu_jenis   ON keu (jenis)',
    ]) {
      try {
        await db.execute(sql);
      } catch (e) {
        debugPrint('[DB] idx: $e');
      }
    }
  }

  // ── Konversi enum ─────────────────────────────────────────────────────────

  int _j2i(JenisKeuangan j) => j == JenisKeuangan.pemasukan ? 0 : 1;
  JenisKeuangan _i2j(int v) =>
      v == 0 ? JenisKeuangan.pemasukan : JenisKeuangan.pengeluaran;

  String _encodeItems(List<TransaksiItem> items) => jsonEncode(
    items
        .map(
          (i) => {
            'jenisIkan': i.jenisIkan,
            'jumlahKg': i.jumlahKg,
            'hargaPerKg': i.hargaPerKg,
          },
        )
        .toList(),
  );

  List<TransaksiItem> _decodeItems(String raw) {
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list.map<TransaksiItem>((e) {
        final m = e as Map<String, dynamic>;
        return TransaksiItem(
          jenisIkan: m['jenisIkan'] as String,
          jumlahKg: (m['jumlahKg'] as num).toDouble(),
          hargaPerKg: (m['hargaPerKg'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[DB] decodeItems error: $e');
      return const [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SEED — dipanggil dari main() sebelum login
  // ═══════════════════════════════════════════════════════════════════════

  /// Seed akun demo jika tabel users masih kosong.
  /// id 'USR_DEMO_MITRA' tetap agar data lama milik akun ini tetap terbaca.
  Future<void> seedDefaultUserIfEmpty() async {
    final db = await database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    if (count > 0) return;

    await insertUser(
      UserAccount(
        id: 'USR_DEMO_MITRA',
        name: 'Mitra Admin',
        email: 'mitra@email.com',
        password: 'admin123',
      ),
    );
    debugPrint('[DB] Akun demo di-seed id=USR_DEMO_MITRA.');
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TRANSAKSI
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<Transaksi>> fetchTransaksi(String userId) async {
    final db = await database;
    final rows = await db.query(
      'trx',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
    );
    return rows
        .map(
          (r) => Transaksi(
            id: r['id'] as String,
            tanggal: r['tanggal'] as String,
            kategori: r['kategori'] as String,
            items: _decodeItems(r['items_json'] as String),
          ),
        )
        .toList();
  }

  Future<void> insertTransaksi(Transaksi t, String userId) async {
    final db = await database;
    await db.insert('trx', {
      'id': t.id,
      'user_id': userId,
      'tanggal': t.tanggal,
      'kategori': t.kategori,
      'items_json': _encodeItems(t.items),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('[DB] insertTransaksi ${t.id} user=$userId ✓');
  }

  Future<void> updateTransaksi(Transaksi t) async {
    final db = await database;
    await db.update(
      'trx',
      {
        'tanggal': t.tanggal,
        'kategori': t.kategori,
        'items_json': _encodeItems(t.items),
      },
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<void> deleteTransaksi(String id) async {
    final db = await database;
    await db.delete('trx', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CATATAN KEUANGAN
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<CatatanKeuangan>> fetchCatatanKeuangan(String userId) async {
    final db = await database;
    final rows = await db.query(
      'keu',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
    );
    return rows
        .map(
          (r) => CatatanKeuangan(
            id: r['id'] as String,
            keterangan: r['keterangan'] as String,
            jumlah: (r['jumlah'] as num).toDouble(),
            tanggal: r['tanggal'] as String,
            jenis: _i2j(r['jenis'] as int),
          ),
        )
        .toList();
  }

  Future<void> insertCatatanKeuangan(CatatanKeuangan c, String userId) async {
    final db = await database;
    await db.insert('keu', {
      'id': c.id,
      'user_id': userId,
      'keterangan': c.keterangan,
      'jumlah': c.jumlah,
      'tanggal': c.tanggal,
      'jenis': _j2i(c.jenis),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('[DB] insertKeuangan ${c.id} user=$userId ✓');
  }

  Future<void> updateCatatanKeuangan(CatatanKeuangan c) async {
    final db = await database;
    await db.update(
      'keu',
      {
        'keterangan': c.keterangan,
        'jumlah': c.jumlah,
        'tanggal': c.tanggal,
        'jenis': _j2i(c.jenis),
      },
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> deleteCatatanKeuangan(String id) async {
    final db = await database;
    await db.delete('keu', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  USERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Simpan user ke SQLite menggunakan u.id yang sudah ditetapkan.
  /// JANGAN generate ulang id — harus konsisten dengan in-memory AuthData.
  Future<void> insertUser(UserAccount u) async {
    final db = await database;
    await db.insert('users', {
      'id': u.id,
      'name': u.name,
      'email': u.email,
      'password': u.password,
      'join_date': u.joinDate,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    debugPrint('[DB] insertUser id=${u.id} email=${u.email} ✓');
  }

  Future<bool> emailExistsOffline(String email) async {
    final db = await database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users WHERE email = ?', [
            email,
          ]),
        ) ??
        0;
    return count > 0;
  }

  Future<UserAccount?> findUserOffline(String email, String password) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return UserAccount(
      id: r['id'] as String,
      name: r['name'] as String,
      email: r['email'] as String,
      password: r['password'] as String,
      joinDate: r['join_date'] as String,
    );
  }
}
