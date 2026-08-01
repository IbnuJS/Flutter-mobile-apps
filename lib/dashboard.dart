// ═══════════════════════════════════════════════════════════════════════════════
//  dashboard.dart  –  Digital Statistik Perikanan
//  Grafik interaktif: Grafik (Bar), Tren (Bezier Line), Proporsi (Donut)
//  Animasi masuk, data real dari AppData, tanpa publikasi kode
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'auth.dart';
import 'main.dart';

// ─── Palet 12 warna berbeda untuk setiap jenis ikan ───────────────
// Setiap index mendapat warna yang kontras dan berbeda agar grafik mudah dibaca.
// Urutan: Biru, Hijau Teal, Oranye, Ungu, Merah, Cyan, Kuning Emas,
//         Indigo, Hijau, Pink, Coklat, Abu Biru.
const _kCC = <Color>[
  Color(0xFF1565C0), // 0 – Biru tua
  Color(0xFF00897B), // 1 – Teal/Hijau laut
  Color(0xFFE65100), // 2 – Oranye
  Color(0xFF6A1B9A), // 3 – Ungu
  Color(0xFFC62828), // 4 – Merah
  Color(0xFF0097A7), // 5 – Cyan tua
  Color(0xFFF9A825), // 6 – Kuning emas
  Color(0xFF283593), // 7 – Indigo
  Color(0xFF2E7D32), // 8 – Hijau
  Color(0xFFAD1457), // 9 – Pink
  Color(0xFF4E342E), // 10 – Coklat
  Color(0xFF37474F), // 11 – Abu biru
];

// Warna terang pasangan (untuk gradient atas bar dan sweep donut)
const _kCL = <Color>[
  Color(0xFF42A5F5), // 0 – Biru muda
  Color(0xFF4DB6AC), // 1 – Teal muda
  Color(0xFFFF8A65), // 2 – Oranye muda
  Color(0xFFAB47BC), // 3 – Ungu muda
  Color(0xFFEF5350), // 4 – Merah muda
  Color(0xFF26C6DA), // 5 – Cyan muda
  Color(0xFFFFEE58), // 6 – Kuning muda
  Color(0xFF5C6BC0), // 7 – Indigo muda
  Color(0xFF66BB6A), // 8 – Hijau muda
  Color(0xFFEC407A), // 9 – Pink muda
  Color(0xFF8D6E63), // 10 – Coklat muda
  Color(0xFF78909C), // 11 – Abu biru muda
];

Color _cc(int i) => _kCC[i % _kCC.length];
Color _cl(int i) => _kCL[i % _kCL.length];

// ══════════════════════════════════════════════════════════════════════════════
//  ROOT
// ══════════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashState();
}

