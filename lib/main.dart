// ═══════════════════════════════════════════════════════════════════════════════
//  main.dart
//  Entry point aplikasi + MainShell (navigasi antar sub-halaman)
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'app_data.dart';
import 'auth.dart';
import 'dashboard.dart';
import 'pengiriman.dart';
import 'keuangan.dart';
import 'input.dart';
import 'transaksi.dart';
import 'riwayat.dart';
import 'data/local/local_data_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── PERBAIKAN: initData() TIDAK dipanggil di sini ────────────────────────
  // Dulu: initData() dipanggil sebelum login → _currentUserId selalu null
  //        → tidak ada data yang dimuat → data tampak hilang setelah restart.
  // Sekarang: initData() dipanggil di auth.dart tepat SETELAH login/register
  //           berhasil, saat uid sudah tersedia.
  //
  // Yang tetap dilakukan di sini:
  // 1. Seed akun demo ke SQLite (tanpa perlu uid) agar bisa login di sesi pertama.
  // 2. Seed akun demo ke in-memory (AuthData) untuk fallback.
  await LocalDataManager.seedUsersIfEmpty();
  AuthData().seedDefaultUsers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIGITAL STATISTIK PERIKANAN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthPage(),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final String footer;
  const NavItem({
    required this.icon,
    required this.label,
    required this.footer,
  });
}

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 2});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const List<NavItem> _navItems = [
    NavItem(icon: Icons.send, label: 'KIRIM', footer: 'PENGIRIMAN'),
    NavItem(
      icon: Icons.account_balance_wallet,
      label: 'KEUANGAN',
      footer: 'KEUANGAN',
    ),
    NavItem(icon: Icons.edit_note, label: 'INPUT', footer: 'PENCATATAN'),
    NavItem(icon: Icons.receipt_long, label: 'TRANSAKSI', footer: 'TRANSAKSI'),
    NavItem(icon: Icons.history, label: 'RIWAYAT', footer: 'RIWAYAT'),
  ];

  late final List<Widget> _pages = [
    SharePage(onNavigate: (i) => setState(() => _currentIndex = i)),
    LaporanKeuanganPage(onNavigate: (i) => setState(() => _currentIndex = i)),
    const InputTransaksiPage(),
    const LaporanTransaksiPage(),
    const RiwayatPage(),
  ];

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
          DashboardButton(onTap: _goToDashboard),
          _BottomNavBar(
            currentIndex: _currentIndex,
            items: _navItems,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ],
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final VoidCallback onTap;
  const DashboardButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.dashboard, color: kBlue),
        label: const Text(
          'KEMBALI KE DASHBOARD',
          style: TextStyle(color: kBlue, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF061440),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        color: active ? Colors.white : Colors.white54,
                        size: 24,
                      ),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
