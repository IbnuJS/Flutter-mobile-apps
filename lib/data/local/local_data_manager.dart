// local_data_manager.dart — Jembatan UI ↔ AppData (memori) ↔ SQLite.

import 'offline_repository.dart';
import '../../app_data.dart';
import 'package:flutter/foundation.dart';

class LocalDataManager {
  LocalDataManager._();
  static final _repo = OfflineRepository.instance;

  /// uid selalu non-null setelah login karena:
  ///   AuthData.login() → AppData().currentUser = user (user.id selalu ada)
  /// Getter ini mengembalikan null HANYA jika belum login.
  static String? get _uid =>
      AppData().currentUser?.id ?? AuthData().currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════
  //  INISIALISASI
  // ═══════════════════════════════════════════════════════════════════════

  /// Dipanggil dari main() — seed akun demo ke SQLite jika belum ada.
  /// Belum muat data transaksi/keuangan karena uid belum tersedia.
  static Future<void> seedUsersIfEmpty() async {
    if (kIsWeb) return;
    try {
      await _repo.seedDefaultUserIfEmpty();
      debugPrint('[LDM] seedUsersIfEmpty selesai.');
    } catch (e) {
      debugPrint('[LDM] seedUsersIfEmpty error (abaikan): $e');
    }
  }

  /// Dipanggil dari auth.dart SETELAH login/register berhasil.
  /// Muat semua data milik user yang login dari SQLite ke AppData.
  static Future<void> loadDataUntukUser() async {
    if (kIsWeb) return;
    final uid = _uid;
    if (uid == null) {
      debugPrint('[LDM] loadDataUntukUser: uid null, lewati.');
      return;
    }
    try {
      final trx = await _repo.fetchTransaksi(uid);
      final keu = await _repo.fetchCatatanKeuangan(uid);
      AppData().transaksiList
        ..clear()
        ..addAll(trx);
      AppData().catatanKeuanganList
        ..clear()
        ..addAll(keu);
      debugPrint(
        '[LDM] Loaded ${trx.length} trx + ${keu.length} keu (uid=$uid).',
      );
    } catch (e) {
      debugPrint('[LDM] loadDataUntukUser error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TRANSAKSI
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> tambahTransaksi(Transaksi t) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('[LDM] tambahTransaksi: uid null, data tidak disimpan!');
      return; // tidak throw — AppData juga tidak diubah agar tidak inkonsisten
    }
    if (!kIsWeb) await _repo.insertTransaksi(t, uid); // SQLite dulu
    AppData().tambahTransaksi(t); // baru AppData
    debugPrint('[LDM] Transaksi ${t.id} tersimpan (uid=$uid).');
  }

  static Future<void> editTransaksi(String id, Transaksi updated) async {
    AppData().editTransaksi(id, updated);
    if (!kIsWeb) await _repo.updateTransaksi(updated);
  }

  static Future<void> hapusTransaksi(String id) async {
    AppData().hapusTransaksi(id);
    if (!kIsWeb) await _repo.deleteTransaksi(id);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CATATAN KEUANGAN
  // ═══════════════════════════════════════════════════════════════════════

  static Future<void> tambahCatatanKeuangan(CatatanKeuangan c) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('[LDM] tambahCatatanKeuangan: uid null, data tidak disimpan!');
      return;
    }
    if (!kIsWeb) await _repo.insertCatatanKeuangan(c, uid); // SQLite dulu
    AppData().tambahCatatanKeuangan(c); // baru AppData
    debugPrint('[LDM] Keuangan ${c.id} tersimpan (uid=$uid).');
  }

  static Future<void> editCatatanKeuangan(
    String id,
    CatatanKeuangan updated,
  ) async {
    AppData().editCatatanKeuangan(id, updated);
    if (!kIsWeb) await _repo.updateCatatanKeuangan(updated);
  }

  static Future<void> hapusCatatanKeuangan(String id) async {
    AppData().hapusCatatanKeuangan(id);
    if (!kIsWeb) await _repo.deleteCatatanKeuangan(id);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  USER / AUTENTIKASI
  // ═══════════════════════════════════════════════════════════════════════

  /// Register: simpan ke SQLite + in-memory.
  /// u.id HARUS sudah diisi (wajib karena UserAccount.id kini required).
  static Future<bool> registerUser(UserAccount u) async {
    if (AuthData().emailExists(u.email)) return false;
    if (!kIsWeb && await _repo.emailExistsOffline(u.email)) return false;
    if (!kIsWeb) await _repo.insertUser(u);
    AuthData().register(u);
    debugPrint('[LDM] Register OK: ${u.email} (id=${u.id}).');
    return true;
  }

  /// Login dari SQLite — fallback jika akun tidak ada di in-memory.
  /// AuthData.login() di sini juga set AppData().currentUser.
  static Future<UserAccount?> loginUser(String email, String password) async {
    if (kIsWeb) return null;
    final user = await _repo.findUserOffline(email, password);
    if (user != null) {
      AuthData().login(user); // ini juga set AppData().currentUser
      debugPrint('[LDM] Login SQLite OK: ${user.email} (id=${user.id}).');
    }
    return user;
  }
}
