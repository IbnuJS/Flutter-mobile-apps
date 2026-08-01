// ═══════════════════════════════════════════════════════════════════════════════
//  transaksi.dart
//  Halaman Laporan Transaksi (index 3 di MainShell)
//  Fitur: Daftar transaksi dengan detail, edit, dan hapus
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_data.dart';
import 'data/local/local_data_manager.dart';

class LaporanTransaksiPage extends StatefulWidget {
  const LaporanTransaksiPage({super.key});

  @override
  State<LaporanTransaksiPage> createState() => _LaporanTransaksiPageState();
}

class _LaporanTransaksiPageState extends State<LaporanTransaksiPage> {
  final _searchCtrl = TextEditingController();
  String _filterKategori = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Transaksi> get _filtered {
    var list = List<Transaksi>.from(AppData().transaksiList);
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isNotEmpty) {
      list = list
          .where(
            (t) =>
                t.id.toLowerCase().contains(q) ||
                t.kategori.toLowerCase().contains(q) ||
                t.items.any((i) => i.jenisIkan.toLowerCase().contains(q)),
          )
          .toList();
    }

    if (_filterKategori.isNotEmpty) {
      list = list.where((t) => t.kategori == _filterKategori).toList();
    }

    return list;
  }

  void _hapus(Transaksi t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: kRed, size: 22),
            SizedBox(width: 8),
            Text('Hapus Transaksi', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Hapus transaksi "${t.id}"?\nTindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await LocalDataManager.hapusTransaksi(t.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Transaksi berhasil dihapus',
                    style: kSnackTextStyle,
                  ),
                  backgroundColor: kGreen,

                  behavior: SnackBarBehavior.floating,
                ),
              );
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    // Total nilai transaksi: jumlahkan subtotal harga tiap item (jenis ikan).
    final totalNilai = filtered.fold<double>(0, (s, t) => s + t.totalPenjualan);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Transaksi',
                      value: '${AppData().transaksiList.length} data',
                      icon: Icons.receipt_long_rounded,
                      color: kBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Nilai',
                      value: 'Rp ${formatRupiah(totalNilai)}',
                      icon: Icons.attach_money_rounded,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari ID transaksi dan Jenis Ikan',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      const Text(
                        'Tidak ada transaksi',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _TransaksiCard(
                    key: ValueKey(filtered[i].id),
                    transaksi: filtered[i],
                    onHapus: () => _hapus(filtered[i]),
                    onRefresh: () => setState(() {}),
                  ),
                ),
        ),

        if (filtered.isNotEmpty)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF082060), Color(0xFF1045BB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ${filtered.length} Transaksi',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Rp ${formatRupiah(totalNilai)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (_) {
                    final jenisSet = <String>{};
                    for (final t in filtered) {
                      for (final item in t.items) {
                        jenisSet.add(item.jenisIkan);
                      }
                    }
                    final totalJenis = jenisSet.length;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Jenis Ikan',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$totalJenis Jenis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ChipFilter({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? kBlue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? kBlue : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransaksiCard extends StatefulWidget {
  final Transaksi transaksi;
  final VoidCallback onHapus;
  final VoidCallback onRefresh;

  const _TransaksiCard({
    super.key,
    required this.transaksi,
    required this.onHapus,
    required this.onRefresh,
  });

  @override
  State<_TransaksiCard> createState() => _TransaksiCardState();
}