class _DashState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _tab = 0;

  late final AnimationController _chartAnim;
  late final Animation<double> _chartProg;
  late final AnimationController _cardAnim;
  late final Animation<double> _cardProg;

  @override
  void initState() {
    super.initState();
    _chartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _chartProg = CurvedAnimation(
      parent: _chartAnim,
      curve: Curves.easeOutCubic,
    );

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardProg = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut);

    _chartAnim.forward();
    _cardAnim.forward();
  }

  @override
  void dispose() {
    _chartAnim.dispose();
    _cardAnim.dispose();
    super.dispose();
  }

  void _switchTab(int t) {
    if (t == _tab) return;
    _chartAnim.reset();
    setState(() => _tab = t);
    _chartAnim.forward();
  }

  void _go(int index) => Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, a, __) => MainShell(initialIndex: index),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 230),
    ),
  );

  double get _totalJual =>
      AppData().transaksiList.fold(0.0, (s, t) => s + t.totalPenjualan);

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Column(
                children: [
                  _statsGrid(),
                  const SizedBox(height: 14),
                  _chartPanel(),
                  const SizedBox(height: 14),
                  _detailTable(),
                  const SizedBox(height: 14),
                  _menuGrid(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF082060), Color(0xFF1045BB), Color(0xFF1D82EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: _disc(140, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            right: 50,
            top: 28,
            child: _disc(55, Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            left: -20,
            bottom: -24,
            child: _disc(88, Colors.white.withValues(alpha: 0.04)),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 16,
              right: 16,
              bottom: 18,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.waves_rounded,
                    color: Color(0xFF1045BB),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'DIGITAL STATISTIK PERIKANAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'SISTEM MANAJEMEN BUDIDAYA',
                        style: TextStyle(color: Colors.white60, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                _profileBtn(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disc(double r, Color c) => Container(
    width: r,
    height: r,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _profileBtn() {
    final user = AuthData().currentUser;
    return GestureDetector(
      onTap: () =>
          showDialog(context: context, builder: (_) => const ProfileDialog()),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: user != null
            ? CircleAvatar(
                radius: 11,
                backgroundColor: Colors.white,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1045BB),
                  ),
                ),
              )
            : const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  KARTU STATISTIK
  // ══════════════════════════════════════════════════════════════════════════
  Widget _statsGrid() {
    final d = AppData();

    // ── Sama persis dengan keuangan.dart ────────────────────────────────────
    // Total Pemasukan = total penjualan dari transaksiList (bukan catatanKeuangan)
    final totalPemasukan = _totalJual;
    // Total Pengeluaran = dari catatanKeuanganList pengeluaran
    final totalPengeluaran = d.totalPengeluaran;
    // Arus Kas Bersih = total penjualan - total pengeluaran
    final arusKas = totalPemasukan - totalPengeluaran;

    // Total jenis ikan unik yang pernah tercatat di seluruh transaksi
    final Set<String> jenisIkanSet = {};
    for (final t in d.transaksiList) {
      for (final item in t.items) {
        jenisIkanSet.add(item.jenisIkan);
      }
    }
    final totalJenisIkan = jenisIkanSet.length;

    final cards = [
      _CD(
        'Total Jenis Ikan',
        '$totalJenisIkan jenis',
        Icons.set_meal_rounded,
        const Color(0xFF1045BB),
        const Color(0xFFDCEAFF),
        '$totalJenisIkan jenis',
        null,
      ),
      _CD(
        'Total Pemasukan',
        'Rp ${formatRupiah(totalPemasukan)}',
        Icons.account_balance_wallet_outlined,
        const Color(0xFF047857),
        const Color(0xFFCCFBF1),
        '',
        true,
      ),
      _CD(
        'Jumlah Transaksi',
        '${d.transaksiList.length} data',
        Icons.receipt_long_outlined,
        const Color(0xFFD84315),
        const Color(0xFFFFEDD5),
        '${d.transaksiList.length} total',
        null,
      ),
      _CD(
        'Arus Kas',
        'Rp ${formatRupiah(arusKas)}',
        Icons.swap_vert_circle_outlined,
        arusKas >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
        arusKas >= 0 ? const Color(0xFFDBF5E0) : const Color(0xFFFFE5E5),
        arusKas >= 0 ? 'Keuntungan' : 'Kerugian',
        arusKas >= 0,
      ),
    ];

    return AnimatedBuilder(
      animation: _cardProg,
      builder: (_, __) => Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatCard(cards[0], _cardProg.value)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(cards[1], _cardProg.value)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatCard(cards[2], _cardProg.value)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(cards[3], _cardProg.value)),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL GRAFIK
  // ══════════════════════════════════════════════════════════════════════════
  Widget _chartPanel() {
    const defs = [
      (
        Icons.bar_chart_rounded,
        'Grafik',
        'Grafik\nPenjualan',
        'Nilai per kategori',
      ),
      (
        Icons.trending_up_rounded,
        'Tren',
        'Tren Penjualan\n& Keuangan',
        'Pemasukan & pengeluaran per tanggal transaksi',
      ),
      (
        Icons.donut_large_rounded,
        'Proporsi',
        'Proporsi\nKategori',
        'Distribusi nilai penjualan',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        defs[_tab].$3,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0C1A5E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        defs[_tab].$4,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tabs
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: List.generate(3, (i) {
                      final active = _tab == i;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _switchTab(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: active ? kBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: kBlue.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  defs[i].$1,
                                  size: 13,
                                  color: active
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  defs[i].$2,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: active
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Area grafik
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 16),
            child: AnimatedBuilder(
              animation: _chartProg,
              builder: (_, __) {
                final h = _tab == 2
                    ? 280.0
                    : _tab == 1
                    ? 340.0
                    : 238.0;
                return SizedBox(
                  height: h,
                  child: _activeChart(_chartProg.value),
                );
              },
            ),
          ),

          // Legenda donut — hanya tampil jika ada data nyata
          if (_tab == 2 && _DonutChart.buildSegments().isNotEmpty) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            _donutLegend(),
          ],
        ],
      ),
    );
  }

  Widget _activeChart(double p) {
    switch (_tab) {
      case 0:
        return _BarChart(progress: p);
      case 1:
        return _LineChart(progress: p);
      default:
        return _DonutChart(progress: p);
    }
  }

  Widget _donutLegend() {
    final segs = _DonutChart.buildSegments();
    final total = segs.fold(0.0, (s, e) => s + e.value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: segs.asMap().entries.map((e) {
          final c = _cc(e.key);
          final pct = total > 0
              ? (e.value.value / total * 100).toStringAsFixed(1)
              : '0';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dot warna unik per kategori
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                '${e.value.label} ($pct%)',
                style: TextStyle(
                  fontSize: 11,
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TABEL DETAIL PENJUALAN PER JENIS IKAN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _detailTable() {
    // Agregasi per jenis ikan dari semua transaksi (maks 8)
    final Map<String, _FishDetail> fishMap = {};
    for (final t in AppData().transaksiList) {
      for (final item in t.items) {
        final existing = fishMap[item.jenisIkan];
        if (existing == null) {
          fishMap[item.jenisIkan] = _FishDetail(
            jenisIkan: item.jenisIkan,
            totalKg: item.jumlahKg,
            totalNilai: item.subtotal,
            hargaPerKg: item.hargaPerKg,
            jumlahEntry: 1,
          );
        } else {
          fishMap[item.jenisIkan] = _FishDetail(
            jenisIkan: item.jenisIkan,
            totalKg: existing.totalKg + item.jumlahKg,
            totalNilai: existing.totalNilai + item.subtotal,
            hargaPerKg: item.hargaPerKg,
            jumlahEntry: existing.jumlahEntry + 1,
          );
        }
      }
    }

    // Urut nilai terbesar, maks 8 baris
    final items = fishMap.values.toList()
      ..sort((a, b) => b.totalNilai.compareTo(a.totalNilai));
    if (items.length > 8) items.length = 8;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Judul ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detail Penjualan Terkini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0C1A5E),
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} jenis',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Garis pembatas ────────────────────────────────────────────────
          Container(height: 1, color: const Color(0xFFF0F0F8)),

          // ── Header kolom ──────────────────────────────────────────────────
          Container(
            color: const Color(0xFFF6F9FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Spacer ini TETAP dipakai untuk menjaga posisi kolom
                // Berat (kg) & Total (Rp) sejajar dengan data di bawahnya
                // (baris data punya avatar 38px + jarak 11px = 49px).
                // Teks "Jenis Ikan" digeser visual ke kiri lewat Transform.
                const SizedBox(width: 49),
                Expanded(
                  flex: 5,
                  child: Transform.translate(
                    // Geser murni visual (tidak mengubah layout flex lain)
                    // agar teks "Jenis Ikan" jatuh tepat di ujung kiri tabel.
                    offset: const Offset(-49, 0),
                    child: const Text(
                      'Jenis Ikan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF444466),
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Berat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF444466),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF444466),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Garis bawah header ────────────────────────────────────────────
          Container(height: 1, color: const Color(0xFFF0F0F8)),

          // ── Isi tabel: kosong atau data ───────────────────────────────────
          if (items.isEmpty)
            // Baris kosong persis seperti referensi gambar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'Belum ada transaksi',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                ),
              ),
            )
          else
            ...() {
              final maxV = items.map((i) => i.totalNilai).reduce(math.max);
              return items.asMap().entries.map((e) {
                final idx = e.key;
                final fish = e.value;
                final c = _cc(idx);
                final cl = _cl(idx);
                final isLast = idx == items.length - 1;
                final ratio = maxV > 0
                    ? (fish.totalNilai / maxV).clamp(0.05, 1.0)
                    : 0.0;
                final pct = maxV > 0
                    ? (fish.totalNilai / maxV * 100).toStringAsFixed(0)
                    : '0';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Avatar inisial ─────────────────────────────
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [c, cl],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.30),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                fish.jenisIkan[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),

                          // ── Nama ikan + harga + bar ────────────────────
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fish.jenisIkan,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: c,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rp ${formatRupiah(fish.hargaPerKg)}/kg · ${fish.jumlahEntry}x transaksi',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9999AA),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                // ── Progress bar proporsi nilai ──────────
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          color: c.withValues(alpha: 0.10),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: ratio,
                                          child: Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  c,
                                                  cl.withValues(alpha: 0.75),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Berat (angka + kg bertumpuk, di tengah) ────
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center, // Rata tengah vertikal
                              crossAxisAlignment: CrossAxisAlignment.center, // Rata tengah horizontal
                              children: [
                                Text(
                                  fish.totalKg % 1 == 0
                                      ? fish.totalKg.toInt().toString()
                                      : fish.totalKg.toStringAsFixed(1),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: c,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'kg',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Total (Rp + badge persentase) ──────────────
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rp ${formatRupiah(fish.totalNilai)}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: c,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: c,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFFF3F4FA),
                      ),
                  ],
                );
              }).toList();
            }(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MENU GRID  –  semua biru seragam seperti tampilan asli, lebih jelas
  // ══════════════════════════════════════════════════════════════════════════

  // Warna tombol: satu palet biru konsisten
  static const _btnBase = Color(0xFF1565C0); // biru tua (tombol)
  static const _btnTop = Color(0xFF1E88E5); // biru tengah
  static const _btnLight = Color(0xFF42A5F5); // biru cerah (highlight)
  static const _panelBg1 = Color(0xFF0A1E60);
  static const _panelBg2 = Color(0xFF0D47A1);

  Widget _menuGrid() {
    final menus = [
      _M(Icons.send_rounded, 'KIRIM', 0),
      _M(Icons.note_add_rounded, 'INPUT', 2),
      _M(Icons.access_time_rounded, 'RIWAYAT', 4),
      _M(Icons.receipt_long_rounded, 'LAPORAN\nTRANSAKSI', 3),
      _M(Icons.account_balance_wallet_rounded, 'LAPORAN\nKEUANGAN', 1),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_panelBg1, _panelBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _panelBg2.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          // Baris atas: 3 tombol
          Row(
            children: menus
                .take(3)
                .map(
                  (m) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _tile(m),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          // Baris bawah: 2 tombol lebih lebar
          Row(
            children: menus
                .skip(3)
                .map(
                  (m) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _tile(m, wide: true),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _tile(_M m, {bool wide = false}) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => _go(m.page),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: wide ? 17 : 14, horizontal: 6),
        decoration: BoxDecoration(
          // Semua tombol: gradien biru seragam, sedikit lebih terang di atas
          gradient: const LinearGradient(
            colors: [_btnTop, _btnBase],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _btnLight.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _btnBase.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon dalam lingkaran semi-transparan putih
            Container(
              padding: EdgeInsets.all(wide ? 10 : 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: Icon(m.icon, color: Colors.white, size: wide ? 28 : 24),
            ),
            const SizedBox(height: 8),
            Text(
              m.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildBottomBar() => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF071A4E), Color(0xFF0D47A1)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ),
    padding: EdgeInsets.only(
      top: 12,
      bottom: MediaQuery.of(context).padding.bottom + 12,
    ),
    child: const Text(
      'DASHBOARD',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: 4.5,
      ),
    ),
  );

  Widget _bottomBar() => _buildBottomBar();
}

// ══════════════════════════════════════════════════════════════════════════════
//  HELPER DATA CLASSES
// ══════════════════════════════════════════════════════════════════════════════
class _CD {
  final String title, value, badge;
  final IconData icon;
  final Color color, bg;
  final bool? up;
  const _CD(
    this.title,
    this.value,
    this.icon,
    this.color,
    this.bg,
    this.badge,
    this.up,
  );
}

class _M {
  final IconData icon;
  final String label;
  final int page;

  const _M(this.icon, this.label, this.page);
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA CLASS — Agregasi per jenis ikan untuk tabel detail
// ══════════════════════════════════════════════════════════════════════════════
class _FishDetail {
  final String jenisIkan;
  final double totalKg;
  final double totalNilai;
  final double hargaPerKg;
  final int jumlahEntry;
  const _FishDetail({
    required this.jenisIkan,
    required this.totalKg,
    required this.totalNilai,
    required this.hargaPerKg,
    required this.jumlahEntry,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  STAT CARD
// ══════════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final _CD d;
  final double anim;
  const _StatCard(this.d, this.anim);

  @override
  Widget build(BuildContext context) {
    final bC = d.up == null
        ? d.color
        : (d.up! ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C));

    return Transform.translate(
      offset: Offset(0, 18 * (1 - anim)),
      child: Opacity(
        opacity: anim.clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: d.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(d.icon, color: d.color, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bC.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.up != null) ...[
                          Icon(
                            d.up!
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 10,
                            color: bC,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          d.badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: bC,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                d.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8888AA),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                d.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: d.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget kosong bersama untuk semua jenis grafik ───────────────────────────
Widget _emptyChart(IconData icon, String pesan) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: const Color(0xFFDDE2F0)),
        const SizedBox(height: 12),
        Text(
          pesan,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFBBBBCC),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Data akan tampil setelah transaksi dicatat',
          style: TextStyle(fontSize: 11, color: Color(0xFFCCCCDD)),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  GRAFIK – BAR CHART
//  Gradient bar + nilai fade-in + label X 2-baris + bayangan blur
// ══════════════════════════════════════════════════════════════════════════════
class _BarChart extends StatelessWidget {
  final double progress;
  const _BarChart({required this.progress});

  // Agregasi nilai penjualan per JENIS IKAN (bukan per kategori).
  // Setiap batang = 1 jenis ikan dengan warna berbeda dari palet _kCC.
  static List<(String, double)> _data() {
    final map = <String, double>{};
    for (final t in AppData().transaksiList) {
      for (final item in t.items) {
        map[item.jenisIkan] = (map[item.jenisIkan] ?? 0) + item.subtotal;
      }
    }
    if (map.isEmpty) return const [];
    // Urut nilai terbesar di depan, tampilkan maks 8 jenis ikan
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => (e.key, e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data();
    if (d.isEmpty)
      return _emptyChart(Icons.bar_chart_rounded, 'Belum ada data transaksi');
    final max = d.map((e) => e.$2).reduce(math.max);
    return CustomPaint(
      painter: _BarPainter(d, max, progress),
      child: const SizedBox.expand(),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<(String, double)> data;
  final double maxVal, progress;
  _BarPainter(this.data, this.maxVal, this.progress);

  static const double _lp = 54, _rp = 14, _tp = 20, _bp = 44;

  @override
  void paint(Canvas canvas, Size sz) {
    final cw = sz.width - _lp - _rp;
    final ch = sz.height - _tp - _bp;
    final tp2 = TextPainter(textDirection: TextDirection.ltr);

    // Grid + Y labels
    final gp = Paint()
      ..color = const Color(0xFFEBEBF8)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = _tp + ch * (1 - i / 4);
      canvas.drawLine(Offset(_lp, y), Offset(sz.width - _rp, y), gp);
      final v = maxVal * i / 4;
      final l = v >= 1e6
          ? '${(v / 1e6).toStringAsFixed(1)}M'
          : v >= 1e3
          ? '${(v / 1e3).toStringAsFixed(0)}K'
          : '0';
      tp2.text = TextSpan(
        text: l,
        style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 9),
      );
      tp2.layout();
      tp2.paint(canvas, Offset(_lp - tp2.width - 6, y - tp2.height / 2));
    }

    if (data.isEmpty || maxVal == 0) return;
    final bw = cw / data.length * 0.55;
    final gap = (cw - bw * data.length) / (data.length + 1);

    for (int i = 0; i < data.length; i++) {
      final bh = ch * (data[i].$2 / maxVal) * progress;
      final x = _lp + gap * (i + 1) + bw * i;
      final y = _tp + ch - bh;
      final rect = Rect.fromLTWH(x, y, bw, bh);
      final c = _cc(i);
      final cL = _cl(i);

      if (bh > 1) {
        // Bayangan
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 3, y + 6, bw, bh),
            const Radius.circular(8),
          ),
          Paint()
            ..color = c.withValues(alpha: 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );

        // Bar gradient
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()
            ..shader = LinearGradient(
              colors: [c, cL.withValues(alpha: 0.65)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(rect),
        );

        // Highlight strip
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, bw * 0.26, bh),
            const Radius.circular(8),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.14),
        );

        // Nilai atas bar (fade in 72%+)
        if (progress > 0.72) {
          final op = ((progress - 0.72) / 0.28).clamp(0.0, 1.0);
          final v = data[i].$2;
          final vl = v >= 1e6
              ? '${(v / 1e6).toStringAsFixed(1)}M'
              : v >= 1e3
              ? '${(v / 1e3).toStringAsFixed(0)}K'
              : v.toStringAsFixed(0);
          tp2.text = TextSpan(
            text: vl,
            style: TextStyle(
              color: c.withValues(alpha: op),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          tp2.layout();
          tp2.paint(
            canvas,
            Offset(x + bw / 2 - tp2.width / 2, y - tp2.height - 4),
          );
        }
      }

      // Label X (selalu tampil, maksimal 2 baris)
      final parts = data[i].$1.split(' ');
      for (int li = 0; li < math.min(parts.length, 2); li++) {
        tp2.text = TextSpan(
          text: parts[li],
          style: const TextStyle(color: Color(0xFF777788), fontSize: 9),
        );
        tp2.layout();
        tp2.paint(
          canvas,
          Offset(x + bw / 2 - tp2.width / 2, _tp + ch + 7 + li * 12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter o) => o.progress != progress || o.data != data;
}

// ══════════════════════════════════════════════════════════════════════════════
//  TREN – DUAL LINE BEZIER CHART
//  Dua garis: Pemasukan/Penjualan (biru) & Pengeluaran (merah)
//  Toggle Harian (max 31) / Bulanan (max 12)
//  Legenda jelas, label X rapi, tooltip sentuh, ringkasan total di bawah
// ══════════════════════════════════════════════════════════════════════════════

// ── Model titik data ──────────────────────────────────────────────────────────
class _TrendPoint {
  /// Label singkat untuk sumbu-X: "dd/MM" (harian) atau "Jan" (bulanan)
  final String label;

  /// Label panjang untuk tooltip: "01 Jul 2025" atau "Juli 2025"
  final String labelPanjang;

  /// Pemasukan = total penjualan transaksi pada periode ini
  final double pemasukan;

  /// Pengeluaran = total catatan pengeluaran keuangan pada periode ini
  final double pengeluaran;

  const _TrendPoint(
    this.label,
    this.labelPanjang,
    this.pemasukan,
    this.pengeluaran,
  );

  double get total => pemasukan + pengeluaran;
  double get selisih => pemasukan - pengeluaran;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Sortir integer dari tanggal dd/MM/yyyy → yyyyMMdd
int _trendDateVal(String d) {
  try {
    final p = d.split('/');
    if (p.length == 3) {
      return int.parse(p[2]) * 10000 + int.parse(p[1]) * 100 + int.parse(p[0]);
    }
  } catch (_) {}
  return 0;
}

/// Format rupiah singkat: 1.250.000 → "1,25 Jt" | 850.000 → "850K" | 500 → "500"
String _rupSingkat(double v) {
  if (v == 0) return '0';
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}M';
  if (v >= 1e6)
    return '${(v / 1e6).toStringAsFixed(2).replaceAll('.00', '').replaceAll(RegExp(r'0$'), '')} Jt';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

/// Format rupiah penuh: 1250000 → "Rp 1.250.000"
String _rupPenuh(double v) => 'Rp ${formatRupiah(v)}';

const _bulanNama = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
const _bulanPanjang = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

// ── Bangun data HARIAN (max 31 hari terakhir berdasarkan data nyata) ──────────
List<_TrendPoint> _buildHarian() {
  final trxList = AppData().transaksiList;
  final keuList = AppData().catatanKeuanganList;

  if (trxList.isEmpty && keuList.isEmpty) return [];

  final Map<String, double> pMap = {};
  for (final t in trxList) {
    pMap[t.tanggal] = (pMap[t.tanggal] ?? 0) + t.totalPenjualan;
  }

  final Map<String, double> kMap = {};
  for (final k in keuList) {
    if (k.jenis == JenisKeuangan.pengeluaran) {
      kMap[k.tanggal] = (kMap[k.tanggal] ?? 0) + k.jumlah;
    }
  }

  final allDates = <String>{...pMap.keys, ...kMap.keys}.toList()
    ..sort((a, b) => _trendDateVal(a).compareTo(_trendDateVal(b)));

  final recent = allDates.length > 31
      ? allDates.sublist(allDates.length - 31)
      : allDates;

  return recent.map((d) {
    // label singkat: "03/07"
    String lbl = d;
    String lblPjg = d;
    try {
      final p = d.split('/');
      if (p.length == 3) {
        final dd = p[0].padLeft(2, '0');
        final mm = int.parse(p[1]);
        final yyyy = p[2];
        lbl = '$dd/${p[1].padLeft(2, '0')}';
        lblPjg =
            '$dd ${mm >= 1 && mm <= 12 ? _bulanPanjang[mm - 1] : p[1]} $yyyy';
      }
    } catch (_) {}
    return _TrendPoint(lbl, lblPjg, pMap[d] ?? 0, kMap[d] ?? 0);
  }).toList();
}

// ── Bangun data BULANAN (max 12 bulan terakhir) ───────────────────────────────
List<_TrendPoint> _buildBulanan() {
  final trxList = AppData().transaksiList;
  final keuList = AppData().catatanKeuanganList;

  if (trxList.isEmpty && keuList.isEmpty) return [];

  // Kunci: "MM/YYYY"
  final Map<String, double> pMap = {};
  for (final t in trxList) {
    try {
      final p = t.tanggal.split('/');
      if (p.length == 3) {
        final key = '${p[1].padLeft(2, '0')}/${p[2]}';
        pMap[key] = (pMap[key] ?? 0) + t.totalPenjualan;
      }
    } catch (_) {}
  }

  final Map<String, double> kMap = {};
  for (final k in keuList) {
    if (k.jenis == JenisKeuangan.pengeluaran) {
      try {
        final p = k.tanggal.split('/');
        if (p.length == 3) {
          final key = '${p[1].padLeft(2, '0')}/${p[2]}';
          kMap[key] = (kMap[key] ?? 0) + k.jumlah;
        }
      } catch (_) {}
    }
  }

  final allKeys = <String>{...pMap.keys, ...kMap.keys}.toList()
    ..sort((a, b) {
      try {
        final pa = a.split('/');
        final pb = b.split('/');
        final va = int.parse(pa[1]) * 100 + int.parse(pa[0]);
        final vb = int.parse(pb[1]) * 100 + int.parse(pb[0]);
        return va.compareTo(vb);
      } catch (_) {
        return 0;
      }
    });

  final recent = allKeys.length > 12
      ? allKeys.sublist(allKeys.length - 12)
      : allKeys;

  return recent.map((key) {
    final p = key.split('/');
    final m = int.tryParse(p[0]) ?? 1;
    final y = p.length > 1 ? p[1] : '';
    final lbl = m >= 1 && m <= 12 ? _bulanNama[m - 1] : key;
    final lblPjg = m >= 1 && m <= 12 ? '${_bulanPanjang[m - 1]} $y' : key;
    return _TrendPoint(lbl, lblPjg, pMap[key] ?? 0, kMap[key] ?? 0);
  }).toList();
}

// ── Widget utama: StatefulWidget dengan toggle + tooltip ─────────────────────
class _LineChart extends StatefulWidget {
  final double progress;
  const _LineChart({required this.progress});

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  bool _isHarian = true;
  int? _hoveredIndex; // indeks titik yang disentuh/di-hover

  List<_TrendPoint> get _pts => _isHarian ? _buildHarian() : _buildBulanan();

  void _switchMode(bool harian) {
    if (_isHarian == harian) return;
    setState(() {
      _isHarian = harian;
      _hoveredIndex = null;
    });
  }

  // Buka dialog fullscreen dengan grafik yang bisa diperbesar (InteractiveViewer)
  void _openZoom(
    BuildContext context,
    List<_TrendPoint> pts,
    double maxVal,
    double totalP,
    double totalK,
    double selisih,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => _ZoomChartDialog(
        pts: pts,
        maxVal: maxVal,
        isHarian: _isHarian,
        totalP: totalP,
        totalK: totalK,
        selisih: selisih,
      ),
    );
  }

  // Deteksi sentuhan → cari titik terdekat
  void _onTap(TapDownDetails details, List<_TrendPoint> pts, double chartW) {
    if (pts.isEmpty) return;
    const lp = _TrendPainter.lp;
    const rp = _TrendPainter.rp;
    final cw = chartW - lp - rp;
    final n = pts.length;
    final tapX = details.localPosition.dx;

    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < n; i++) {
      final x = lp + (n == 1 ? cw / 2 : i / (n - 1) * cw);
      final d = (tapX - x).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    setState(() {
      _hoveredIndex = (_hoveredIndex == best) ? null : best;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pts = _pts;
    final n = pts.length;

    if (pts.isEmpty) {
      return _emptyChart(Icons.trending_up_rounded, 'Belum ada data tren');
    }

    final maxP = n > 0 ? pts.map((e) => e.pemasukan).reduce(math.max) : 0.0;
    final maxK = n > 0 ? pts.map((e) => e.pengeluaran).reduce(math.max) : 0.0;
    final maxVal = math.max(maxP, maxK);

    final totalP = pts.fold(0.0, (s, e) => s + e.pemasukan);
    final totalK = pts.fold(0.0, (s, e) => s + e.pengeluaran);
    final selisih = totalP - totalK;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toggle Harian / Bulanan + tombol zoom ────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Text(
                _isHarian ? '$n hari terakhir' : '$n bulan terakhir',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF9999BB),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _TrendToggle(isHarian: _isHarian, onSwitch: _switchMode),
              const SizedBox(width: 8),
              // ── Tombol perbesar grafik ──────────────────────────────
              Tooltip(
                message: 'Perbesar grafik',
                child: InkWell(
                  onTap: () =>
                      _openZoom(context, pts, maxVal, totalP, totalK, selisih),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD0D8F0),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 18,
                      color: Color(0xFF1045BB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Area grafik (GestureDetector untuk tooltip) ───────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return GestureDetector(
                onTapDown: (d) => _onTap(d, pts, constraints.maxWidth),
                child: CustomPaint(
                  painter: _TrendPainter(
                    pts: pts,
                    maxVal: maxVal == 0 ? 1 : maxVal,
                    progress: widget.progress,
                    hoveredIndex: _hoveredIndex,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),

        // ── Tooltip sentuh ────────────────────────────────────────────────
        if (_hoveredIndex != null && _hoveredIndex! < pts.length)
          _TrendTooltip(pt: pts[_hoveredIndex!], isHarian: _isHarian)
        else
          // ── Legenda + ringkasan total ─────────────────────────────────
          _TrendLegend(totalP: totalP, totalK: totalK, selisih: selisih),
      ],
    );
  }
}

// ── Dialog fullscreen grafik yang bisa di-zoom & pan ─────────────────────────
class _ZoomChartDialog extends StatefulWidget {
  final List<_TrendPoint> pts;
  final double maxVal, totalP, totalK, selisih;
  final bool isHarian;

  const _ZoomChartDialog({
    required this.pts,
    required this.maxVal,
    required this.isHarian,
    required this.totalP,
    required this.totalK,
    required this.selisih,
  });

  @override
  State<_ZoomChartDialog> createState() => _ZoomChartDialogState();
}

class _ZoomChartDialogState extends State<_ZoomChartDialog> {
  int? _hoveredIndex;
  final _transformCtrl = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  void _onTap(TapDownDetails details) {
    final pts = widget.pts;
    if (pts.isEmpty) return;

    // Konversi posisi tap ke ruang lokal canvas (setelah transform)
    final m = _transformCtrl.value;
    final scaleX = m.getMaxScaleOnAxis();
    final tx = m.getTranslation().x;

    const lp = _TrendPainter.lp;
    const rp = _TrendPainter.rp;
    // Lebar canvas dalam dialog (layar penuh dikurangi padding)
    final screenW =
        (MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).size.width) -
        32;
    final cw = screenW - lp - rp;
    final n = pts.length;

    // Posisi tap dalam ruang canvas yang sudah discale
    final tapXLocal = (details.localPosition.dx - tx) / scaleX;

    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < n; i++) {
      final x = lp + (n == 1 ? cw / 2 : i / (n - 1) * cw);
      final d = (tapXLocal - x).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    setState(() {
      _hoveredIndex = (_hoveredIndex == best) ? null : best;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.pts;
    final n = pts.length;
    final isPos = widget.selisih >= 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0A1440),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar dialog ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isHarian
                            ? 'Tren Harian · $n hari'
                            : 'Tren Bulanan · $n bulan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Tombol reset zoom
                    TextButton.icon(
                      onPressed: _resetZoom,
                      icon: const Icon(
                        Icons.zoom_out_map_rounded,
                        size: 14,
                        color: Color(0xFF90AAFF),
                      ),
                      label: const Text(
                        'Reset',
                        style: TextStyle(
                          color: Color(0xFF90AAFF),
                          fontSize: 11,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // ── Petunjuk zoom ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pinch_rounded,
                      size: 13,
                      color: Color(0xFF6677AA),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Cubit untuk zoom · Geser untuk pan · Ketuk titik untuk detail',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Area grafik interaktif ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: ClipRect(
                    child: InteractiveViewer(
                      transformationController: _transformCtrl,
                      minScale: 1.0,
                      maxScale: 5.0,
                      constrained: true,
                      boundaryMargin: const EdgeInsets.all(40),
                      onInteractionUpdate: (d) {
                        setState(() {
                          _currentScale = _transformCtrl.value
                              .getMaxScaleOnAxis();
                        });
                      },
                      child: GestureDetector(
                        onTapDown: _onTap,
                        child: CustomPaint(
                          painter: _TrendPainter(
                            pts: pts,
                            maxVal: widget.maxVal == 0 ? 1 : widget.maxVal,
                            progress: 1.0,
                            hoveredIndex: _hoveredIndex,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Indikator skala zoom ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.zoom_in_rounded,
                      size: 13,
                      color: Color(0xFF4455AA),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_currentScale.toStringAsFixed(1)}×',
                      style: const TextStyle(
                        color: Color(0xFF6677AA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (_currentScale - 1.0) / 4.0,
                          backgroundColor: const Color(0xFF1A2560),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3355CC),
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tooltip titik aktif ─────────────────────────────────────
              if (_hoveredIndex != null && _hoveredIndex! < pts.length)
                _TrendTooltip(
                  pt: pts[_hoveredIndex!],
                  isHarian: widget.isHarian,
                )
              else
                // ── Legenda ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    children: [
                      // Dot biru
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1045BB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Pemasukan',
                        style: TextStyle(
                          color: Color(0xFF90AAFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _rupPenuh(widget.totalP),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Dot merah
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Pengeluaran',
                        style: TextStyle(
                          color: Color(0xFFFF8888),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _rupPenuh(widget.totalK),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // Badge surplus/defisit
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPos
                              ? const Color(0xFF1B3A1F)
                              : const Color(0xFF3A1B1B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPos
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPos
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 11,
                              color: isPos
                                  ? const Color(0xFF66BB6A)
                                  : const Color(0xFFEF5350),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _rupPenuh(widget.selisih.abs()),
                              style: TextStyle(
                                color: isPos
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFFEF5350),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle pill ───────────────────────────────────────────────────────────────
class _TrendToggle extends StatelessWidget {
  final bool isHarian;
  final void Function(bool harian) onSwitch;
  const _TrendToggle({required this.isHarian, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D8F0), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrendChip(
            label: 'Harian',
            active: isHarian,
            onTap: () => onSwitch(true),
          ),
          _TrendChip(
            label: 'Bulanan',
            active: !isHarian,
            onTap: () => onSwitch(false),
          ),
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TrendChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kBlue.withValues(alpha: 0.30),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF8888AA),
          ),
        ),
      ),
    );
  }
}

// ── Tooltip saat titik disentuh ───────────────────────────────────────────────
class _TrendTooltip extends StatelessWidget {
  final _TrendPoint pt;
  final bool isHarian;
  const _TrendTooltip({required this.pt, required this.isHarian});

  @override
  Widget build(BuildContext context) {
    final isPositive = pt.selisih >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A5E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tanggal / bulan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pt.labelPanjang,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHarian ? 'Data harian' : 'Data bulanan',
                  style: const TextStyle(
                    color: Color(0xFFAABBDD),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Pemasukan
          _TooltipVal(
            dot: const Color(0xFF4A90E2),
            label: 'Masuk',
            nilai: _rupPenuh(pt.pemasukan),
          ),
          const SizedBox(width: 10),
          // Pengeluaran
          _TooltipVal(
            dot: const Color(0xFFE05050),
            label: 'Keluar',
            nilai: _rupPenuh(pt.pengeluaran),
          ),
          const SizedBox(width: 10),
          // Selisih
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF1B5E20).withValues(alpha: 0.7)
                  : const Color(0xFFB71C1C).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  isPositive ? 'Untung' : 'Rugi',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  _rupPenuh(pt.selisih.abs()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TooltipVal extends StatelessWidget {
  final Color dot;
  final String label, nilai;
  const _TooltipVal({
    required this.dot,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFAABBDD), fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          nilai,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Legenda + ringkasan total (tampil saat tidak ada tooltip) ─────────────────
class _TrendLegend extends StatelessWidget {
  final double totalP, totalK, selisih;
  const _TrendLegend({
    required this.totalP,
    required this.totalK,
    required this.selisih,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = selisih >= 0;
    final badgeColor = isPos
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final badgeBg = isPos ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final badgeBorder = isPos
        ? const Color(0xFF81C784)
        : const Color(0xFFE57373);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Dot biru + Pemasukan ──────────────────────────────────────────
          Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Color(0xFF1045BB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pemasukan (Penjualan)',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF555577),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _rupPenuh(totalP),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1045BB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // ── Dot merah + Pengeluaran ───────────────────────────────────────
          Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengeluaran',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF555577),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _rupPenuh(totalK),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // ── Dorong badge ke kanan ─────────────────────────────────────────
          const Spacer(),

          // ── Badge keuntungan / defisit — sejajar dengan legenda ──────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeBorder, width: 0.9),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPos
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: badgeColor,
                ),
                const SizedBox(width: 5),
                Text(
                  _rupPenuh(selisih.abs()),
                  style: TextStyle(
                    fontSize: 12,
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CustomPainter: dual bezier line ──────────────────────────────────────────
class _TrendPainter extends CustomPainter {
  final List<_TrendPoint> pts;
  final double maxVal, progress;
  final int? hoveredIndex;

  const _TrendPainter({
    required this.pts,
    required this.maxVal,
    required this.progress,
    required this.hoveredIndex,
  });

  // Konstanta layout — public agar bisa diakses dari State
  static const double lp = 58; // kiri: ruang label Y
  static const double rp = 10; // kanan
  static const double tp = 20; // atas
  static const double bp = 40; // bawah: ruang label X (2 baris)

  static const _cBlue = Color(0xFF1045BB);
  static const _cRed = Color(0xFFD32F2F);
  static const _cBlueFill = Color(0x251045BB);
  static const _cRedFill = Color(0x25D32F2F);

  // ── Posisi X sebuah titik ─────────────────────────────────────────────────
  double _x(int i, double cw) =>
      lp + (pts.length <= 1 ? cw / 2 : i / (pts.length - 1) * cw);

  // ── Posisi Y sebuah nilai ─────────────────────────────────────────────────
  double _y(double val, double ch) => tp + ch * (1 - val / maxVal);

  // ── Offset titik ─────────────────────────────────────────────────────────
  Offset _pt(int i, double cw, double ch, List<double> vals) =>
      Offset(_x(i, cw), _y(vals[i], ch));

  // ── Kontrol bezier ────────────────────────────────────────────────────────
  Offset _c1(int i, double cw, double ch, List<double> vals) {
    final p0 = _pt(i, cw, ch, vals);
    final p1 = _pt(i + 1, cw, ch, vals);
    return Offset((p0.dx + p1.dx) / 2, p0.dy);
  }

  Offset _c2(int i, double cw, double ch, List<double> vals) {
    final p0 = _pt(i, cw, ch, vals);
    final p1 = _pt(i + 1, cw, ch, vals);
    return Offset((p0.dx + p1.dx) / 2, p1.dy);
  }

  // ── Titik di bezier pada t ────────────────────────────────────────────────
  Offset _bz(int i, double t, double cw, double ch, List<double> vals) {
    final p0 = _pt(i, cw, ch, vals);
    final p3 = _pt(i + 1, cw, ch, vals);
    final b1 = _c1(i, cw, ch, vals);
    final b2 = _c2(i, cw, ch, vals);
    final mt = 1 - t;
    return Offset(
      mt * mt * mt * p0.dx +
          3 * mt * mt * t * b1.dx +
          3 * mt * t * t * b2.dx +
          t * t * t * p3.dx,
      mt * mt * mt * p0.dy +
          3 * mt * mt * t * b1.dy +
          3 * mt * t * t * b2.dy +
          t * t * t * p3.dy,
    );
  }

  // ── Gambar satu seri ─────────────────────────────────────────────────────
  void _drawSeries(
    Canvas canvas,
    Size sz,
    double cw,
    double ch,
    List<double> vals,
    Color lineColor,
    Color fillColor,
    bool isBlue, // true=pemasukan(atas), false=pengeluaran(bawah)
  ) {
    final n = vals.length;
    if (n < 1) return;

    final drawTo = (progress * (n - 1)).clamp(0.0, (n - 1).toDouble());
    final full = drawTo.floor();
    final frac = drawTo - full;

    final Offset endPt = (frac > 0 && full < n - 1)
        ? _bz(full, frac, cw, ch, vals)
        : _pt(full, cw, ch, vals);

    // ── Area fill ─────────────────────────────────────────────────────────
    if (n > 1) {
      final fp = Path();
      fp.moveTo(_pt(0, cw, ch, vals).dx, tp + ch);
      fp.lineTo(_pt(0, cw, ch, vals).dx, _pt(0, cw, ch, vals).dy);
      for (int i = 0; i < full && i < n - 1; i++) {
        fp.cubicTo(
          _c1(i, cw, ch, vals).dx,
          _c1(i, cw, ch, vals).dy,
          _c2(i, cw, ch, vals).dx,
          _c2(i, cw, ch, vals).dy,
          _pt(i + 1, cw, ch, vals).dx,
          _pt(i + 1, cw, ch, vals).dy,
        );
      }
      if (frac > 0 && full < n - 1) {
        fp.cubicTo(
          _c1(full, cw, ch, vals).dx,
          _c1(full, cw, ch, vals).dy,
          _c2(full, cw, ch, vals).dx,
          _c2(full, cw, ch, vals).dy,
          endPt.dx,
          endPt.dy,
        );
      }
      fp.lineTo(endPt.dx, tp + ch);
      fp.close();

      canvas.drawPath(
        fp,
        Paint()
          ..shader = LinearGradient(
            colors: [
              lineColor.withValues(alpha: 0.20),
              lineColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, tp, sz.width, ch)),
      );

      // ── Garis bezier ───────────────────────────────────────────────────
      final lp2 = Path();
      lp2.moveTo(_pt(0, cw, ch, vals).dx, _pt(0, cw, ch, vals).dy);
      for (int i = 0; i < full && i < n - 1; i++) {
        lp2.cubicTo(
          _c1(i, cw, ch, vals).dx,
          _c1(i, cw, ch, vals).dy,
          _c2(i, cw, ch, vals).dx,
          _c2(i, cw, ch, vals).dy,
          _pt(i + 1, cw, ch, vals).dx,
          _pt(i + 1, cw, ch, vals).dy,
        );
      }
      if (frac > 0 && full < n - 1) {
        lp2.cubicTo(
          _c1(full, cw, ch, vals).dx,
          _c1(full, cw, ch, vals).dy,
          _c2(full, cw, ch, vals).dx,
          _c2(full, cw, ch, vals).dy,
          endPt.dx,
          endPt.dy,
        );
      }
      canvas.drawPath(
        lp2,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // ── Dots ──────────────────────────────────────────────────────────────
    for (int i = 0; i <= full && i < n; i++) {
      final p = _pt(i, cw, ch, vals);
      final isHovered = hoveredIndex == i;

      if (isHovered) {
        // Dot diperbesar saat hover
        canvas.drawCircle(
          p,
          11,
          Paint()..color = lineColor.withValues(alpha: 0.12),
        );
        canvas.drawCircle(
          p,
          8,
          Paint()..color = lineColor.withValues(alpha: 0.20),
        );
      }
      // Ring luar (glow)
      canvas.drawCircle(
        p,
        7,
        Paint()..color = lineColor.withValues(alpha: 0.14),
      );
      // Lingkaran putih
      canvas.drawCircle(p, 5.5, Paint()..color = Colors.white);
      // Dot warna utama
      canvas.drawCircle(p, 3.8, Paint()..color = lineColor);
      // Titik putih tengah
      canvas.drawCircle(p, 1.6, Paint()..color = Colors.white);

      // ── Label nilai di atas/bawah dot (setelah 75% animasi) ───────────
      if (progress > 0.75) {
        final op = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
        final v = vals[i];
        if (v > 0) {
          final lbl = _rupSingkat(v);
          final tp2 = TextPainter(textDirection: TextDirection.ltr)
            ..text = TextSpan(
              text: lbl,
              style: TextStyle(
                color: lineColor.withValues(alpha: op),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            )
            ..layout();

          // Pemasukan: nilai di atas dot; Pengeluaran: di bawah dot
          final yLabel = isBlue ? p.dy - tp2.height - 6 : p.dy + 8;
          tp2.paint(canvas, Offset(p.dx - tp2.width / 2, yLabel));
        }
      }
    }

    // Garis vertikal pada titik yang di-hover
    if (hoveredIndex != null && hoveredIndex! < n && hoveredIndex! <= full) {
      final hx = _x(hoveredIndex!, cw);
      canvas.drawLine(
        Offset(hx, tp),
        Offset(hx, tp + ch),
        Paint()
          ..color = const Color(0xFF0C1A5E).withValues(alpha: 0.12)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size sz) {
    final cw = sz.width - lp - rp;
    final ch = sz.height - tp - bp;
    final n = pts.length;
    final tp2 = TextPainter(textDirection: TextDirection.ltr);

    // ── Grid Y (4 garis) ──────────────────────────────────────────────────
    final gPaint = Paint()
      ..color = const Color(0xFFEAEAF5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = tp + ch * (1 - i / 4);
      canvas.drawLine(Offset(lp, y), Offset(sz.width - rp, y), gPaint);

      // Label Y: format "0", "100K", "1,2 Jt"
      final v = maxVal * i / 4;
      final lbl = _rupSingkat(v);
      tp2.text = TextSpan(
        text: lbl,
        style: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      tp2.layout();
      tp2.paint(canvas, Offset(lp - tp2.width - 6, y - tp2.height / 2));
    }

    // ── Label X ──────────────────────────────────────────────────────────
    if (progress > 0.45 && n > 0) {
      final op = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);

      // Lebar per titik — jika terlalu sempit, kurangi jumlah label
      final perPt = n <= 1 ? cw : cw / (n - 1);
      // Minimal lebar label ~26px agar tidak tumpang tindih
      final step = perPt < 26 ? (26 / perPt).ceil() : 1;

      for (int i = 0; i < n; i++) {
        final showThis = (i % step == 0) || (i == n - 1);
        if (!showThis) continue;

        final x = _x(i, cw);
        final labelColor = Color.fromRGBO(0x66, 0x66, 0x88, op);

        // Baris 1: label singkat (dd/MM atau nama bulan)
        tp2.text = TextSpan(
          text: pts[i].label,
          style: TextStyle(
            color: labelColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        );
        tp2.layout();
        tp2.paint(canvas, Offset(x - tp2.width / 2, tp + ch + 6));

        // Baris 2 (hanya jika tidak terlalu padat): garis X vertikal tipis
        canvas.drawLine(
          Offset(x, tp + ch),
          Offset(x, tp + ch + 4),
          Paint()
            ..color = Color.fromRGBO(0x99, 0x99, 0xBB, op * 0.5)
            ..strokeWidth = 1,
        );
      }
    }

    // ── Gambar seri (merah dulu → biru di atas) ───────────────────────────
    _drawSeries(
      canvas,
      sz,
      cw,
      ch,
      pts.map((e) => e.pengeluaran).toList(),
      _cRed,
      _cRedFill,
      false,
    );
    _drawSeries(
      canvas,
      sz,
      cw,
      ch,
      pts.map((e) => e.pemasukan).toList(),
      _cBlue,
      _cBlueFill,
      true,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter o) =>
      o.progress != progress ||
      o.pts != pts ||
      o.maxVal != maxVal ||
      o.hoveredIndex != hoveredIndex;
}

// ══════════════════════════════════════════════════════════════════════════════
//  PROPORSI – DONUT CHART
//  Sweep gradient + highlight arc + persen label + teks TOTAL di tengah
// ══════════════════════════════════════════════════════════════════════════════
class _SegData {
  final String label;
  final double value;
  const _SegData(this.label, this.value);
}

class _DonutChart extends StatelessWidget {
  final double progress;
  const _DonutChart({required this.progress});

  static List<_SegData> buildSegments() {
    final map = <String, double>{};
    for (final t in AppData().transaksiList) {
      map[t.kategori] = (map[t.kategori] ?? 0) + t.totalPenjualan;
    }
    if (map.isEmpty) return const [];
    return (map.entries.map((e) => _SegData(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
  }

  @override
  Widget build(BuildContext context) {
    final segs = buildSegments();
    if (segs.isEmpty) {
      return _emptyChart(Icons.donut_large_rounded, 'Belum ada data transaksi');
    }
    final total = segs.fold(0.0, (s, e) => s + e.value);
    return CustomPaint(
      painter: _DonutPainter(segs, total, progress),
      child: const SizedBox.expand(),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_SegData> segs;
  final double total, progress;
  _DonutPainter(this.segs, this.total, this.progress);

  @override
  void paint(Canvas canvas, Size sz) {
    if (segs.isEmpty || total == 0) return;

    final cx = sz.width / 2;
    final cy = sz.height / 2 - 8;
    final rad = math.min(cx - 12, cy - 12) * 0.88;

    double start = -math.pi / 2;

    for (int i = 0; i < segs.length; i++) {
      final sweep = 2 * math.pi * (segs[i].value / total) * progress;
      if (sweep < 0.001) {
        start += sweep;
        continue;
      }

      final mid = start + sweep / 2;
      final c = _cc(i);
      final cL = _cl(i);
      // Segmen terbesar sedikit "meloncat"
      final jut = i == 0 ? 9.0 : 0.0;
      final ox = math.cos(mid) * jut;
      final oy = math.sin(mid) * jut;
      final center = Offset(cx + ox, cy + oy);
      final rect = Rect.fromCircle(center: center, radius: rad);

      // Bayangan
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx + ox + 3, cy + oy + 4), radius: rad),
        start,
        sweep,
        true,
        Paint()
          ..color = c.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Segmen utama (sweep gradient)
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: [c, cL],
            tileMode: TileMode.clamp,
          ).createShader(rect),
      );

      // Garis pemisah putih
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );

      // Inner arc highlight
      if (sweep > 0.25) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: rad * 0.93),
          start + 0.07,
          (sweep - 0.14).clamp(0.0, sweep),
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.18)
            ..strokeWidth = rad * 0.14
            ..style = PaintingStyle.stroke,
        );
      }

      // Label persen (segmen > 7%, fade in 76%+)
      if (segs[i].value / total > 0.07 && progress > 0.76) {
        final op = ((progress - 0.76) / 0.24).clamp(0.0, 1.0);
        final lr = rad * 0.67;
        final lx = center.dx + math.cos(mid) * lr;
        final ly = center.dy + math.sin(mid) * lr;
        final pct = (segs[i].value / total * 100).toStringAsFixed(0);
        final tp = TextPainter(
          text: TextSpan(
            text: '$pct%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: op),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }

      start += sweep;
    }

    // Lubang putih donut
    canvas.drawCircle(
      Offset(cx, cy),
      rad * 0.49,
      Paint()..color = Colors.white,
    );

    // Cincin dalam tipis
    canvas.drawCircle(
      Offset(cx, cy),
      rad * 0.49,
      Paint()
        ..color = const Color(0xFFE8EDF8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Teks tengah (fade in 58%+)
    if (progress > 0.58) {
      final op = ((progress - 0.58) / 0.42).clamp(0.0, 1.0);
      void draw(String text, double fs, FontWeight fw, double dy) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: const Color(0xFF0C1A5E).withValues(alpha: op),
              fontSize: fs,
              fontWeight: fw,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy + dy - tp.height / 2));
      }

      draw('TOTAL', 9.5, FontWeight.w600, -14);
      final tl = total >= 1e6
          ? 'Rp ${(total / 1e6).toStringAsFixed(2)}M'
          : 'Rp ${(total / 1e3).toStringAsFixed(0)}K';
      draw(tl, 12, FontWeight.w900, 2);
      draw('penjualan', 8.5, FontWeight.w400, 17);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) =>
      o.progress != progress || o.segs != segs;
}