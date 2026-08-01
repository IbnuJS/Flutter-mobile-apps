// ═══════════════════════════════════════════════════════════════════════════════
//  keuangan.dart
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_data.dart';
import 'data/local/local_data_manager.dart';

class LaporanKeuanganPage extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const LaporanKeuanganPage({super.key, this.onNavigate});

  @override
  State<LaporanKeuanganPage> createState() => _LaporanKeuanganPage();
}

class _LaporanKeuanganPage extends State<LaporanKeuanganPage> {
  bool _showForm = false;
  // Bagian “Catat Pemasukan” dihapus: hanya pengeluaran.
  JenisKeuangan _jenis = JenisKeuangan.pengeluaran;

  final _keteranganCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    _jumlahCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    // ── Validasi field ────────────────────────────────────────────────────────
    if (_keteranganCtrl.text.trim().isEmpty) {
      _snack('Mohon isi keterangan pengeluaran', isError: true);
      return;
    }
    if (_jumlahCtrl.text.isEmpty) {
      _snack('Mohon isi jumlah pengeluaran', isError: true);
      return;
    }
    if (_tanggalCtrl.text.isEmpty) {
      _snack('Mohon pilih tanggal pengeluaran', isError: true);
      return;
    }

    final jumlah =
        double.tryParse(
          _jumlahCtrl.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;

    if (jumlah <= 0) {
      _snack('Jumlah pengeluaran harus lebih dari 0', isError: true);
      return;
    }

    // ── Simpan data ───────────────────────────────────────────────────────────
    final catatan = CatatanKeuangan(
      id: 'KEU${DateTime.now().millisecondsSinceEpoch}',
      keterangan: _keteranganCtrl.text.trim(),
      jumlah: jumlah,
      tanggal: _tanggalCtrl.text,
      jenis: JenisKeuangan.pengeluaran,
    );

    // [FIX] Selalu pakai LocalDataManager — tidak ada lagi percabangan uid.
    // LocalDataManager.tambahCatatanKeuangan() sudah:
    //   1. Cek uid (dari AppData().currentUser yang diset AuthData.login()).
    //   2. Simpan ke SQLite terlebih dahulu (source of truth).
    //   3. Baru update AppData in-memory.
    // Jika uid null (tidak mungkin terjadi di sini karena user sudah login),
    // LDM akan log error dan tidak menyimpan ke mana pun — konsisten.
    await LocalDataManager.tambahCatatanKeuangan(catatan);

    // ── PERBAIKAN UTAMA: setState() wajib dipanggil SETELAH await selesai ────
    // Sebelumnya setState() tidak menyebabkan rebuild list karena dipanggil
    // sebelum data benar-benar masuk ke AppData. Sekarang urutan sudah benar.
    if (!mounted) return;
    setState(() {
      _showForm = false;
      _keteranganCtrl.clear();
      _jumlahCtrl.clear();
      _tanggalCtrl.clear();
    });

    _snack('Catatan pengeluaran berhasil disimpan! Rp ${formatRupiah(jumlah)}');
  }

  void _openEdit(CatatanKeuangan c) {
    showDialog(
      context: context,
      builder: (_) =>
          _EditKeuanganDialog(catatan: c, onSaved: () => setState(() {})),
    );
  }

