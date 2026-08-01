// ═══════════════════════════════════════════════════════════════════════════════
//  auth.dart
//  Halaman Login & Register dalam satu layar dengan tab switcher
//  Terhubung ke AuthData singleton di app_data.dart
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'app_data.dart';
import 'dashboard.dart';
import 'data/local/local_data_manager.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  // 0 = Login, 1 = Register
  int _tab = 0;

  late final AnimationController _slideAnim;
  late final Animation<Offset> _slideIn;

  // ── LOGIN fields ─────────────────────────────────────────────────────────────
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPassHidden = true;
  bool _loginLoading = false;

  // ── REGISTER fields ──────────────────────────────────────────────────────────
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  bool _regPassHidden = true;
  bool _regConfirmHidden = true;
  bool _regLoading = false;

  @override
  void initState() {
    super.initState();
    _slideAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnim, curve: Curves.easeOutCubic));
    _slideAnim.forward();
  }

  @override
  void dispose() {
    _slideAnim.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int t) {
    if (t == _tab) return;
    _slideAnim.reset();
    setState(() => _tab = t);
    _slideAnim.forward();
  }

  Future<void> _doLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _snack('Mohon isi email dan password', isError: true);
      return;
    }
    if (!email.contains('@')) {
      _snack('Format email tidak valid', isError: true);
      return;
    }

    setState(() => _loginLoading = true);
    // ── PERBAIKAN: cek in-memory dulu, lalu fallback ke SQLite ──────────────
    // Dulu: hanya AuthData().findUser() → akun yang dibuat di sesi lalu tidak
    //       ada di memori → login selalu gagal setelah restart aplikasi.
    UserAccount? user = AuthData().findUser(email, pass);
    user ??= await LocalDataManager.loginUser(email, pass);

    setState(() => _loginLoading = false);

    if (user == null) {
      _snack('Email atau password salah', isError: true);
      return;
    }

    // Pastikan sesi aktif tersimpan di kedua singleton
    AuthData().login(user);

    // ── PERBAIKAN UTAMA: muat data SQLite user ini setelah login ────────────
    // Dulu: tidak ada pemanggilan ini → AppData selalu kosong setelah restart.
    await LocalDataManager.loadDataUntukUser();

    if (!mounted) return;
    _goToDashboard();
  }

  Future<void> _doRegister() async {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text;
    final confirm = _regConfirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _snack('Mohon lengkapi semua field', isError: true);
      return;
    }
    if (!email.contains('@')) {
      _snack('Format email tidak valid', isError: true);
      return;
    }
    if (pass.length < 6) {
      _snack('Password minimal 6 karakter', isError: true);
      return;
    }
    if (pass != confirm) {
      _snack('Konfirmasi password tidak cocok', isError: true);
      return;
    }
    if (AuthData().emailExists(email)) {
      _snack('Email sudah terdaftar', isError: true);
      return;
    }

    setState(() => _regLoading = true);
    final newUser = UserAccount(
      id: 'USR${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      password: pass,
    );

    // ── PERBAIKAN: simpan ke SQLite agar akun tidak hilang setelah restart ──
    // Dulu: AuthData().register() hanya menyimpan ke in-memory → akun hilang
    //       saat aplikasi ditutup → tidak bisa login kembali.
    final berhasil = await LocalDataManager.registerUser(newUser);
    if (!berhasil) {
      setState(() => _regLoading = false);
      _snack('Email sudah terdaftar', isError: true);
      return;
    }

    // Set sesi aktif di kedua singleton
    AuthData().login(newUser);

    // Akun baru = belum ada data → tidak perlu loadDataUntukUser()
    // AppData sudah kosong secara default, langsung ke dashboard.

    setState(() => _regLoading = false);
    _snack('Akun berhasil dibuat, selamat datang $name!');
    if (!mounted) return;
    _goToDashboard();
  }

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const DashboardScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (_) => false,
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: kSnackTextStyle),
        backgroundColor: isError ? kRed : kGreen,

        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FF),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF082060),
                    Color(0xFF1045BB),
                    Color(0xFF1D82EE),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: _blob(140, Colors.white.withValues(alpha: 0.07)),
                  ),
                  Positioned(
                    right: 60,
                    top: 40,
                    child: _blob(55, Colors.white.withValues(alpha: 0.09)),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: _blob(90, Colors.white.withValues(alpha: 0.05)),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: const Color(0xFF1045BB),
                              size: 46,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1D82EE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'DIGITAL STATISTIK PERIKANAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SISTEM MANAJEMEN BUDIDAYA IKAN',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1045BB,
                          ).withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _TabBtn(
                                label: 'LOGIN',
                                active: _tab == 0,
                                onTap: () => _switchTab(0),
                              ),
                              const SizedBox(width: 10),
                              _TabBtn(
                                label: 'REGISTER',
                                active: _tab == 1,
                                onTap: () => _switchTab(1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFF0F0F8)),
                        const SizedBox(height: 4),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: SlideTransition(
                              position: _slideIn,
                              child: FadeTransition(
                                opacity: _slideAnim,
                                child: _tab == 0
                                    ? _loginForm()
                                    : _registerForm(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat Datang',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0C1A5E),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Masuk ke akun Anda',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _field(
          controller: _loginEmailCtrl,
          label: 'Email',
          hint: 'nama@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _loginPassCtrl,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          passwordHidden: _loginPassHidden,
          onTogglePassword: () =>
              setState(() => _loginPassHidden = !_loginPassHidden),
        ),
        const SizedBox(height: 24),

        _SubmitBtn(label: 'MASUK', loading: _loginLoading, onTap: _doLogin),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'atau',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () => _switchTab(1),
            child: RichText(
              text: const TextSpan(
                text: 'Belum punya akun? ',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Daftar Sekarang',
                    style: TextStyle(
                      color: Color(0xFF1045BB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _registerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buat Akun Baru',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0C1A5E),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Daftarkan diri Anda dengan email',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        _field(
          controller: _regNameCtrl,
          label: 'Nama Lengkap',
          hint: 'Nama Anda',
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _regEmailCtrl,
          label: 'Email',
          hint: 'nama@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _regPassCtrl,
          label: 'Password',
          hint: 'Min. 6 karakter',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          passwordHidden: _regPassHidden,
          onTogglePassword: () =>
              setState(() => _regPassHidden = !_regPassHidden),
        ),
        const SizedBox(height: 12),
        _field(
          controller: _regConfirmCtrl,
          label: 'Konfirmasi Password',
          hint: 'Ulangi password',
          icon: Icons.lock_reset_rounded,
          isPassword: true,
          passwordHidden: _regConfirmHidden,
          onTogglePassword: () =>
              setState(() => _regConfirmHidden = !_regConfirmHidden),
        ),
        const SizedBox(height: 24),
        _SubmitBtn(label: 'DAFTAR', loading: _regLoading, onTap: _doRegister),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: () => _switchTab(0),
            child: RichText(
              text: const TextSpan(
                text: 'Sudah punya akun? ',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Masuk',
                    style: TextStyle(
                      color: Color(0xFF1045BB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool passwordHidden = true,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333355),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && passwordHidden,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF1045BB), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      passwordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF6F8FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE3F5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE3F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1045BB),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAB BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1045BB) : const Color(0xFFF0F3FF),
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF1045BB).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SUBMIT BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _SubmitBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitBtn({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1045BB), Color(0xFF1D82EE)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1045BB).withValues(alpha: 0.42),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PROFILE DIALOG  — dipanggil dari header tombol profil
// ══════════════════════════════════════════════════════════════════════════════
class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthData().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF082060), Color(0xFF1D82EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF1045BB),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Column(
              children: [
                _InfoRow(Icons.badge_outlined, 'Nama', user.name),
                const Divider(height: 16),
                _InfoRow(Icons.email_outlined, 'Email', user.email),
                const Divider(height: 16),
                _InfoRow(
                  Icons.calendar_today_outlined,
                  'Bergabung',
                  user.joinDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                // AuthData.logout() sekarang juga membersihkan AppData
                // (transaksiList, catatanKeuanganList, currentUser) agar
                // data user sebelumnya tidak muncul sebentar saat user
                // berikutnya login.
                AuthData().logout();
                if (!context.mounted) return;
                await Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, __) => const AuthPage(),
                    transitionsBuilder: (_, a, __, c) =>
                        FadeTransition(opacity: a, child: c),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                  (_) => false,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kRed.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: kRed, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        color: kRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1045BB)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0C1A5E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
