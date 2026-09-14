import 'dart:async';

import 'package:flutter/material.dart';

import '../berkas.dart';
import '../tema.dart';
import '../umpan.dart';
import 'pelanggan.dart';
import 'pelanggan_csv.dart';
import 'pelanggan_repo.dart';

class PelangganCsvDialog {
  static Future<void> buka({
    required BuildContext context,
    required PelangganRepo repo,
    required VoidCallback onSelesai,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _Isi(repo: repo, onSelesai: onSelesai),
    );
  }
}

class _Isi extends StatefulWidget {
  const _Isi({required this.repo, required this.onSelesai});

  final PelangganRepo repo;
  final VoidCallback onSelesai;

  @override
  State<_Isi> createState() => _IsiState();
}

class _IsiState extends State<_Isi> {
  bool _proses = false;
  List<Pelanggan>? _semua;
  String? _galat;

  ButtonStyle get _isi => FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  ButtonStyle get _garis => OutlinedButton.styleFrom(
        foregroundColor: Tema.seed,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  @override
  void initState() {
    super.initState();
    unawaited(_muatSemua());
  }

  Future<void> _muatSemua() async {
    try {
      final list = await widget.repo.semua();
      if (!mounted) return;
      setState(() {
        _semua = list;
        _galat = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _galat = pesanGagal(e, 'Data CSV belum bisa dimuat.'));
    }
  }

  Future<void> _unduh() async {
    final list = _semua;
    if (list == null) {
      setState(() => _galat = 'Data masih dimuat. Coba lagi sebentar.');
      return;
    }
    try {
      final ok = await Berkas.unduhCsv('pelanggan.csv', PelangganCsv.dariDaftar(list));
      if (!mounted) return;
      if (ok) {
        umpan(context, 'CSV pelanggan disimpan.', nada: NadaUmpan.hijau);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _galat = pesanGagal(e, 'CSV pelanggan belum terunduh.'));
      }
    }
  }

  Future<void> _template() async {
    try {
      final ok = await Berkas.unduhCsv(
        'template_pelanggan.csv',
        PelangganCsv.template(),
      );
      if (!mounted) return;
      if (ok) {
        umpan(context, 'Template pelanggan disimpan.', nada: NadaUmpan.hijau);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _galat = pesanGagal(e, 'Template belum terunduh.'));
      }
    }
  }

  Future<void> _unggah() async {
    final teks = await Berkas.pilihCsv();
    if (teks == null || !mounted) return;
    final baris = PelangganCsv.baca(teks);
    if (baris.isEmpty) {
      setState(() => _galat = 'CSV pelanggan kosong atau tanpa id.');
      return;
    }
    setState(() => _proses = true);
    try {
      final hasil = await widget.repo.unggah(baris);
      if (!mounted) return;
      await _muatSemua();
      widget.onSelesai();
      await _tampilHasil(hasil);
    } catch (e) {
      if (mounted) {
        setState(() => _galat = pesanGagal(e, 'CSV pelanggan belum terunggah.'));
      }
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Future<void> _tampilHasil(List<BarisCsvPelanggan> hasil) async {
    final ok = hasil.where((e) => e.ok).length;
    final gagal = hasil.length - ok;
    if (!mounted) return;
    umpan(
      context,
      'Unggah pelanggan: $ok berhasil, $gagal gagal.',
      nada: gagal == 0 ? NadaUmpan.hijau : NadaUmpan.kuning,
    );
    setState(() {
      _galat = gagal == 0 ? null : 'Unggah: $ok berhasil, $gagal gagal.';
    });
    if (gagal == 0) return;
    final salah = hasil.where((e) => !e.ok).take(12).toList();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unggah pelanggan'),
        content: SingleChildScrollView(
          child: Text(
            salah
                .map((e) => 'Baris ${e.baris} (${e.id}): ${e.pesan}')
                .join('\n'),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CSV pelanggan'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_proses || (_semua == null && _galat == null))
              const LinearProgressIndicator(minHeight: 2),
            if (_galat != null) ...[
              Text(
                _galat!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Master pelanggan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hanya ubah id yang sudah ada: nama, rute, visit, urutan, koordinat, aktif. Toko baru dari aplikasi salesman. Rute/visit kosong = tidak diubah; isi - untuk mengosongkan. Kolom hapus = 1: hapus, atau nonaktif jika sudah dipakai nota.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  style: _garis,
                  onPressed: _proses ? null : _unduh,
                  child: const Text('Unduh data'),
                ),
                OutlinedButton(
                  style: _garis,
                  onPressed: _proses ? null : _template,
                  child: const Text('Unduh template'),
                ),
                FilledButton(
                  style: _isi,
                  onPressed: _proses ? null : _unggah,
                  child: const Text('Unggah CSV'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _proses ? null : () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