  void _hapus(CatatanKeuangan c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Color.fromARGB(255, 255, 13, 13),
              size: 22,
            ),
            SizedBox(width: 8),
            Text('Hapus Catatan', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Hapus catatan "${c.keterangan}"?\nTindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await LocalDataManager.hapusCatatanKeuangan(c.id);
              if (!mounted) return;
              Navigator.pop(ctx);
              setState(() {});
              _snack('Catatan berhasil dihapus', isError: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: kSnackTextStyle),
        backgroundColor: isError ? kRed : kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = AppData();

    // Total pemasukan dihitung dari total transaksi (penjualan ikan).
    final totalTransaksi = data.transaksiList.fold<double>(
      0,
      (s, t) => s + t.totalPenjualan,
    );
    // Total pengeluaran berasal dari catatan keuangan pengeluaran.
    final totalPengeluaran = data.totalPengeluaran;
    // Arus kas bersih = total transaksi - total pengeluaran.
    final arusKasBersih = totalTransaksi - totalPengeluaran;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary cards ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: KeuanganSummaryCard(
                        title: 'Total Pemasukan',
                        value: formatRupiah(totalTransaksi),
                        color: kGreen,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KeuanganSummaryCard(
                        title: 'Total Pengeluaran',
                        value: formatRupiah(totalPengeluaran),
                        color: kRed,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                KeuanganSummaryCard(
                  title: 'Arus Kas Bersih',
                  value: formatRupiah(arusKasBersih),
                  color: arusKasBersih >= 0 ? kGreen : kRed,
                  icon: Icons.account_balance_wallet_rounded,
                  isWide: true,
                ),

                const SizedBox(height: 12),

                // ── DISTRIBUSI — sesuai permintaan: TIDAK menampilkan Jenis Ikan & Transaksi ──
                // Distribusi catatan keuangan: keterangan pemasukan/pengeluaran
                const _DistribusiBoxOnlyPemasukanPengeluaran(),

                const SizedBox(height: 16),

                // ── Header catatan ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Catat Keuangan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kBlue,
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _showForm = !_showForm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _showForm ? Colors.grey : kBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showForm ? Icons.close : Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showForm
                                    ? 'Batal'
                                    : 'Tambah Catatan Pengeluaran',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_showForm) _buildForm(),
                const SizedBox(height: 8),
                _buildCatatanList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catat Pengeluaran',
            style: TextStyle(fontWeight: FontWeight.bold, color: kBlue),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: kRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pengeluaran',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Text(
            'Keterangan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _keteranganCtrl,
            decoration: buildInputDecoration(hint: 'Keterangan transaksi'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Jumlah (Rp)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _jumlahCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              // Hanya izinkan angka (opsional titik/koma desimal) untuk jumlah
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
            ],
            decoration: buildInputDecoration(hint: 'Masukkan jumlah'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tanggal',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _tanggalCtrl,
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );

              if (picked != null) {
                setState(() {
                  _tanggalCtrl.text =
                      '${picked.day.toString().padLeft(2, '0')}/'
                      '${picked.month.toString().padLeft(2, '0')}/'
                      '${picked.year}';
                });
              }
            },
            decoration: buildInputDecoration(
              hint: 'Pilih tanggal, bulan, dan tahun',
              suffix: const Icon(Icons.calendar_today, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Simpan Catatan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanList() {
    // Halaman ini khusus untuk catatan pengeluaran.
    final list = AppData().catatanKeuanganList
        .where((c) => c.jenis == JenisKeuangan.pengeluaran)
        .toList();

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .receipt_long_outlined, // Bisa juga diganti Icons.money_off_rounded jika lebih cocok
                color: Colors.grey.shade300,
                size: 48,
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum ada catatan pengeluaran',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight
                      .bold, // Menambahkan bold agar mirip dengan halaman transaksi
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Tambah Catatan Pengeluaran untuk memulai',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ), // Sedikit membesarkan ukuran font sub-teks
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ── Header jumlah data ────────────────────────────────────────────────────
    final totalNilai = list.fold<double>(0, (s, c) => s + c.jumlah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge ringkasan: jumlah catatan + total rupiah
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kRed.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.list_alt_rounded, color: kRed, size: 16),
              const SizedBox(width: 6),
              Text(
                '${list.length} catatan pengeluaran',
                style: const TextStyle(
                  fontSize: 12,
                  color: kRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Total: Rp ${formatRupiah(totalNilai)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: kRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        // ── Kartu per catatan ────────────────────────────────────────────────
        ...list.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border(left: BorderSide(color: kRed, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Baris atas: ikon + keterangan + nilai rupiah ──────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ikon pengeluaran
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kRed.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: kRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Keterangan + tanggal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.keterangan,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  c.tanggal,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── PERBAIKAN UTAMA: Nilai rupiah ditampilkan di sini ─
                      // Sebelumnya kolom ini hanya berisi tombol Edit/Hapus,
                      // nilai rupiah sama sekali tidak ditampilkan pada kartu.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: kRed.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kRed,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rp ${formatRupiah(c.jumlah)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: kRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Container(height: 1, color: const Color(0xFFF2F2F8)),
                  const SizedBox(height: 8),

                  // ── Baris bawah: tombol Edit & Hapus ─────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tombol Edit
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _openEdit(c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kBlue.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kBlue.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: kBlue,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: kBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Hapus
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _hapus(c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kRed.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kRed.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: kRed,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Hapus',
                                  style: TextStyle(
                                    color: kRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Distribusi: Pemasukan terhubung ke transaksiList, Pengeluaran dari catatanKeuanganList
class _DistribusiBoxOnlyPemasukanPengeluaran extends StatelessWidget {
  const _DistribusiBoxOnlyPemasukanPengeluaran();

  @override
  Widget build(BuildContext context) {
    final data = AppData();

    // ── Pemasukan — terhubung ke total transaksi penjualan ────────────────────
    final jumlahTransaksi = data.transaksiList.length;
    final totalNilaiTransaksi = data.transaksiList.fold<double>(
      0,
      (s, t) => s + t.totalPenjualan,
    );

    // ── Pengeluaran — dari catatan keuangan pengeluaran ───────────────────────
    final jumlahPengeluaran = data.catatanKeuanganList
        .where((c) => c.jenis == JenisKeuangan.pengeluaran)
        .length;
    final totalNilaiPengeluaran = data.totalPengeluaran;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: kBlue, size: 20),
              SizedBox(width: 6),
              Text(
                'Distribusi Catatan Keuangan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kBlue,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Pemasukan',
                  value: '$jumlahTransaksi',
                  satuan: 'Transaksi',
                  subLabel: 'Rp ${formatRupiah(totalNilaiTransaksi)}',
                  color: kGreen,
                  bgColor: const Color.fromARGB(255, 228, 249, 228),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Pengeluaran',
                  value: '$jumlahPengeluaran',
                  satuan: 'Catatan',
                  subLabel: 'Rp ${formatRupiah(totalNilaiPengeluaran)}',
                  color: kRed,
                  bgColor: kRedBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String satuan;
  final String? subLabel; // total nilai rupiah (opsional)
  final Color color;
  final Color bgColor;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.satuan,
    this.subLabel,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: ' $satuan',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total nilai rupiah — terhubung ke sumber data yang sama
                if (subLabel != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditKeuanganDialog extends StatefulWidget {
  final CatatanKeuangan catatan;
  final VoidCallback onSaved;

  const _EditKeuanganDialog({required this.catatan, required this.onSaved});

  @override
  State<_EditKeuanganDialog> createState() => _EditKeuanganDialogState();
}

class _EditKeuanganDialogState extends State<_EditKeuanganDialog> {
  late JenisKeuangan _jenis;
  late final TextEditingController _keteranganCtrl;
  late final TextEditingController _jumlahCtrl;
  late final TextEditingController _tanggalCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.catatan;
    _jenis = c.jenis;
    _keteranganCtrl = TextEditingController(text: c.keterangan);
    _jumlahCtrl = TextEditingController(text: c.jumlah.toStringAsFixed(0));
    _tanggalCtrl = TextEditingController(text: c.tanggal);
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    _jumlahCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_keteranganCtrl.text.isEmpty ||
        _jumlahCtrl.text.isEmpty ||
        _tanggalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Mohon lengkapi semua catatan',
              style: kSnackTextStyle,
            ),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            margin: EdgeInsets.fromLTRB(14, 0, 14, 14),
          ),
        );
      return;
    }

    final jumlah =
        double.tryParse(
          _jumlahCtrl.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;

    await LocalDataManager.editCatatanKeuangan(
      widget.catatan.id,
      CatatanKeuangan(
        id: widget.catatan.id,
        keterangan: _keteranganCtrl.text,
        jumlah: jumlah,
        tanggal: _tanggalCtrl.text,
        jenis: _jenis,
      ),
    );

    widget.onSaved();
    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Catatan berhasil diperbarui!', style: kSnackTextStyle),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          margin: EdgeInsets.fromLTRB(14, 0, 14, 14),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBlueBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded, color: kBlue, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Edit Catatan Keuangan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kBlue,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: kRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pengeluaran',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Keterangan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _keteranganCtrl,
              decoration: buildInputDecoration(hint: 'Keterangan...'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Jumlah (Rp)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _jumlahCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                // Hanya izinkan angka (dengan titik/koma desimal opsional)
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]*')),
              ],
              decoration: buildInputDecoration(hint: 'Jumlah...'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tanggal',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _tanggalCtrl,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2060),
                );
                if (picked != null) {
                  setState(() {
                    _tanggalCtrl.text =
                        '${picked.day.toString().padLeft(2, '0')}/'
                        '${picked.month.toString().padLeft(2, '0')}/'
                        '${picked.year}';
                  });
                }
              },
              decoration: buildInputDecoration(
                hint: 'Pilih tanggal, bulan, tahun',
                suffix: const Icon(Icons.calendar_today, size: 18),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KeuanganSummaryCard extends StatelessWidget {
  final String title, value;
  final Color color;
  final IconData icon;
  final bool isWide;

  const KeuanganSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'Rp $value',
                  style: TextStyle(
                    fontSize: isWide ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: color,
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
