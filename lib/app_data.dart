// app_data.dart — Model, konstanta, singleton data aplikasi.

import 'package:flutter/material.dart';

// ─── AUTH MODELS ──────────────────────────────────────────────────────────────

class UserAccount {
  final String
  id; // WAJIB non-null: tanpa id, filter user_id di SQLite tidak bekerja
  final String name;
  final String email;
  final String password;
  final String joinDate;

  UserAccount({
    required this.id, // ← required, bukan optional
    required this.name,
    required this.email,
    required this.password,
    String? joinDate,
  }) : joinDate =
           joinDate ??
           '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
}

// ─── CONSTANTS ────────────────────────────────────────────────────────────────

const kBlue = Color(0xFF1565C0);
const kBlueBg = Color(0xFFE3F2FD);
const kLightBlue = Color(0xFF42A5F5);
const kGreen = Color(0xFF2E7D32);
const kRed = Color(0xFFD32F2F);
const kRedBg = Color(0xFFFFE8E8);

// ─── DATA MODELS ──────────────────────────────────────────────────────────────

class TransaksiItem {
  final String jenisIkan;
  final double jumlahKg;
  final double hargaPerKg;
  const TransaksiItem({
    required this.jenisIkan,
    required this.jumlahKg,
    required this.hargaPerKg,
  });
  double get subtotal => jumlahKg * hargaPerKg;
}

class Transaksi {
  final String id;
  final String tanggal;
  final List<TransaksiItem> items;
  final String kategori;
  const Transaksi({
    required this.id,
    required this.tanggal,
    required this.items,
    required this.kategori,
  });
  double get totalPenjualan => items.fold(0, (s, i) => s + i.subtotal);
  int get totalIkan => items.length;
  double get totalBerat => items.fold(0.0, (s, i) => s + i.jumlahKg);
}

enum JenisKeuangan { pemasukan, pengeluaran }

class CatatanKeuangan {
  final String id;
  final String keterangan;
  final double jumlah;
  final String tanggal;
  final JenisKeuangan jenis;
  CatatanKeuangan({
    required this.id,
    required this.keterangan,
    required this.jumlah,
    required this.tanggal,
    required this.jenis,
  });
}

// ─── SINGLETON AUTH ───────────────────────────────────────────────────────────

class AuthData {
  static final AuthData _instance = AuthData._internal();
  factory AuthData() => _instance;
  AuthData._internal();

  final List<UserAccount> _users = [];
  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;

  /// Login: set currentUser DAN langsung sync ke AppData.
  /// Ini memastikan LocalDataManager._currentUserId selalu tersedia.
  void login(UserAccount user) {
    final idx = _users.indexWhere((u) => u.email == user.email);
    _currentUser = (idx >= 0) ? _users[idx] : user;
    if (idx < 0) _users.add(user);

    // KRITIS: AppData.currentUser harus selalu sama dengan AuthData.currentUser
    // agar LocalDataManager bisa baca uid tanpa perlu argumen tambahan.
    AppData().currentUser = _currentUser;
  }

  void register(UserAccount user) {
    if (!emailExists(user.email)) _users.add(user);
  }

  /// Logout: bersihkan semua state agar data tidak bocor ke user berikutnya.
  void logout() {
    _currentUser = null;
    AppData().currentUser = null;
    AppData().transaksiList.clear();
    AppData().catatanKeuanganList.clear();
  }

  UserAccount? findUser(String email, String password) {
    for (final u in _users) {
      if (u.email == email && u.password == password) return u;
    }
    return null;
  }

  bool emailExists(String email) => _users.any((u) => u.email == email);

  /// Seed akun demo ke in-memory dengan id tetap 'USR_DEMO_MITRA'.
  /// id HARUS sama dengan yang di-seed ke SQLite oleh seedDefaultUserIfEmpty().
  void seedDefaultUsers() {
    if (!emailExists('mitra@email.com')) {
      register(
        UserAccount(
          id: 'USR_DEMO_MITRA',
          name: 'Mitra Admin',
          email: 'mitra@email.com',
          password: 'admin123',
        ),
      );
    }
  }
}

// ─── SINGLETON DATA ───────────────────────────────────────────────────────────

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  /// User aktif. Diset otomatis oleh AuthData.login() dan logout().
  UserAccount? currentUser;

  final List<Transaksi> transaksiList = [];
  final List<CatatanKeuangan> catatanKeuanganList = [];

  void tambahTransaksi(Transaksi t) => transaksiList.insert(0, t);
  void hapusTransaksi(String id) =>
      transaksiList.removeWhere((t) => t.id == id);
  void editTransaksi(String id, Transaksi upd) {
    final i = transaksiList.indexWhere((t) => t.id == id);
    if (i != -1) transaksiList[i] = upd;
  }

  void tambahCatatanKeuangan(CatatanKeuangan c) =>
      catatanKeuanganList.insert(0, c);
  void hapusCatatanKeuangan(String id) =>
      catatanKeuanganList.removeWhere((c) => c.id == id);
  void editCatatanKeuangan(String id, CatatanKeuangan upd) {
    final i = catatanKeuanganList.indexWhere((c) => c.id == id);
    if (i != -1) catatanKeuanganList[i] = upd;
  }

  double get totalPemasukan => catatanKeuanganList
      .where((c) => c.jenis == JenisKeuangan.pemasukan)
      .fold(0, (s, c) => s + c.jumlah);
  double get totalPengeluaran => catatanKeuanganList
      .where((c) => c.jenis == JenisKeuangan.pengeluaran)
      .fold(0, (s, c) => s + c.jumlah);
  double get arusKasBersih => totalPemasukan - totalPengeluaran;

  Map<String, double> get persentaseKategori {
    if (transaksiList.isEmpty) return {};
    final total = transaksiList.fold(0.0, (s, t) => s + t.totalPenjualan);
    if (total == 0) return {};
    final Map<String, double> map = {};
    for (final t in transaksiList) {
      map[t.kategori] = (map[t.kategori] ?? 0) + t.totalPenjualan;
    }
    return map.map((k, v) => MapEntry(k, v / total * 100));
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────

String formatRupiah(double value) {
  final str = value.abs().toStringAsFixed(0);
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
    count++;
  }
  final result = buffer.toString().split('').reversed.join();
  return value < 0 ? '-$result' : result;
}

InputDecoration buildInputDecoration({String? hint, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: kBlue, width: 1.5),
      ),
      isDense: true,
    );

const TextStyle kSnackTextStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
);
const TextStyle kSnackErrorTextStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w800,
);
const TextStyle kSnackSuccessTextStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w800,
);

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF082060), Color(0xFF1045BB), Color(0xFF1D82EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.waves_rounded, color: kBlue, size: 26),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIGITAL STATISTIK PERIKANAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'SISTEM MANAJEMEN BUDIDAYA IKAN',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