class _TransaksiCardState extends State<_TransaksiCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaksi;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlueBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: kBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kBlue,
                              fontSize: 13.5,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 11,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                t.tanggal,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp ${formatRupiah(t.totalPenjualan)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBlue,
                            fontSize: 13,
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: kBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...t.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: kBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.jenisIkan,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.jumlahKg} kg × Rp ${formatRupiah(item.hargaPerKg)}/kg',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${formatRupiah(item.subtotal)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _StatItem(
                        label: 'Jenis Ikan',
                        value: '${t.totalIkan}',
                        icon: Icons.set_meal_rounded,
                      ),
                      _StatItem(
                        label: 'Total Berat',
                        value: '${t.totalBerat} kg',
                        icon: Icons.scale_rounded,
                      ),
                      _StatItem(
                        label: 'Rata-rata Harga',
                        value: 'Rp ${formatRupiah(_avgHargaKg(t))}/kg',
                        icon: Icons.price_change_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _tampilkanDialogEdit(context, t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: kBlue,
                                  size: 15,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: kBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onHapus,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kRed.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: kRed,
                                  size: 15,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Hapus',
                                  style: TextStyle(
                                    color: kRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
          ],
        ],
      ),
    );
  }

  double _avgHargaKg(Transaksi t) {
    final totalBerat = t.totalBerat;
    if (totalBerat <= 0) return 0;
    return t.totalPenjualan / totalBerat;
  }

  void _tampilkanDialogEdit(BuildContext context, Transaksi t) async {
    final tanggalCtrl = TextEditingController(text: t.tanggal);
    final kategoriCtrl = TextEditingController(text: t.kategori);

    final jenisC = <TextEditingController>[];

    final beratC = <TextEditingController>[];
    final hargaC = <TextEditingController>[];

    for (final item in t.items) {
      jenisC.add(TextEditingController(text: item.jenisIkan));
      beratC.add(TextEditingController(text: item.jumlahKg.toString()));
      hargaC.add(TextEditingController(text: item.hargaPerKg.toString()));
    }

    void disposeControllers() {
      tanggalCtrl.dispose();
      kategoriCtrl.dispose();
      for (final c in jenisC) {
        c.dispose();
      }
      for (final c in beratC) {
        c.dispose();
      }
      for (final c in hargaC) {
        c.dispose();
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            List<Widget> entryWidgets() {
              return List.generate(jenisC.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ikan #${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kBlue,
                                fontSize: 13,
                              ),
                            ),
                            if (jenisC.length > 1)
                              IconButton(
                                tooltip: 'Hapus jenis ikan',
                                onPressed: () {
                                  // PERBAIKAN BUG: sebelumnya dispose()
                                  // dipanggil DI DALAM setStateDialog()
                                  // sebelum rebuild terjadi — padahal
                                  // TextField untuk entri ini masih
                                  // terpasang ke controller saat itu,
                                  // menyebabkan crash yang sama seperti
                                  // di tombol Batal/Simpan (lihat catatan
                                  // di atas). Sekarang: controller hanya
                                  // dikeluarkan dari list saat setState
                                  // (memicu rebuild yang menghapus
                                  // TextField-nya), lalu di-dispose SETELAH
                                  // frame berikutnya saat widget-nya sudah
                                  // benar-benar hilang dari tree.
                                  final removedJenis = jenisC[i];
                                  final removedBerat = beratC[i];
                                  final removedHarga = hargaC[i];
                                  setStateDialog(() {
                                    jenisC.removeAt(i);
                                    beratC.removeAt(i);
                                    hargaC.removeAt(i);
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    removedJenis.dispose();
                                    removedBerat.dispose();
                                    removedHarga.dispose();
                                  });
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: kRed,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: jenisC[i],
                          decoration: buildInputDecoration(hint: 'Jenis ikan'),
                          onChanged: (_) => setStateDialog(() {}),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: beratC[i],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  // Hanya izinkan angka (opsional titik koma) untuk input jumlah/berat.
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]*'),
                                  ),
                                ],
                                decoration: buildInputDecoration(
                                  hint: 'Berat (kg)',
                                ),
                                onChanged: (_) => setStateDialog(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: hargaC[i],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  // Hanya izinkan angka (opsional titik koma) untuk input harga.
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]*'),
                                  ),
                                ],
                                decoration: buildInputDecoration(
                                  hint: 'Harga per kg',
                                ),
                                onChanged: (_) => setStateDialog(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.edit_outlined, color: kBlue),
                  SizedBox(width: 8),
                  Text('Edit Transaksi'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: tanggalCtrl,
                      readOnly: true,
                      decoration: buildInputDecoration(hint: 'Tanggal'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2060),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            tanggalCtrl.text =
                                '${picked.day.toString().padLeft(2, '')}/'
                                '${picked.month.toString().padLeft(2, '')}/'
                                '${picked.year}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Kolom kategori dihapus sesuai permintaan.
                    // Kategori dipersiapkan/diisi dari data input lain.
                    // (Tidak lagi menampilkan TextField "Kategori" di dialog edit.)
                    const SizedBox.shrink(),
                    const SizedBox(height: 12),
                    const Text(
                      'Jenis ikan & input harga',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entryWidgets(),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            jenisC.add(TextEditingController(text: ''));
                            beratC.add(TextEditingController(text: ''));
                            hargaC.add(TextEditingController(text: ''));
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: kBlueBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: kBlue, size: 18),
                              SizedBox(width: 8),
                              Text('Tambah jenis ikan'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // PERBAIKAN BUG: Navigator.pop() DULU, baru dispose
                    // controller SETELAH frame berikutnya. Sebelumnya
                    // disposeControllers() dipanggil SEBELUM dialog
                    // benar-benar tertutup, padahal TextField di dalam
                    // dialog masih aktif menempel ke controller tersebut —
                    // menyebabkan crash "_dependents.isEmpty" karena widget
                    // yang masih hidup kehilangan controllernya secara tiba-tiba.
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => disposeControllers(),
                    );
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final items = <TransaksiItem>[];
                    for (int i = 0; i < jenisC.length; i++) {
                      final jenis = jenisC[i].text.trim();
                      final berat = double.tryParse(beratC[i].text) ?? 0;
                      final harga = double.tryParse(hargaC[i].text) ?? 0;
                      if (jenis.isEmpty || berat <= 0 || harga <= 0) continue;

                      items.add(
                        TransaksiItem(
                          jenisIkan: jenis,
                          jumlahKg: berat,
                          hargaPerKg: harga,
                        ),
                      );
                    }

                    // Kategori tidak lagi wajib diisi (kolom kategori dihapus dari dialog edit).
                    if (items.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lengkapi item ikan',
                              style: kSnackTextStyle,
                            ),
                            backgroundColor: kRed,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            margin: EdgeInsets.fromLTRB(14, 0, 14, 14),
                          ),
                        );
                      return;
                    }

                    final updated = Transaksi(
                      id: t.id,
                      tanggal: tanggalCtrl.text,
                      kategori: kategoriCtrl.text.trim(),
                      items: items,
                    );

                    await LocalDataManager.editTransaksi(t.id, updated);
                    // PERBAIKAN BUG: urutan dibalik — pop dialog DULU,
                    // baru dispose controller SETELAH frame berikutnya.
                    // Lihat catatan yang sama di tombol Batal di atas.
                    Navigator.pop(ctx);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => disposeControllers(),
                    );

                    // Refresh halaman setelah edit (mirip behavior di halaman keuangan)
                    // dan pastikan UI sudah render sebelum SnackBar muncul.
                    if (!mounted) return;
                    setState(() {});
                    widget.onRefresh();
                    await Future<void>.delayed(
                      const Duration(milliseconds: 80),
                    );

                    // Notifikasi seperti tombol Hapus (di bagian dialog edit)
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Transaksi berhasil diubah',
                            style: kSnackTextStyle,
                          ),
                          backgroundColor: kGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          margin: EdgeInsets.fromLTRB(14, 0, 14, 14),
                        ),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // disposeControllers dipanggil saat batal/simpan
    });
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: kBlue),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}
