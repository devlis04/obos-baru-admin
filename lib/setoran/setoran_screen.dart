import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../beranda/admin_drawer.dart';
import '../berkas.dart';
import '../dialog.dart';
import '../tema.dart';
import '../uang.dart';
import '../umpan.dart';
import '../barang/barang.dart';
import 'mutasi_csv.dart';
import 'barang_masuk_csv.dart';

/// Cek harian setara sheet SETORAN Excel. Peta kolom: setoran_excel.md
class SetoranScreen extends StatefulWidget {
  const SetoranScreen({super.key});

  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> {
  static const _rute = ['SBGP01', 'SBGP02', 'SBGP03', 'SBGP04'];
  static const _pecahanTunai = [
    (nilai: 100000, jenis: 'Lembar', label: '100.000'),
    (nilai: 50000, jenis: 'Lembar', label: '50.000'),
    (nilai: 20000, jenis: 'Lembar', label: '20.000'),
    (nilai: 10000, jenis: 'Lembar', label: '10.000'),
    (nilai: 5000, jenis: 'Lembar', label: '5.000'),
    (nilai: 2000, jenis: 'Lembar', label: '2.000'),
    (nilai: 1000, jenis: 'Lembar', label: '1.000'),
    (nilai: 1000, jenis: 'Koin', label: '1.000'),
    (nilai: 500, jenis: 'Koin', label: '500'),
  ];
  static const _lebarRute = 108.0;
  static const _lebarNilai = 248.0;
  static const _lebarLabelNilai = 118.0;
  static const _lebarKartuSetoran = 960.0;
  static const _lebarKananMin = 280.0;
  static const _tinggiBarisNilai = 26.0;
  static const _tinggiJudulSetoran = 32.0;
  static const _tinggiBarisSetoranMaks = 200.0;
  static const _padKartuTabelAtas = 4.0;
  static const _padKartuTabelBawah = 8.0;
  static const _celahKartu = 6.0;
  static const _celahSampingKartu = 12.0;
  static const _tinggiBarisSupplier = 28.0;
  static const _barisSupplierTampil = 5;
  static const _tinggiTotalMasuk = 22.0;
  static const _tinggiBarisAbsensi = 28.0;
  static const _tinggiTombolAksi = 32.0;
  static const _padHalamanAtas = 6.0;
  static const _padHalamanBawah = 6.0;
  static const _tinggiStatusHarian = 32.0;
  static const _teksIsi = 14.0;
  static const _hintCek =
      'Actual nota − mutasi − tunai admin − BOP − retur klaim − kasbon. '
      'Kiriman = masih dikirim (bukan pending). '
      'Actual = terkirim (tebus, waktu kunci hari itu). '
      'Batal = nota dibatalkan pengirim hari itu. '
      'Pending = ditunda, bukan sisa packed.';
  static const _garisKolom = TableBorder(
    verticalInside: BorderSide(color: Color(0xFF8FB4D9), width: 1),
  );
  final _sb = Supabase.instance.client;
  DateTime _hari = DateTime.now();
  bool _muat = true;
  bool _proses = false;
  List<Map<String, dynamic>> _truk = [];
  List<Map<String, dynamic>> _mutasi = [];
  List<Map<String, dynamic>> _pengirim = [];
  List<Map<String, dynamic>> _gudang = [];
  List<Map<String, dynamic>> _masukCloud = [];
  int _ongkirHari = 0;
  bool _bukuTerbuka = false;
  String _bukuTanggal = '';
  int _bukuGantung = 0;
  int _bukuPending = 0;
  bool _ikutiBukuTerbuka = true;
  bool _opnameAda = false;
  String _opnameStatus = '';
  int _opnameSelisihSku = 0;
  int _opnameNilaiSelisih = 0;
  int _opnameMenunggu = 0;
  List<Map<String, dynamic>> _opnameBeda = [];
  bool _kotor = false;
  bool _mutasiGantiIsi = false;
  String _namaBerkasMutasi = '';
  int _idMutasiLokal = 0;
  final Map<int, String> _ruteMutasiAwal = {};
  final Map<String, int> _drafTunai = {};
  final Map<String, List<int>> _drafPecahan = {};
  final List<
      ({int idSupplier, String namaSupplier, List<Map<String, dynamic>> baris})>
      _drafMasuk = [];
  final Map<String, List<Map<String, dynamic>>> _drafRetur = {};
  final Map<String, bool> _drafPendingCek = {};
  final Map<String, String> _drafPendingRute = {};
  final Map<String, ({List<String> rute, bool cek, int fisik})> _drafBatalCek =
      {};
  final Map<String, ({bool cek, int actual})> _drafKasbon = {};

  String get _iso => Uang.isoHari(_hari);

  String _teksHari(DateTime d) => Uang.hariTanggal(d);

  String get _judulHari => _teksHari(_hari);

  String get _judulAppBar => 'Setoran ${_teksHari(_hari)}';

  String _isoDariNilai(dynamic v) {
    if (v is DateTime) return Uang.isoHari(v);
    final s = v?.toString() ?? '';
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  String get _judulBuku {
    if (_bukuTanggal.isEmpty) return '';
    final p = DateTime.tryParse(_bukuTanggal);
    if (p == null) return _bukuTanggal;
    return _teksHari(DateTime(p.year, p.month, p.day));
  }

  bool get _sedangLihatBukuTerbuka =>
      _bukuTerbuka && _bukuTanggal.isNotEmpty && _iso == _bukuTanggal;

  double _tinggiKartuSetoran(int nBaris, double tinggiBaris) =>
      _padKartuTabelAtas +
      _tinggiJudulSetoran +
      nBaris * tinggiBaris +
      _padKartuTabelBawah;

  double get _tinggiKartuMasukPenuh =>
      8 +
      _tinggiTombolAksi +
      8 +
      _barisSupplierTampil * _tinggiBarisSupplier +
      6 +
      _tinggiTotalMasuk * 2 +
      10;

  ButtonStyle get _gayaTombolBiru => FilledButton.styleFrom(
    backgroundColor: Tema.seed,
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFF8FB4D9),
    disabledForegroundColor: Colors.white,
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size(0, _tinggiTombolAksi),
    padding: const EdgeInsets.symmetric(horizontal: 10),
  );

  Widget _tombolBiru({
    required String label,
    required VoidCallback? onPressed,
    IconData? ikon,
    double? ukuranFont,
  }) {
    final teks = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ukuranFont == null
          ? null
          : TextStyle(fontSize: ukuranFont, fontWeight: FontWeight.bold),
    );
    return SizedBox(
      width: double.infinity,
      height: _tinggiTombolAksi,
      child: FilledButton(
        onPressed: onPressed,
        style: _gayaTombolBiru,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ikon == null
              ? teks
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ikon, size: 18),
                    const SizedBox(width: 8),
                    teks,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _tombolSetengahKiri({
    required String label,
    required VoidCallback? onPressed,
    IconData? ikon,
    double? ukuranFont,
  }) {
    return Row(
      children: [
        Expanded(
          child: _tombolBiru(
            label: label,
            onPressed: onPressed,
            ikon: ikon,
            ukuranFont: ukuranFont,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _hari = DateTime(_hari.year, _hari.month, _hari.day);
    _muatData();
  }

  int _angka(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> get _masuk {
    final out = [
      for (final m in _masukCloud) Map<String, dynamic>.from(m),
    ];
    for (final d in _drafMasuk) {
      for (final b in d.baris) {
        _gabungBarisMasukKartu(out, d.idSupplier, d.namaSupplier, b);
      }
    }
    return out;
  }

  void _setDrafMasuk(
    int idSupplier,
    String namaSupplier,
    List<Map<String, dynamic>> kirim,
  ) {
    _drafMasuk.removeWhere((d) => d.idSupplier == idSupplier);
    if (kirim.isNotEmpty) {
      _drafMasuk.add((
        idSupplier: idSupplier,
        namaSupplier: namaSupplier,
        baris: List<Map<String, dynamic>>.from(kirim),
      ));
    }
  }

  void _gabungBarisMasukKartu(
    List<Map<String, dynamic>> out,
    int idSupplier,
    String namaSupplier,
    Map<String, dynamic> b,
  ) {
    final kode = (b['kode_barang'] ?? '').toString().trim();
    final namaTampil = b['baru'] == true
        ? Barang.gabungNama(
            nama: b['nama']?.toString() ?? '',
            satuan: b['satuan']?.toString() ?? '',
            rincian: b['rincian']?.toString() ?? '',
          )
        : (b['nama_barang'] ?? b['nama'] ?? '').toString().trim();
    final i = out.indexWhere((m) {
      if (_angka(m['id_supplier']) != idSupplier) return false;
      if (kode.isNotEmpty) {
        return (m['kode_barang']?.toString() ?? '').toLowerCase() ==
            kode.toLowerCase();
      }
      return (m['kode_barang']?.toString() ?? '').trim().isEmpty &&
          (m['nama_barang']?.toString() ?? '') == namaTampil;
    });
    final qty = _angka(b['qty']);
    final harga = _angka(b['harga_beli']);
    final nilai = qty * harga;
    if (i < 0) {
      out.add({
        'id_supplier': idSupplier,
        'nama_supplier': namaSupplier,
        'kode_barang': kode,
        'nama_barang': namaTampil.isEmpty ? kode : namaTampil,
        'qty': qty,
        'harga_beli': harga,
        'nilai': nilai,
      });
      return;
    }
    out[i] = {
      ...out[i],
      'qty': _angka(out[i]['qty']) + qty,
      'harga_beli': harga,
      'nilai': _angka(out[i]['nilai']) + nilai,
    };
  }

  List<int> _qtyPecahan(Map<String, dynamic> row) {
    dynamic raw = row['pecahan_tunai'];
    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        raw = null;
      }
    }
    if (raw is! List || raw.length != _pecahanTunai.length) {
      return List<int>.filled(_pecahanTunai.length, 0);
    }
    return raw.map(_angka).toList();
  }

  void _timpaBarisTruk(String rute, Map<String, dynamic> ubah) {
    final i = _truk.indexWhere((r) => r['rute_pengirim']?.toString() == rute);
    if (i < 0) return;
    final row = Map<String, dynamic>.from(_truk[i])..addAll(ubah);
    _selesaiHitung(row);
    setState(() {
      final next = List<Map<String, dynamic>>.from(_truk);
      next[i] = row;
      _truk = next;
    });
  }

  void _selesaiHitung(Map<String, dynamic> row) {
    final kasbon = _kasbonKlaimTotal(row);
    final tunaiAdmin = _angka(row['tunai_admin']);
    final mutasi = _angka(row['transfer_mutasi']);
    row['tunai_beda'] =
        row['sudah_setor'] == true &&
        tunaiAdmin > 0 &&
        tunaiAdmin != _angka(row['tunai']);
    row['transfer_beda'] =
        row['sudah_setor'] == true &&
        mutasi > 0 &&
        mutasi != _angka(row['transfer']);
    row['sesa_cek'] =
        _angka(row['actual']) -
        mutasi -
        tunaiAdmin -
        _angka(row['bop']) -
        _angka(row['retur']) -
        kasbon;
  }

  List<Map<String, dynamic>> _saringMutasiKredit(
    List<Map<String, dynamic>> mutasi,
  ) {
    return mutasi.where((m) {
      if (_angka(m['jumlah']) <= 0) return false;
      return !MutasiCsv.beritaDebet(m['berita']?.toString() ?? '');
    }).toList();
  }

  List<Map<String, dynamic>> _timpaTransferMutasi(
    List<Map<String, dynamic>> truk,
    List<Map<String, dynamic>> mutasi,
  ) {
    final jumlah = <String, int>{};
    for (final m in mutasi) {
      final st = m['status_cocok']?.toString() ?? '';
      if (st != 'cocok' && st != 'manual') continue;
      final rute = m['rute_pengirim']?.toString() ?? '';
      if (rute.isEmpty) continue;
      jumlah[rute] = (jumlah[rute] ?? 0) + _angka(m['jumlah']);
    }
    return truk.map((lama) {
      final row = Map<String, dynamic>.from(lama);
      final rute = row['rute_pengirim']?.toString() ?? '';
      row['transfer_mutasi'] = jumlah[rute] ?? 0;
      _selesaiHitung(row);
      return row;
    }).toList();
  }

  void _resetDraf() {
    _kotor = false;
    _mutasiGantiIsi = false;
    _namaBerkasMutasi = '';
    _idMutasiLokal = 0;
    _ruteMutasiAwal.clear();
    _drafTunai.clear();
    _drafPecahan.clear();
    _drafMasuk.clear();
    _drafRetur.clear();
    _drafPendingCek.clear();
    _drafPendingRute.clear();
    _drafBatalCek.clear();
    _drafKasbon.clear();
  }

  void _catatSnapshotAwal() {
    _ruteMutasiAwal
      ..clear()
      ..addAll({
        for (final m in _mutasi)
          _angka(m['id']): m['rute_pengirim']?.toString() ?? '',
      });
  }

  void _tandaiKotor() {
    _kotor = true;
    if (mounted) setState(() {});
  }

  Future<bool> _izinBuangDraf() async {
    if (!_kotor) return true;
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: const Text('Buang perubahan?'),
        content: const Text(
          'Ada data setoran yang belum disimpan ke cloud. Lanjut dan buang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return ya == true;
  }

  Future<void> _tutupBuku() async {
    if (_proses || !_sedangLihatBukuTerbuka) return;
    if (_bukuGantung > 0) {
      umpan(
        context,
        'Masih ada $_bukuGantung nota di truk. Kunci atau tandai pending dulu.',
        nada: NadaUmpan.kuning,
      );
      return;
    }
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: const Text('Tutup buku setoran?'),
        content: Text(
          _bukuPending > 0
              ? 'Buku ${_judulBuku.isEmpty ? _bukuTanggal : _judulBuku} ditutup. '
                  '$_bukuPending nota pending pindah ke buku berikutnya. '
                  'Nota terkirim dan batal tetap di buku ini.'
              : 'Buku ${_judulBuku.isEmpty ? _bukuTanggal : _judulBuku} ditutup. '
                  'Packing berikutnya masuk buku baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    setState(() => _proses = true);
    try {
      final ok = await _sb.rpc(
        'admin_setoran_buku_tutup',
        params: {
          'p_tanggal': _bukuTanggal.isEmpty ? _iso : _bukuTanggal,
        },
      );
      if (ok != true) throw Exception('buku');
      if (!mounted) return;
      _ikutiBukuTerbuka = true;
      await _muatData(buangDraf: true);
      if (!mounted) return;
      umpan(context, 'Buku setoran ditutup.', nada: NadaUmpan.hijau);
    } catch (e) {
      if (mounted) {
        umpan(context, pesanGagal(e, 'Gagal menutup buku setoran.'));
      }
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  String? _ruteDariBerita(String berita) {
    final diBuku = MutasiCsv.ruteDariBerita(berita, _iso);
    if (diBuku != null) return diBuku;
    final hariIni = Uang.isoHari(DateTime.now());
    if (hariIni == _iso) return null;
    return MutasiCsv.ruteDariBerita(berita, hariIni);
  }

  Future<bool> _adaNet() async => true;

  Future<void> _muatData({
    bool layarPenuh = false,
    bool buangDraf = false,
  }) async {
    if (!buangDraf && !await _izinBuangDraf()) return;
    if (layarPenuh && mounted) setState(() => _muat = true);
    try {
      var bukuTerbuka = false;
      var bukuTanggal = '';
      var bukuGantung = 0;
      var bukuPending = 0;
      try {
        final rawBuku = await _sb.rpc(
          'admin_setoran_buku_lihat',
          params: {'p_tanggal': null},
        );
        if (rawBuku is List) {
          Map<String, dynamic>? pilih;
          for (final e in rawBuku) {
            if (e is! Map) continue;
            final m = Map<String, dynamic>.from(e);
            if (m['buku_terbuka'] == true) {
              pilih = m;
              break;
            }
            pilih ??= m;
          }
          if (pilih != null) {
            bukuTerbuka = pilih['buku_terbuka'] == true;
            bukuTanggal = _isoDariNilai(pilih['tanggal']);
            bukuGantung = _angka(pilih['jumlah_gantung']);
            bukuPending = _angka(pilih['jumlah_pending']);
          }
        }
      } catch (_) {}
      if (_ikutiBukuTerbuka && bukuTerbuka && bukuTanggal.isNotEmpty) {
        final p = DateTime.tryParse(bukuTanggal);
        if (p != null) {
          _hari = DateTime(p.year, p.month, p.day);
        }
      }
      final truk = await _sb.rpc(
        'admin_setoran_hari',
        params: {'p_tanggal': _iso},
      );
      dynamic mutasi;
      try {
        mutasi = await _sb.rpc(
          'admin_mutasi_lihat',
          params: {'p_tanggal': _iso},
        );
      } catch (_) {
        mutasi = [];
      }
      List<Map<String, dynamic>> pengirim = [];
      List<Map<String, dynamic>> gudang = [];
      try {
        final orang = await _sb.rpc(
          'admin_absensi_hari',
          params: {'p_tanggal': _iso},
        );
        final isi = orang is List
            ? orang.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : <Map<String, dynamic>>[];
        pengirim = isi
            .where(
              (m) =>
                  (m['peran']?.toString() ?? '').trim().toLowerCase() ==
                  'pengirim',
            )
            .toList();
        gudang = isi
            .where(
              (m) =>
                  (m['peran']?.toString() ?? '').trim().toLowerCase() ==
                  'gudang',
            )
            .toList();
      } catch (_) {
        pengirim = [];
        gudang = [];
      }
      List<Map<String, dynamic>> masuk = [];
      try {
        final rawMasuk = await _sb.rpc(
          'admin_barang_masuk_hari',
          params: {'p_tanggal': _iso},
        );
        if (rawMasuk is List) {
          masuk = rawMasuk
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {
        masuk = [];
      }
      var ongkirHari = 0;
      try {
        ongkirHari = _angka(
          await _sb.rpc('admin_ongkir_lihat', params: {'p_tanggal': _iso}),
        );
      } catch (_) {}
      var opnameAda = false;
      var opnameStatus = '';
      var opnameSku = 0;
      var opnameNilai = 0;
      var opnameMenunggu = 0;
      var opnameBeda = <Map<String, dynamic>>[];
      try {
        final ringkas = await _ringkasOpname();
        opnameAda = ringkas.ada;
        opnameStatus = ringkas.status;
        opnameSku = ringkas.sku;
        opnameNilai = ringkas.nilai;
        opnameMenunggu = ringkas.menunggu;
        opnameBeda = ringkas.beda;
      } catch (_) {}
      if (!mounted) return;
      final mutasiKredit = (mutasi is List)
          ? _saringMutasiKredit(
              mutasi.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            )
          : <Map<String, dynamic>>[];
      final trukList = (truk is List)
          ? truk.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _mutasi = mutasiKredit;
        _truk = _timpaTransferMutasi(trukList, mutasiKredit);
        _pengirim = pengirim;
        _gudang = gudang;
        _masukCloud = masuk;
        _ongkirHari = ongkirHari;
        _bukuTerbuka = bukuTerbuka;
        _bukuTanggal = bukuTanggal;
        _bukuGantung = bukuGantung;
        _bukuPending = bukuPending;
        _opnameAda = opnameAda;
        _opnameStatus = opnameStatus;
        _opnameSelisihSku = opnameSku;
        _opnameNilaiSelisih = opnameNilai;
        _opnameMenunggu = opnameMenunggu;
        _opnameBeda = opnameBeda;
        _muat = false;
        _resetDraf();
        _catatSnapshotAwal();
      });
    } catch (e) {
      if (!mounted) return;
      if (layarPenuh) {
        setState(() {
          _truk = [];
          _mutasi = [];
          _pengirim = [];
          _gudang = [];
          _masukCloud = [];
          _ongkirHari = 0;
          _bukuTerbuka = false;
          _bukuTanggal = '';
          _bukuGantung = 0;
          _bukuPending = 0;
          _opnameAda = false;
          _opnameStatus = '';
          _opnameSelisihSku = 0;
          _opnameNilaiSelisih = 0;
          _opnameMenunggu = 0;
          _opnameBeda = [];
          _muat = false;
        });
      }
      umpan(context, pesanGagal(e, 'Gagal memuat setoran.'));
    }
  }

  int _idDariRpc(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<List<({int id, String nama})>> _muatDaftarSupplier() async {
    final raw = await _sb.rpc('admin_supplier_lihat');
    final out = <({int id, String nama})>[];
    if (raw is! List) return out;
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final id = _idDariRpc(m['id']);
      final nama = (m['nama']?.toString() ?? '').trim();
      if (id <= 0 || nama.isEmpty) continue;
      out.add((id: id, nama: nama));
    }
    return out;
  }

  Future<void> _dialogBarangMasuk() async {
    if (_proses) return;
    if (!await _adaNet()) return;
    final baris = <_BarisMasuk>[];
    var daftarSupplier = <({int id, String nama})>[];
    var idSupplier = 0;
    final hargaSupplier = <String, int>{};
    try {
      daftarSupplier = await _muatDaftarSupplier();
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat barang masuk.');
      return;
    }

    var ongkirHariTotal = 0;
    var ongkirMingguTotal = 0;
    try {
      ongkirHariTotal = _angka(
        await _sb.rpc('admin_ongkir_lihat', params: {'p_tanggal': _iso}),
      );
      ongkirMingguTotal = _angka(
        await _sb.rpc('admin_ongkir_minggu', params: {'p_tanggal': _iso}),
      );
    } catch (_) {}
    if (!mounted) {
      for (final b in baris) {
        b.dispose();
      }
      return;
    }

    final cariCtrl = TextEditingController();
    final namaSupplierCtrl = TextEditingController();
    final ongkirCtrl = TextEditingController();
    final skuNamaCtrl = TextEditingController();
    final skuSatuanCtrl = TextEditingController();
    final skuRincianCtrl = TextEditingController();
    final skuKategoriCtrl = TextEditingController();
    final skuHargaCtrl = TextEditingController();
    final skuQtyCtrl = TextEditingController();
    var ongkirTersimpan = 0;
    var ongkirProses = false;
    var saran = <({String kode, String nama, int harga})>[];
    var tampilSupplierBaru = false;
    var tampilSkuBaru = false;
    var kunciPilihSupplier = 0;
    Timer? tunda;
    final seninMinggu = DateTime(
      _hari.year,
      _hari.month,
      _hari.day,
    ).subtract(Duration(days: _hari.weekday - 1));
    final labelMinggu =
        '${Uang.pendek(seninMinggu)} – ${Uang.pendek(seninMinggu.add(const Duration(days: 5)))}';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            bool adaQtyBaru() =>
                baris.any((b) => b.qty > 0) ||
                Uang.angkaTeks(ongkirCtrl.text) != ongkirTersimpan;

            void tambahBarang(
              String kode,
              String nama, {
              int qty = 0,
              int harga = 0,
            }) {
              if (idSupplier <= 0) {
                umpan(
                  this.context,
                  'Pilih atau tambah supplier dulu.',
                  nada: NadaUmpan.kuning,
                );
                return;
              }
              final kodeN = kode.trim();
              if (kodeN.isEmpty) return;
              for (final b in baris) {
                if (b.kode.toLowerCase() == kodeN.toLowerCase()) {
                  cariCtrl.clear();
                  saran = [];
                  setLocal(() {});
                  return;
                }
              }
              baris.add(
                _BarisMasuk(
                  kode: kodeN,
                  nama: nama.trim(),
                  qtySudah: 0,
                  hargaAwal: hargaSupplier[kodeN.toLowerCase()] ?? harga,
                  qtyTambah: qty,
                ),
              );
              cariCtrl.clear();
              saran = [];
              setLocal(() {});
            }

            void terapkanBerkas(List<BarisMasukCsv> items) {
              for (final it in items) {
                _BarisMasuk? ada;
                for (final b in baris) {
                  if (it.baru) {
                    if (b.baru &&
                        b.nama.toLowerCase() == it.nama.toLowerCase() &&
                        b.satuan.toLowerCase() == it.satuan.toLowerCase()) {
                      ada = b;
                      break;
                    }
                  } else if (it.kode.isNotEmpty &&
                      b.kode.toLowerCase() == it.kode.toLowerCase()) {
                    ada = b;
                    break;
                  }
                }
                if (ada != null) {
                  ada.qtyCtrl.text = Uang.angka(ada.qty + it.qty);
                  if (it.harga > 0) {
                    ada.hargaCtrl.text = Uang.angka(it.harga);
                  }
                } else {
                  final hargaLama = it.kode.isEmpty
                      ? 0
                      : (hargaSupplier[it.kode.toLowerCase()] ?? 0);
                  baris.add(
                    _BarisMasuk(
                      kode: it.kode,
                      nama: it.nama,
                      qtySudah: 0,
                      hargaAwal: it.harga > 0 ? it.harga : hargaLama,
                      qtyTambah: it.qty,
                      baru: it.baru,
                      satuan: it.satuan,
                      rincian: it.rincian,
                      kategori: it.kategori,
                    ),
                  );
                }
              }
              setLocal(() {});
            }

            Future<List<({String kode, String nama, int harga})>?>
            muatKatalog() async {
              if (!await _adaNet()) return null;
              try {
                final raw = await _sb.rpc('admin_barang_semua');
                final katalog = <({String kode, String nama, int harga})>[];
                if (raw is List) {
                  for (final e in raw) {
                    if (e is! Map) continue;
                    final m = Map<String, dynamic>.from(e);
                    final kode = (m['id_barang']?.toString() ??
                            m['kode_barang']?.toString() ??
                            '')
                        .trim();
                    if (kode.isEmpty) continue;
                    katalog.add((
                      kode: kode,
                      nama: (m['nama_barang']?.toString() ?? '').trim(),
                      harga: _angka(m['harga_beli']),
                    ));
                  }
                }
                return katalog;
              } catch (_) {
                if (!mounted) return null;
                umpan(this.context, 'Gagal memuat katalog.');
                return null;
              }
            }

            Future<void> unduhTemplate() async {
              final katalog = await muatKatalog();
              if (katalog == null || !mounted) return;
              final simpan = await Berkas.unduhCsv(
                BarangMasukCsv.namaBerkas,
                utf8.decode(
                  BarangMasukCsv.bytesTemplate([
                    for (final b in katalog) (kode: b.kode, nama: b.nama),
                  ]),
                ),
              );
              if (!mounted || !simpan) return;
              umpan(this.context, 'Template ${BarangMasukCsv.namaBerkas}: ${katalog.length} barang. Isi qty dan harga beli.', nada: NadaUmpan.hijau);
            }

            Future<void> unduhTemplateSku() async {
              final katalog = await muatKatalog();
              if (katalog == null || !mounted) return;
              final contoh = BarangMasukCsv.contohSkuBaru(katalog);
              final simpan = await Berkas.unduhCsv(
                BarangMasukCsv.namaBerkasSku,
                utf8.decode(BarangMasukCsv.bytesTemplateSkuBaru(contoh)),
              );
              if (!mounted || !simpan) return;
              umpan(this.context, 'Template ${BarangMasukCsv.namaBerkasSku}: ganti baris contoh, lalu unggah SKU baru.', nada: NadaUmpan.hijau);
            }

            Future<HasilMasukCsv?> pilihBerkasMasuk() async {
              final teks = await Berkas.pilihCsv();
              if (teks == null || !mounted) return null;
              final hasil = BarangMasukCsv.parse(teks);
              if (hasil.error != null) {
                umpan(this.context, hasil.error!);
                return null;
              }
              return hasil;
            }

            Future<void> unggahBerkas() async {
              if (idSupplier <= 0) {
                umpan(this.context, 'Pilih atau tambah supplier dulu.', nada: NadaUmpan.kuning);
                return;
              }
              final hasil = await pilihBerkasMasuk();
              if (hasil == null || !mounted) return;
              final katalog = await muatKatalog();
              if (katalog == null || !mounted) return;
              final namaByKode = {for (final b in katalog) b.kode: b.nama};
              final kodeAsli = {
                for (final b in katalog) b.kode.trim().toLowerCase(): b.kode,
              };
              final salah = BarangMasukCsv.cekCocokKatalog(
                hasil.baris,
                namaByKode,
              );
              if (salah != null) {
                umpan(this.context, salah, nada: NadaUmpan.kuning);
                return;
              }
              terapkanBerkas([
                for (final x in hasil.baris)
                  BarisMasukCsv(
                    kode: kodeAsli[x.kode.trim().toLowerCase()] ?? x.kode,
                    nama: x.nama,
                    qty: x.qty,
                    harga: x.harga,
                  ),
              ]);
              umpan(this.context, '${hasil.baris.length} barang dari berkas. Periksa, lalu Simpan.', nada: NadaUmpan.hijau);
            }

            Future<void> unggahSkuBaru() async {
              if (idSupplier <= 0) {
                umpan(this.context, 'Pilih atau tambah supplier dulu.', nada: NadaUmpan.kuning);
                return;
              }
              final teks = await Berkas.pilihCsv();
              if (teks == null || !mounted) return;
              final hasil = BarangMasukCsv.parseSku(teks);
              if (hasil.error != null) {
                umpan(this.context, hasil.error!);
                return;
              }
              final salah = BarangMasukCsv.cekSkuBaru(hasil.baris);
              if (salah != null) {
                umpan(this.context, salah, nada: NadaUmpan.kuning);
                return;
              }
              final katalog = await muatKatalog();
              if (katalog == null || !mounted) return;
              final namaAda = {
                for (final b in katalog) b.nama.trim().toLowerCase(),
              };
              for (final x in hasil.baris) {
                final tampil = Barang.gabungNama(
                  nama: x.nama,
                  satuan: x.satuan,
                  rincian: x.rincian,
                );
                if (namaAda.contains(tampil.toLowerCase())) {
                  umpan(
                    this.context,
                    'SKU $tampil sudah ada di katalog. Pakai Unggah barang masuk.',
                    nada: NadaUmpan.kuning,
                  );
                  return;
                }
              }
              terapkanBerkas(hasil.baris);
              umpan(this.context, '${hasil.baris.length} SKU baru dari berkas. Periksa, lalu Simpan.', nada: NadaUmpan.hijau);
            }

            Future<void> pilihSupplier(int id) async {
              if (id == idSupplier) return;
              if (adaQtyBaru()) {
                umpan(
                  this.context,
                  'Satu kali input = satu supplier. Simpan dulu, lalu buka Barang masuk lagi untuk supplier lain.',
                  nada: NadaUmpan.kuning,
                );
                kunciPilihSupplier++;
                setLocal(() {});
                return;
              }
              for (final b in baris) {
                b.dispose();
              }
              baris.clear();
              hargaSupplier.clear();
              try {
                final raw = await _sb.rpc(
                  'admin_barang_masuk_lihat',
                  params: {'p_tanggal': _iso, 'p_id_supplier': id},
                );
                final hargaRaw = await _sb.rpc(
                  'admin_supplier_harga_lihat',
                  params: {'p_id_supplier': id},
                );
                if (hargaRaw is List) {
                  for (final e in hargaRaw) {
                    if (e is! Map) continue;
                    final m = Map<String, dynamic>.from(e);
                    final kode = m['kode_barang']?.toString() ?? '';
                    if (kode.isEmpty) continue;
                    hargaSupplier[kode.trim().toLowerCase()] =
                        _angka(m['harga_beli']);
                  }
                }
                if (raw is List) {
                  for (final e in raw) {
                    if (e is! Map) continue;
                    final m = Map<String, dynamic>.from(e);
                    baris.add(
                      _BarisMasuk(
                        kode: m['kode_barang']?.toString() ?? '',
                        nama: m['nama_barang']?.toString() ?? '',
                        qtySudah: _angka(m['qty']),
                        nilaiSudah: _angka(m['nilai']),
                        hargaAwal: _angka(m['harga_beli']),
                      ),
                    );
                  }
                }
                idSupplier = id;
                final ongkirSup = _angka(
                  await _sb.rpc(
                    'admin_ongkir_lihat_supplier',
                    params: {
                      'p_tanggal': _iso,
                      'p_id_supplier': id,
                    },
                  ),
                );
                ongkirTersimpan = ongkirSup;
                ongkirCtrl.text = ongkirSup == 0 ? '' : Uang.angka(ongkirSup);
                final drafSup = _drafMasuk.where((d) => d.idSupplier == id);
                for (final d in drafSup) {
                  terapkanBerkas([
                    for (final n in d.baris)
                      if (n['baru'] == true)
                        BarisMasukCsv(
                          kode: '',
                          nama: n['nama']?.toString() ?? '',
                          qty: _angka(n['qty']),
                          harga: _angka(n['harga_beli']),
                          baru: true,
                          satuan: n['satuan']?.toString() ?? '',
                          rincian: n['rincian']?.toString() ?? '',
                          kategori: n['kategori']?.toString() ?? '',
                        )
                      else
                        BarisMasukCsv(
                          kode: n['kode_barang']?.toString() ?? '',
                          nama: n['nama_barang']?.toString() ?? '',
                          qty: _angka(n['qty']),
                          harga: _angka(n['harga_beli']),
                        ),
                  ]);
                }
                if (ctx.mounted) setLocal(() {});
              } catch (_) {
                if (!mounted) return;
                umpan(this.context, 'Gagal memuat data supplier.');
              }
            }

            Future<void> tambahSupplier() async {
              final nama = namaSupplierCtrl.text.trim();
              if (nama.isEmpty) {
                umpan(this.context, 'Isi nama supplier.', nada: NadaUmpan.kuning);
                return;
              }
              try {
                final id = _idDariRpc(
                  await _sb.rpc(
                    'admin_supplier_tambah',
                    params: {'p_nama': nama},
                  ),
                );
                if (!mounted) return;
                if (id <= 0) {
                  umpan(this.context, 'Gagal menambah supplier.');
                  return;
                }
                daftarSupplier = await _muatDaftarSupplier();
                if (!mounted) return;
                namaSupplierCtrl.clear();
                tampilSupplierBaru = false;
                await pilihSupplier(id);
              } catch (_) {
                if (!mounted) return;
                umpan(this.context, 'Gagal menambah supplier.');
              }
            }

            void cariBarang(String q) {
              tunda?.cancel();
              final teks = q.trim();
              if (teks.length < 2) {
                setLocal(() => saran = []);
                return;
              }
              tunda = Timer(const Duration(milliseconds: 280), () async {
                try {
                  final raw = await _sb.rpc(
                    'admin_barang_cari',
                    params: {'p_cari': teks},
                  );
                  final next = <({String kode, String nama, int harga})>[];
                  if (raw is List) {
                    for (final e in raw) {
                      if (e is! Map) continue;
                      final m = Map<String, dynamic>.from(e);
                      next.add((
                        kode: m['kode_barang']?.toString() ?? '',
                        nama: m['nama_barang']?.toString() ?? '',
                        harga: _angka(m['harga_beli']),
                      ));
                    }
                  }
                  if (!ctx.mounted) return;
                  setLocal(() => saran = next);
                } catch (_) {
                  if (!ctx.mounted) return;
                  setLocal(() => saran = []);
                }
              });
            }

            Future<void> tambahSkuBaru() async {
              if (idSupplier <= 0) {
                umpan(
                  this.context,
                  'Pilih atau tambah supplier dulu.',
                  nada: NadaUmpan.kuning,
                );
                return;
              }
              final nama = skuNamaCtrl.text.trim();
              final satuan = skuSatuanCtrl.text.trim();
              final rincian = skuRincianCtrl.text.trim();
              final kategori = skuKategoriCtrl.text.trim();
              final harga = Uang.angkaTeks(skuHargaCtrl.text);
              final qty = Uang.angkaTeks(skuQtyCtrl.text);
              if (nama.isEmpty || satuan.isEmpty) {
                umpan(
                  this.context,
                  'Nama dan satuan wajib diisi.',
                  nada: NadaUmpan.kuning,
                );
                return;
              }
              if (harga <= 0 || qty <= 0) {
                umpan(
                  this.context,
                  'Harga beli dan qty wajib diisi.',
                  nada: NadaUmpan.kuning,
                );
                return;
              }
              final tampil = Barang.gabungNama(
                nama: nama,
                satuan: satuan,
                rincian: rincian,
              );
              for (final b in baris) {
                if (!b.baru && b.nama.trim().toLowerCase() == tampil.toLowerCase()) {
                  umpan(
                    this.context,
                    'Nama itu sudah di daftar sebagai ${b.kode}. Jangan buat SKU baru.',
                    nada: NadaUmpan.kuning,
                  );
                  return;
                }
              }
              final kunci = '${nama.toLowerCase()}|${satuan.toLowerCase()}';
              for (final b in baris) {
                if (b.baru &&
                    '${b.nama.toLowerCase()}|${b.satuan.toLowerCase()}' ==
                        kunci) {
                  umpan(
                    this.context,
                    'SKU itu sudah di daftar input.',
                    nada: NadaUmpan.kuning,
                  );
                  return;
                }
              }
              try {
                final raw = await _sb.rpc(
                  'admin_barang_cari',
                  params: {'p_cari': nama},
                );
                if (raw is List) {
                  for (final e in raw) {
                    if (e is! Map) continue;
                    final m = Map<String, dynamic>.from(e);
                    final nm = (m['nama_barang']?.toString() ?? '').trim();
                    if (nm.toLowerCase() == tampil.toLowerCase()) {
                      if (!mounted) return;
                      umpan(
                        this.context,
                        'Nama itu sudah ada (${m['kode_barang']}). Cari SKU lama, jangan buat baru.',
                        nada: NadaUmpan.kuning,
                      );
                      return;
                    }
                  }
                }
              } catch (_) {}
              baris.add(
                _BarisMasuk(
                  kode: '',
                  nama: nama,
                  qtyTambah: qty,
                  hargaAwal: harga,
                  baru: true,
                  satuan: satuan,
                  rincian: rincian,
                  kategori: kategori,
                ),
              );
              skuNamaCtrl.clear();
              skuSatuanCtrl.clear();
              skuRincianCtrl.clear();
              skuKategoriCtrl.clear();
              skuHargaCtrl.clear();
              skuQtyCtrl.clear();
              setLocal(() {});
            }

            int totalInput() => baris.fold<int>(0, (a, b) => a + b.nilai);
            int totalHariIni() =>
                baris.fold<int>(0, (a, b) => a + b.nilaiSudah) + totalInput();

            Future<bool> simpanOngkir() async {
              if (idSupplier <= 0) return false;
              final nilai = Uang.angkaTeks(ongkirCtrl.text);
              if (nilai == ongkirTersimpan) return true;
              setLocal(() => ongkirProses = true);
              try {
                final ok = await _sb.rpc(
                  'admin_ongkir_simpan',
                  params: {
                    'p_tanggal': _iso,
                    'p_id_supplier': idSupplier,
                    'p_ongkir': nilai,
                  },
                );
                if (!mounted) return false;
                if (ok == true) {
                  ongkirTersimpan = nilai;
                  ongkirHariTotal = _angka(
                    await _sb.rpc(
                      'admin_ongkir_lihat',
                      params: {'p_tanggal': _iso},
                    ),
                  );
                  if (!mounted) return false;
                  ongkirMingguTotal = _angka(
                    await _sb.rpc(
                      'admin_ongkir_minggu',
                      params: {'p_tanggal': _iso},
                    ),
                  );
                  if (!mounted) return false;
                  return true;
                }
                umpan(this.context, 'Ongkir gagal disimpan.', nada: NadaUmpan.kuning);
                return false;
              } catch (_) {
                if (mounted) {
                  umpan(this.context, 'Gagal menyimpan ongkir belanja.');
                }
                return false;
              } finally {
                if (ctx.mounted) setLocal(() => ongkirProses = false);
              }
            }

            Future<void> simpan() async {
              if (idSupplier <= 0) {
                umpan(
                  this.context,
                  'Pilih supplier dulu. Simpan ditolak jika supplier kosong.',
                  nada: NadaUmpan.kuning,
                );
                return;
              }
              final kirim = [
                for (final b in baris)
                  if (b.qty > 0 && b.harga > 0)
                    if (b.baru)
                      {
                        'baru': true,
                        'nama': b.nama,
                        'satuan': b.satuan,
                        'rincian': b.rincian,
                        'kategori': b.kategori,
                        'qty': b.qty,
                        'harga_beli': b.harga,
                      }
                    else if (b.kode.isNotEmpty)
                      {
                        'kode_barang': b.kode,
                        'nama_barang': b.nama,
                        'qty': b.qty,
                        'harga_beli': b.harga,
                      },
              ];
              for (final b in baris) {
                if (b.qty <= 0) continue;
                if (b.baru && (b.nama.isEmpty || b.satuan.isEmpty)) {
                  umpan(
                    this.context,
                    'SKU baru wajib nama dan satuan.',
                    nada: NadaUmpan.kuning,
                  );
                  return;
                }
                if (!b.baru && b.kode.isEmpty) continue;
                if (b.harga <= 0) {
                  umpan(this.context, 'Harga beli wajib diisi untuk setiap qty masuk.', nada: NadaUmpan.kuning);
                  return;
                }
              }
              if (!await simpanOngkir()) return;
              final namaSup = daftarSupplier
                  .where((s) => s.id == idSupplier)
                  .map((s) => s.nama)
                  .firstWhere((_) => true, orElse: () => 'Supplier');
              final drafLama = _drafMasuk.any((d) => d.idSupplier == idSupplier);
              _setDrafMasuk(idSupplier, namaSup, kirim);
              if (mounted) {
                setState(() {
                  if (kirim.isNotEmpty || drafLama) _kotor = true;
                  _ongkirHari = ongkirHariTotal;
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            }

            const gaya = TextStyle(fontSize: 12, height: 1.2);
            const gayaTebal = TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.bold,
            );
            const garis = BorderSide(color: Tema.seed, width: 1);
            final sudut = BorderRadius.circular(8);
            InputDecoration dekor({
              String? hint,
              String? label,
              Widget? prefix,
            }) {
              return InputDecoration(
                isDense: true,
                hintText: hint,
                labelText: label,
                hintStyle: gaya.copyWith(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                prefixIcon: prefix,
                prefixIconConstraints: prefix == null
                    ? null
                    : const BoxConstraints(minWidth: 36, minHeight: 36),
                border: OutlineInputBorder(
                  borderRadius: sudut,
                  borderSide: garis,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: sudut,
                  borderSide: garis,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: sudut,
                  borderSide: garis,
                ),
              );
            }

            Widget tajuk(String judul, bool buka, VoidCallback onTap) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(judul, style: gayaTebal)),
                      Icon(
                        buka ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: Tema.seed,
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget tautan(IconData ikon, String label, VoidCallback onTap) {
              return TextButton.icon(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(ikon, size: 18),
                label: Text(label, style: gayaTebal.copyWith(color: Tema.seed)),
              );
            }

            Widget tombolTambah(VoidCallback onTap) {
              return FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: const Text('Tambah'),
              );
            }

            const lebarQty = 76.0;
            const lebarHarga = 100.0;
            const lebarHapus = 32.0;

            return AppDialog(
              title: const Text('Barang masuk'),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              content: SizedBox(
                width: 540,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Satu kali input = satu supplier. Ongkir diisi per supplier, lalu dijumlahkan untuk hari itu (bukan rumus Cek). Supplier kosong: Simpan ditolak.',
                      style: gaya.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      key: ValueKey('$idSupplier-$kunciPilihSupplier'),
                      initialValue: idSupplier > 0 ? idSupplier : null,
                      isDense: true,
                      style: gaya.copyWith(color: Colors.black),
                      decoration: dekor(
                        label: 'Supplier',
                        hint: 'Pilih satu supplier',
                      ),
                      items: [
                        for (final s in daftarSupplier)
                          DropdownMenuItem(value: s.id, child: Text(s.nama)),
                      ],
                      onChanged: (v) {
                        if (v != null) pilihSupplier(v);
                      },
                    ),
                    tajuk(
                      'Supplier baru',
                      tampilSupplierBaru,
                      () => setLocal(
                        () => tampilSupplierBaru = !tampilSupplierBaru,
                      ),
                    ),
                    if (tampilSupplierBaru)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: namaSupplierCtrl,
                              style: gaya,
                              decoration: dekor(hint: 'Nama supplier baru'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          tombolTambah(tambahSupplier),
                        ],
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ongkirCtrl,
                      enabled: !ongkirProses && idSupplier > 0,
                      keyboardType: TextInputType.number,
                      style: gaya,
                      textAlign: TextAlign.right,
                      inputFormatters: const [UangFormatRibuan()],
                      decoration: dekor(
                        label: 'Ongkir supplier ini (bukan rumus Cek)',
                      ).copyWith(prefixText: 'Rp '),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Ongkir buku ini (semua supplier): Rp ${Uang.angka(ongkirHariTotal)}'
                        '\nTotal minggu $labelMinggu: Rp ${Uang.angka(ongkirMingguTotal)}',
                        style: gaya.copyWith(color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cariCtrl,
                      style: gaya,
                      decoration: dekor(
                        hint: 'Cari barang yang sudah ada',
                        prefix: const Icon(Icons.search, size: 18),
                      ),
                      onChanged: cariBarang,
                    ),
                    if (saran.isNotEmpty)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final s in saran)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(s.nama, style: gayaTebal),
                              subtitle: Text(s.kode, style: gaya),
                              onTap: () =>
                                  tambahBarang(s.kode, s.nama, harga: s.harga),
                            ),
                        ],
                      ),
                    Row(
                      children: [
                        tautan(
                          Icons.download_outlined,
                          'Template',
                          unduhTemplate,
                        ),
                        tautan(
                          Icons.upload_file_outlined,
                          'Unggah barang masuk',
                          unggahBerkas,
                        ),
                      ],
                    ),
                    tajuk(
                      'SKU baru',
                      tampilSkuBaru,
                      () => setLocal(() => tampilSkuBaru = !tampilSkuBaru),
                    ),
                    if (tampilSkuBaru) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: skuNamaCtrl,
                              style: gaya,
                              decoration: dekor(label: 'Nama'),
                            ),
                          ),
                          SizedBox(
                            width: 88,
                            child: TextField(
                              controller: skuSatuanCtrl,
                              style: gaya,
                              decoration: dekor(label: 'Satuan'),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: skuRincianCtrl,
                              style: gaya,
                              decoration: dekor(label: 'Rincian'),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: skuKategoriCtrl,
                              style: gaya,
                              decoration: dekor(label: 'Kategori'),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: skuHargaCtrl,
                              keyboardType: TextInputType.number,
                              style: gaya,
                              inputFormatters: const [UangFormatRibuan()],
                              decoration: dekor(label: 'Harga beli')
                                  .copyWith(prefixText: 'Rp '),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: skuQtyCtrl,
                              keyboardType: TextInputType.number,
                              style: gaya,
                              inputFormatters: const [UangFormatRibuan()],
                              decoration: dekor(label: 'Qty'),
                            ),
                          ),
                          tombolTambah(tambahSkuBaru),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Id otomatis. Jual = beli × 1,05 (pembulatan Rp 500). Langsung aktif di lapangan.',
                          style: gaya.copyWith(color: Colors.grey.shade700),
                        ),
                      ),
                      Row(
                        children: [
                          tautan(
                            Icons.download_outlined,
                            'Template SKU baru',
                            unduhTemplateSku,
                          ),
                          tautan(
                            Icons.upload_file_outlined,
                            'Unggah SKU baru',
                            unggahSkuBaru,
                          ),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, thickness: 0.6),
                    ),
                    _barisNilai('Total input', totalInput()),
                    _barisNilai('Total supplier ini', totalHariIni()),
                    const SizedBox(height: 8),
                    if (baris.isEmpty)
                      Text(
                        'Belum ada barang masuk di buku ini.',
                        style: gaya.copyWith(color: Colors.grey.shade600),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Expanded(child: Text('Barang', style: gayaTebal)),
                            SizedBox(
                              width: lebarQty,
                              child: const Text(
                                '+Qty',
                                textAlign: TextAlign.center,
                                style: gayaTebal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: lebarHarga,
                              child: const Text(
                                'Harga beli',
                                textAlign: TextAlign.right,
                                style: gayaTebal,
                              ),
                            ),
                            const SizedBox(width: lebarHapus),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: (MediaQuery.sizeOf(context).height * 0.36)
                              .clamp(200.0, 360.0),
                        ),
                        child: Scrollbar(
                          thumbVisibility: baris.length > 3,
                          child: ListView.builder(
                            primary: false,
                            shrinkWrap: true,
                            itemCount: baris.length,
                            itemBuilder: (context, i) {
                              final b = baris[i];
                              return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.baru
                                          ? Barang.gabungNama(
                                              nama: b.nama,
                                              satuan: b.satuan,
                                              rincian: b.rincian,
                                            )
                                          : (b.nama.isEmpty ? b.kode : b.nama),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: gayaTebal,
                                    ),
                                    Text(
                                      [
                                        if (b.baru) 'baru · id otomatis',
                                        if (!b.baru) b.kode,
                                        if (b.qtySudah > 0)
                                          'di buku ${Uang.angka(b.qtySudah)}',
                                        if (b.nilai > 0)
                                          'Rp ${Uang.angka(b.nilai)}',
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: gaya.copyWith(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: lebarQty,
                                child: TextField(
                                  controller: b.qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  style: gaya,
                                  textAlign: TextAlign.center,
                                  inputFormatters: const [UangFormatRibuan()],
                                  decoration: dekor(hint: '0'),
                                  onChanged: (_) => setLocal(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: lebarHarga,
                                child: TextField(
                                  controller: b.hargaCtrl,
                                  keyboardType: TextInputType.number,
                                  style: gaya,
                                  textAlign: TextAlign.right,
                                  inputFormatters: const [UangFormatRibuan()],
                                  decoration: dekor(hint: '0'),
                                  onChanged: (_) => setLocal(() {}),
                                ),
                              ),
                              SizedBox(
                                width: lebarHapus,
                                child: IconButton(
                                  tooltip: b.qtySudah > 0
                                      ? 'Sudah tersimpan di buku ini. Kosongkan +Qty jika batal tambah.'
                                      : 'Hapus',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: lebarHapus,
                                    minHeight: 32,
                                  ),
                                  iconSize: 18,
                                  onPressed: b.qtySudah > 0
                                      ? null
                                      : () {
                                          b.dispose();
                                          baris.removeAt(i);
                                          setLocal(() {});
                                        },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: b.qtySudah > 0
                                        ? Colors.grey
                                        : Tema.seed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
                FilledButton(
                  onPressed: ongkirProses ? null : simpan,
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
    tunda?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    cariCtrl.dispose();
    namaSupplierCtrl.dispose();
    ongkirCtrl.dispose();
    skuNamaCtrl.dispose();
    skuSatuanCtrl.dispose();
    skuRincianCtrl.dispose();
    skuKategoriCtrl.dispose();
    skuHargaCtrl.dispose();
    skuQtyCtrl.dispose();
    for (final b in baris) {
      b.dispose();
    }
  }

  num _pecahan(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  bool _ya(dynamic v) => v == true || v == 'true' || v == 't';

  Future<
    ({
      bool ada,
      String status,
      int sku,
      int nilai,
      int menunggu,
      List<Map<String, dynamic>> beda,
    })
  >
  _ringkasOpname() async {
    final raw = await _sb.rpc(
      'admin_opname_lihat',
      params: {'p_tanggal': _iso},
    );
    if (raw is! List || raw.isEmpty) {
      return (
        ada: false,
        status: '',
        sku: 0,
        nilai: 0,
        menunggu: 0,
        beda: <Map<String, dynamic>>[],
      );
    }
    final semua = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final status = semua.first['status_opname']?.toString() ?? 'draft';
    final beda = semua.where((r) => _pecahan(r['selisih_qty']) != 0).toList();
    final nilai = beda.fold<int>(0, (a, r) => a + _angka(r['nilai_selisih']));
    final menunggu = beda.where((r) => _ya(r['perlu_konfirmasi'])).length;
    return (
      ada: true,
      status: status,
      sku: beda.length,
      nilai: nilai,
      menunggu: menunggu,
      beda: beda,
    );
  }

  Future<void> _cekOpname() async {
    if (_proses) return;
    if (!await _adaNet()) return;
    setState(() => _proses = true);
    try {
      final ringkas = await _ringkasOpname();
      if (!mounted) return;
      setState(() {
        _opnameAda = ringkas.ada;
        _opnameStatus = ringkas.status;
        _opnameSelisihSku = ringkas.sku;
        _opnameNilaiSelisih = ringkas.nilai;
        _opnameMenunggu = ringkas.menunggu;
        _opnameBeda = ringkas.beda;
      });
      if (!ringkas.ada) {
        umpan(context, 'Belum ada input opname dari aplikasi gudang.', nada: NadaUmpan.kuning);
        return;
      }
      if (ringkas.beda.isEmpty) {
        umpan(context, 'Opname cocok. Tidak ada selisih.', nada: NadaUmpan.hijau);
        return;
      }
      await _dialogSelisihOpname();
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal cek opname.');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Future<void> _dialogSelisihOpname() async {
    if (_opnameBeda.isEmpty) return;
    final kunci = _opnameStatus == 'kunci';
    final ctrl = <String, TextEditingController>{};
    for (final r in _opnameBeda) {
      final kode = r['kode_barang']?.toString() ?? '';
      if (kode.isEmpty) continue;
      final awal = r['qty_dikonfirmasi'] != null
          ? _pecahan(r['qty_dikonfirmasi'])
          : _pecahan(r['stok_fisik']);
      ctrl[kode] = TextEditingController(text: Uang.qty(awal));
    }
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (_, setLocal) {
              Future<void> simpan() async {
                if (!kunci) return;
                final kirim = [
                  for (final e in ctrl.entries)
                    {'kode_barang': e.key, 'qty': Uang.qtyTeks(e.value.text)},
                ];
                try {
                  await _sb.rpc(
                    'admin_opname_konfirmasi',
                    params: {'p_tanggal': _iso, 'p_baris': kirim},
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  final ringkas = await _ringkasOpname();
                  if (!mounted) return;
                  setState(() {
                    _opnameAda = ringkas.ada;
                    _opnameStatus = ringkas.status;
                    _opnameSelisihSku = ringkas.sku;
                    _opnameNilaiSelisih = ringkas.nilai;
                    _opnameMenunggu = ringkas.menunggu;
                    _opnameBeda = ringkas.beda;
                  });
                  umpan(
                    context,
                    'Qty opname dikonfirmasi.',
                    nada: NadaUmpan.hijau,
                  );
                } catch (e) {
                  if (!mounted) return;
                  umpan(context, pesanGagal(e, 'Gagal konfirmasi opname.'));
                }
              }

              return AppDialog(
                title: Text('Selisih opname (${_opnameBeda.length})'),
                content: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kunci
                            ? 'Fisik gudang tidak diubah. Isi qty yang sah ke stok.'
                            : 'Tunggu gudang simpan opname, lalu konfirmasi qty di sini.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final r in _opnameBeda)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${r['nama_barang'] ?? r['kode_barang']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${r['kode_barang']}  ·  sistem ${Uang.qty(_pecahan(r['sisa']))}  ·  '
                                      'fisik ${Uang.qty(_pecahan(r['stok_fisik']))}  ·  '
                                      'selisih ${Uang.qty(_pecahan(r['selisih_qty']))}  ·  '
                                      'Rp ${Uang.angka(_angka(r['nilai_selisih']))}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 72,
                                child: TextField(
                                  controller:
                                      ctrl[r['kode_barang']?.toString() ?? ''],
                                  enabled: kunci,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Qty',
                                    hintStyle: TextStyle(fontSize: 11),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 6,
                                    ),
                                  ),
                                  onChanged: (_) => setLocal(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                  if (kunci)
                    FilledButton(
                      onPressed: simpan,
                      child: const Text('Konfirmasi'),
                    ),
                ],
              );
            },
          );
        },
      );
    } finally {
      for (final c in ctrl.values) {
        c.dispose();
      }
    }
  }

  Future<void> _pilihHari() async {
    if (!await _izinBuangDraf()) return;
    if (!mounted) return;
    var akhir = DateTime.now();
    akhir = DateTime(akhir.year, akhir.month, akhir.day);
    if (_bukuTerbuka && _bukuTanggal.isNotEmpty) {
      final b = DateTime.tryParse(_bukuTanggal);
      if (b != null) {
        akhir = DateTime(b.year, b.month, b.day);
      }
    }
    var awal = DateTime(_hari.year, _hari.month, _hari.day);
    if (awal.isAfter(akhir)) awal = akhir;
    final pilih = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: DateTime(2025),
      lastDate: akhir,
      helpText: 'Buku lama',
    );
    if (pilih == null) return;
    if (!mounted) return;
    _hari = DateTime(pilih.year, pilih.month, pilih.day);
    _ikutiBukuTerbuka =
        _bukuTerbuka && _bukuTanggal.isNotEmpty && _iso == _bukuTanggal;
    await _muatData(layarPenuh: true, buangDraf: true);
  }

  String _selCsv(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(RegExp(r'[;"\n\r]'))) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  Future<void> _unduhHalaman() async {
    final judul = [
      'Rute',
      'Kiriman',
      'Batal',
      'Pending',
      'Actual',
      'Transfer',
      'Mutasi',
      'Tunai',
      'Tunai admin',
      'BOP',
      'Kasbon',
      'Retur',
      'Cek',
    ].join(';');
    String barisDari(Map<String, dynamic> row, String nama) {
      final kasbon = row.containsKey('kasbon_supir')
          ? _angka(row['kasbon_supir']) + _angka(row['kasbon_kenek'])
          : _angka(row['kasbon']);
      return [
        nama,
        _angka(row['kiriman']),
        _angka(row['batal']),
        _angka(row['pending']),
        _angka(row['actual']),
        _angka(row['transfer']),
        _angka(row['transfer_mutasi']),
        _angka(row['tunai']),
        _angka(row['tunai_admin']),
        _angka(row['bop']),
        kasbon,
        _angka(row['retur']),
        row['sudah_setor'] == true ? _angka(row['sesa_cek']) : '',
      ].map(_selCsv).join(';');
    }

    final isi = <String>[judul];
    for (final row in _truk) {
      isi.add(barisDari(row, row['rute_pengirim']?.toString() ?? ''));
    }
    isi.add(barisDari(_jumlahEmpatTim(), 'Jumlah'));
    await Berkas.unduhCsv('setoran_$_iso.csv', isi.join('\n'));
  }

  Future<void> _simpanHalaman() async {
    if (!_kotor) {
      umpan(context, 'Tidak ada perubahan untuk disimpan.', nada: NadaUmpan.kuning);
      return;
    }
    if (!await _adaNet()) return;
    setState(() => _proses = true);
    try {
      for (final rute in _drafTunai.keys) {
        final ok = await _sb.rpc(
          'admin_setoran_simpan_tunai',
          params: {
            'p_tanggal': _iso,
            'p_rute': rute,
            'p_tunai': _drafTunai[rute],
            'p_pecahan': _drafPecahan[rute] ?? const <int>[],
          },
        );
        if (ok != true) throw Exception('tunai');
      }
      if (_mutasiGantiIsi) {
        await _sb.rpc('admin_mutasi_hapus', params: {'p_tanggal': _iso});
        if (_mutasi.isNotEmpty) {
          final urut = [..._mutasi]
            ..sort((a, b) {
              final c = _angka(b['jumlah']).compareTo(_angka(a['jumlah']));
              if (c != 0) return c;
              return _angka(a['id']).compareTo(_angka(b['id']));
            });
          await _sb.rpc(
            'admin_mutasi_unggah',
            params: {
              'p_tanggal': _iso,
              'p_nama_berkas': _namaBerkasMutasi,
              'p_baris': [
                for (final m in urut)
                  {
                    'tanggal_mutasi': m['tanggal_mutasi']?.toString(),
                    'jumlah': _angka(m['jumlah']),
                    'berita': m['berita']?.toString() ?? '',
                    'rekening': m['rekening_alias']?.toString() ?? '',
                  },
              ],
            },
          );
          final raw = await _sb.rpc(
            'admin_mutasi_lihat',
            params: {'p_tanggal': _iso},
          );
          final cloud = raw is List
              ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : <Map<String, dynamic>>[];
          for (var i = 0; i < urut.length && i < cloud.length; i++) {
            final rute = urut[i]['rute_pengirim']?.toString() ?? '';
            await _sb.rpc(
              'admin_mutasi_set_rute',
              params: {'p_id': _angka(cloud[i]['id']), 'p_rute': rute},
            );
          }
        }
      } else {
        for (final m in _mutasi) {
          final id = _angka(m['id']);
          if (id <= 0) continue;
          final rute = m['rute_pengirim']?.toString() ?? '';
          final st = m['status_cocok']?.toString() ?? '';
          final harus = rute.isEmpty ? 'tidak_cocok' : 'cocok';
          if (rute == (_ruteMutasiAwal[id] ?? '') && st == harus) continue;
          await _sb.rpc(
            'admin_mutasi_set_rute',
            params: {'p_id': id, 'p_rute': rute},
          );
        }
      }
      for (final d in _drafMasuk) {
        final ok = await _sb.rpc(
          'admin_barang_masuk_simpan',
          params: {
            'p_tanggal': _iso,
            'p_id_supplier': d.idSupplier,
            'p_baris': d.baris,
            'p_keterangan': '',
          },
        );
        if (ok != true) throw Exception('masuk');
      }
      for (final e in _drafRetur.entries) {
        final ok = await _sb.rpc(
          'admin_retur_item_simpan',
          params: {'p_tanggal': _iso, 'p_rute': e.key, 'p_baris': e.value},
        );
        if (ok != true) throw Exception('retur');
      }
      for (final e in _drafPendingCek.entries) {
        final rute = _drafPendingRute[e.key] ?? '';
        if (rute.isEmpty) continue;
        final ok = await _sb.rpc(
          'admin_setoran_pending_cek_set',
          params: {
            'p_tanggal': _iso,
            'p_id_nota': e.key,
            'p_rute': rute,
            'p_cek': e.value,
          },
        );
        if (ok != true) throw Exception('pending');
      }
      for (final e in _drafBatalCek.entries) {
        final ok = await _sb.rpc(
          'admin_setoran_batal_terima',
          params: {
            'p_tanggal': _iso,
            'p_rute': e.value.rute,
            'p_kunci': e.key,
            'p_qty_fisik': e.value.fisik,
            'p_cek': e.value.cek,
          },
        );
        if (ok != true) throw Exception('batal');
      }
      for (final e in _drafKasbon.entries) {
        final bagian = e.key.split('|');
        if (bagian.length != 2) continue;
        final ok = await _sb.rpc(
          'admin_setoran_simpan_kasbon',
          params: {
            'p_tanggal': _iso,
            'p_rute': bagian[0],
            'p_peran': bagian[1],
            'p_cek': e.value.cek,
            'p_actual': e.value.actual,
          },
        );
        if (ok != true) throw Exception('kasbon');
      }
      if (!mounted) return;
      _resetDraf();
      await _muatData(buangDraf: true);
      if (!mounted) return;
      umpan(context, 'Setoran disimpan ke cloud.', nada: NadaUmpan.hijau);
    } catch (_) {
      if (mounted) {
        umpan(context, 'Gagal menyimpan setoran ke cloud.');
      }
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Future<void> _unggahMutasi() async {
    final teks = await Berkas.pilihCsv();
    if (teks == null) return;
    const nama = 'mutasi.csv';
    final hasil = MutasiCsv.parse(teks);
    if (hasil.error != null) {
      if (!mounted) return;
      umpan(context, hasil.error!);
      return;
    }
    _idMutasiLokal -= hasil.baris.length;
    var id = _idMutasiLokal;
    final baru = <Map<String, dynamic>>[];
    for (final b in hasil.baris) {
      final rute = _ruteDariBerita(b.berita) ?? '';
      baru.add({
        'id': id++,
        'tanggal_mutasi': b.tanggalMutasi,
        'jumlah': b.jumlah,
        'berita': b.berita,
        'rekening_alias': b.rekening.isNotEmpty
            ? b.rekening
            : MutasiCsv.namaDariBerita(b.berita),
        'rute_pengirim': rute,
        'status_cocok': rute.isEmpty ? '' : 'cocok',
      });
    }
    setState(() {
      _kotor = true;
      _mutasiGantiIsi = true;
      _namaBerkasMutasi = nama;
      _pasangMutasiLokal([..._mutasi, ...baru]);
    });
  }

  void _pasangMutasiLokal(List<Map<String, dynamic>> mutasi) {
    mutasi = _saringMutasiKredit(mutasi);
    _mutasi = mutasi;
    _truk = _timpaTransferMutasi(_truk, mutasi);
  }

  Future<void> _hapusMutasi() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: const Text('Hapus mutasi'),
        content: Text('Buang semua mutasi $_judulHari?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya != true) return;
    setState(() {
      _kotor = true;
      _mutasiGantiIsi = true;
      _pasangMutasiLokal([]);
    });
  }

  Future<void> _simpanTunai(String rute, int tunai, List<int> pecahan) async {
    _drafTunai[rute] = tunai;
    _drafPecahan[rute] = pecahan;
    _timpaBarisTruk(rute, {'tunai_admin': tunai, 'pecahan_tunai': pecahan});
    _tandaiKotor();
  }

  Future<void> _dialogTunai(Map<String, dynamic> row) async {
    final rute = row['rute_pengirim']?.toString() ?? '';
    final pecahan = _pecahanTunai;
    final qtyLama = _qtyPecahan(row);
    final pecahanCtrl = List.generate(
      pecahan.length,
      (i) => TextEditingController(
        text: qtyLama[i] == 0 ? '' : Uang.angka(qtyLama[i]),
      ),
    );
    var totalPecahan = 0;
    for (var i = 0; i < pecahan.length; i++) {
      totalPecahan += pecahan[i].nilai * qtyLama[i];
    }
    final pecahanKosong =
        _angka(row['tunai_admin']) > 0 && qtyLama.every((n) => n == 0);

    if (!mounted) {
      for (final c in pecahanCtrl) {
        c.dispose();
      }
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            void hitungPecahan() {
              var n = 0;
              pecahan.asMap().forEach((i, p) {
                n += p.nilai * Uang.angkaTeks(pecahanCtrl[i].text);
              });
              totalPecahan = n;
              setLocal(() {});
            }

            const gaya = TextStyle(fontSize: 12, height: 1.2);
            const lebarKolom = {
              0: FixedColumnWidth(64),
              1: FixedColumnWidth(18),
              2: FixedColumnWidth(52),
              3: FixedColumnWidth(58),
              4: FixedColumnWidth(18),
              5: FixedColumnWidth(80),
            };
            const garis = BorderSide(color: Tema.seed, width: 1);
            final sudut = BorderRadius.circular(8);
            final dekorQty = InputDecoration(
              isDense: true,
              hintText: '0',
              hintStyle: gaya.copyWith(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: sudut,
                borderSide: garis,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: sudut,
                borderSide: garis,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: sudut,
                borderSide: garis,
              ),
            );

            Widget teks(String s, {TextAlign align = TextAlign.left}) {
              return Text(s, style: gaya, textAlign: align);
            }

            return AppDialog(
              title: Text('Tunai $rute'),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Table(
                    columnWidths: lebarKolom,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: List.generate(pecahan.length, (i) {
                      final p = pecahan[i];
                      final hasil = p.nilai * Uang.angkaTeks(pecahanCtrl[i].text);
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: TextField(
                              controller: pecahanCtrl[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: gaya,
                              inputFormatters: const [UangFormatRibuan(kosong: '')],
                              onChanged: (_) => hitungPecahan(),
                              decoration: dekorQty,
                            ),
                          ),
                          teks('×', align: TextAlign.center),
                          teks(p.jenis),
                          teks(p.label, align: TextAlign.right),
                          teks('=', align: TextAlign.center),
                          _uangSel(hasil),
                        ],
                      );
                    }),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.6),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tunai admin',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 18,
                        child: teks('=', align: TextAlign.center),
                      ),
                      SizedBox(
                        width: 80,
                        child: _uangSel(totalPecahan, tebal: true),
                      ),
                    ],
                  ),
                  if (pecahanKosong)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Total tersimpan Rp ${Uang.angka(_angka(row['tunai_admin']))}. '
                        'Rincian pecahan belum ada; isi lalu simpan.',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(72, 36),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _simpanTunai(
                      rute,
                      totalPecahan,
                      List.generate(
                        pecahan.length,
                        (i) => Uang.angkaTeks(pecahanCtrl[i].text),
                      ),
                    );
                  },
                  child: const Text('Pakai'),
                ),
              ],
            );
          },
        );
      },
    );
    for (final c in pecahanCtrl) {
      c.dispose();
    }
  }

  Future<void> _dialogTunaiJumlah() async {
    final qty = List<int>.filled(_pecahanTunai.length, 0);
    for (final row in _truk) {
      final pecahan = _qtyPecahan(row);
      for (var i = 0; i < qty.length && i < pecahan.length; i++) {
        qty[i] += pecahan[i];
      }
    }
    var total = 0;
    for (var i = 0; i < _pecahanTunai.length; i++) {
      total += _pecahanTunai[i].nilai * qty[i];
    }
    if (!mounted) return;
    const gaya = TextStyle(fontSize: 12, height: 1.2);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AppDialog(
          title: const Text('Tunai admin semua rute'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(52),
                  1: FixedColumnWidth(18),
                  2: FixedColumnWidth(52),
                  3: FixedColumnWidth(58),
                  4: FixedColumnWidth(18),
                  5: FixedColumnWidth(80),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  for (var i = 0; i < _pecahanTunai.length; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            Uang.angka(qty[i]),
                            textAlign: TextAlign.center,
                            style: gaya,
                          ),
                        ),
                        Text('×', style: gaya, textAlign: TextAlign.center),
                        Text(_pecahanTunai[i].jenis, style: gaya),
                        Text(
                          _pecahanTunai[i].label,
                          style: gaya,
                          textAlign: TextAlign.right,
                        ),
                        Text('=', style: gaya, textAlign: TextAlign.center),
                        _uangSel(_pecahanTunai[i].nilai * qty[i]),
                      ],
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, thickness: 0.6),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tunai admin',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 18,
                    child: Text('=', style: gaya, textAlign: TextAlign.center),
                  ),
                  SizedBox(width: 80, child: _uangSel(total, tebal: true)),
                ],
              ),
              const SizedBox(height: 8),
              for (final row in _truk)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _barisNilai(
                    row['rute_pengirim']?.toString() ?? '',
                    row['tunai_admin'],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogNota({required bool pending, String? rute}) async {
    if (!await _adaNet()) return;
    final daftarRute = (rute == null || rute.isEmpty)
        ? List<String>.from(_rute)
        : [rute];
    final semua = daftarRute.length > 1;
    List<Map<String, dynamic>> nota = [];
    try {
      for (final r in daftarRute) {
        final raw = await _sb.rpc(
          'admin_setoran_nota',
          params: {'p_tanggal': _iso, 'p_rute': r},
        );
        if (raw is! List) continue;
        for (final e in raw) {
          final m = Map<String, dynamic>.from(e as Map);
          m['rute_pengirim'] = r;
          nota.add(m);
        }
      }
    } catch (_) {
      if (!mounted) return;
      umpan(context, semua
            ? 'Gagal memuat nota semua rute.'
            : 'Gagal memuat nota ${daftarRute.first}.');
      return;
    }
    if (pending) {
      nota = nota.where((n) => n['pending'] == true).toList();
    } else {
      nota = nota
          .where((n) => n['status']?.toString() == 'batal')
          .toList();
    }
    if (!mounted) return;
    if (pending && nota.isNotEmpty) {
      try {
        final rawCek = await _sb.rpc(
          'admin_setoran_pending_cek_lihat',
          params: {'p_tanggal': _iso},
        );
        final cek = <String>{};
        if (rawCek is List) {
          for (final e in rawCek) {
            if (e is! Map) continue;
            final id = (e['id_nota']?.toString() ?? '').trim();
            if (id.isNotEmpty) cek.add(id);
          }
        }
        for (final n in nota) {
          final id = (n['id_nota']?.toString() ?? '').trim();
          n['dicek'] = id.isNotEmpty && cek.contains(id);
          if (id.isNotEmpty && _drafPendingCek.containsKey(id)) {
            n['dicek'] = _drafPendingCek[id];
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        Widget tabelNota(void Function(void Function())? setLocal) {
          return DataTable(
            border: _garisKolom,
            columnSpacing: 12,
            horizontalMargin: 8,
            headingRowHeight: 36,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 44,
            columns: [
              if (pending)
                const DataColumn(
                  headingRowAlignment: MainAxisAlignment.center,
                  label: SizedBox(width: 28),
                ),
              if (semua)
                const DataColumn(
                  headingRowAlignment: MainAxisAlignment.center,
                  label: Text('Rute'),
                ),
              const DataColumn(
                headingRowAlignment: MainAxisAlignment.center,
                label: Text('Pelanggan'),
              ),
              const DataColumn(
                headingRowAlignment: MainAxisAlignment.center,
                label: Text('Nota'),
              ),
              if (!pending)
                const DataColumn(
                  headingRowAlignment: MainAxisAlignment.center,
                  label: Text('Status'),
                ),
              const DataColumn(
                headingRowAlignment: MainAxisAlignment.center,
                numeric: true,
                label: Text('Packed'),
              ),
              if (!pending)
                const DataColumn(
                  headingRowAlignment: MainAxisAlignment.center,
                  numeric: true,
                  label: Text('Actual'),
                ),
              if (!pending)
                const DataColumn(
                  headingRowAlignment: MainAxisAlignment.center,
                  numeric: true,
                  label: Text('Batal'),
                ),
            ],
            rows: nota.map((n) {
              final selPending = n['pending'] == true;
              final selNota = DataCell(
                Tooltip(
                  message: 'Rincian barang',
                  child: Text(
                    '${n['id_nota'] ?? ''}',
                    style: const TextStyle(
                      color: Tema.seed,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                onTap: () =>
                    pending ? _dialogRincianPending(n) : _dialogRincianBatal(n),
              );
              return DataRow(
                cells: [
                  if (pending)
                    DataCell(
                      Checkbox(
                        value: n['dicek'] == true,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: _proses || setLocal == null
                            ? null
                            : (v) {
                                final id = (n['id_nota']?.toString() ?? '')
                                    .trim();
                                final ruteNota =
                                    n['rute_pengirim']?.toString() ?? '';
                                if (id.isEmpty || ruteNota.isEmpty) return;
                                final cek = v ?? false;
                                n['dicek'] = cek;
                                _drafPendingCek[id] = cek;
                                _drafPendingRute[id] = ruteNota;
                                _timpaPendingDicekDariNota(nota, daftarRute);
                                _tandaiKotor();
                                setLocal(() {});
                              },
                      ),
                    ),
                  if (semua)
                    DataCell(Text(n['rute_pengirim']?.toString() ?? '')),
                  DataCell(Text('${n['nama_pelanggan'] ?? '-'}')),
                  selNota,
                  if (!pending)
                    DataCell(
                      Text(selPending ? 'pending' : '${n['status'] ?? ''}'),
                    ),
                  DataCell(Text(Uang.angka(n['packed']))),
                  if (!pending) DataCell(Text(Uang.angka(n['actual']))),
                  if (!pending) DataCell(Text(Uang.angka(n['batal']))),
                ],
              );
            }).toList(),
          );
        }

        Widget isiDialog(void Function(void Function())? setLocal) {
          return AppDialog(
            title: Text(
              pending
                  ? (semua
                        ? 'Nota pending semua rute'
                        : 'Nota pending ${daftarRute.first}')
                  : (semua
                        ? 'Nota batal semua rute'
                        : 'Nota batal ${daftarRute.first}'),
            ),
            content: nota.isEmpty
                ? Text(
                    pending
                        ? 'Tidak ada nota pending di buku ini.'
                        : 'Tidak ada nota batal di buku ini.',
                  )
                : tabelNota(setLocal),
            actions: [
              TextButton.icon(
                onPressed: nota.isEmpty
                    ? null
                    : () => pending
                          ? _dialogSemuaItemPending(
                              semua ? null : daftarRute.first,
                            )
                          : _dialogSemuaItemBatal(
                              semua ? null : daftarRute.first,
                            ),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text(
                  pending ? 'Semua item pending' : 'Semua item batal',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          );
        }

        if (!pending) return isiDialog(null);
        return StatefulBuilder(
          builder: (context, setLocal) => isiDialog(setLocal),
        );
      },
    );
    if (mounted) setState(() {});
  }

  String _statusTokoDimuat(List<Map<String, dynamic>> nota) {
    var dikirim = false;
    var pending = false;
    var terkirim = false;
    var batal = false;
    for (final n in nota) {
      if (n['pending'] == true) pending = true;
      final st = n['status']?.toString();
      if (st == 'dikirim') dikirim = true;
      if (st == 'terkirim') terkirim = true;
      if (st == 'batal') batal = true;
    }
    if (dikirim) return 'dikirim';
    if (pending) return 'pending';
    if (terkirim) return 'terkirim';
    if (batal) return 'batal';
    return '-';
  }

  Future<void> _dialogTokoDikirim(String rute) async {
    if (rute.isEmpty) return;
    if (!await _adaNet()) return;
    List<Map<String, dynamic>> nota = [];
    final returToko = <String, int>{};
    final namaDariRetur = <String, String>{};
    try {
      final hasil = await Future.wait([
        _sb.rpc(
          'admin_setoran_nota',
          params: {'p_tanggal': _iso, 'p_rute': rute},
        ),
        _sb.rpc(
          'admin_retur_toko_lihat',
          params: {'p_tanggal': _iso, 'p_rute': rute},
        ),
      ]);
      final rawNota = hasil[0];
      if (rawNota is List) {
        for (final e in rawNota) {
          if (e is Map) nota.add(Map<String, dynamic>.from(e));
        }
      }
      final rawRetur = hasil[1];
      if (rawRetur is List) {
        for (final e in rawRetur) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final kunci = (m['id_pelanggan']?.toString() ?? '').trim();
          if (kunci.isEmpty) continue;
          returToko[kunci] = (returToko[kunci] ?? 0) + _angka(m['nilai']);
          final nama = (m['nama_toko']?.toString() ?? '').trim();
          if (nama.isNotEmpty) namaDariRetur[kunci] = nama;
        }
      }
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat toko $rute.');
      return;
    }

    final grup = <String, List<Map<String, dynamic>>>{};
    final namaToko = <String, String>{};
    for (final n in nota) {
      final kode = (n['kode_pelanggan']?.toString() ?? '').trim();
      final nama = (n['nama_pelanggan']?.toString() ?? '').trim();
      final kunci = kode.isNotEmpty ? kode : (nama.isEmpty ? '-' : nama);
      grup.putIfAbsent(kunci, () => []).add(n);
      namaToko[kunci] = nama.isEmpty ? kunci : nama;
    }
    for (final e in returToko.entries) {
      if (grup.containsKey(e.key)) continue;
      grup[e.key] = [];
      namaToko[e.key] = namaDariRetur[e.key] ?? e.key;
    }

    final baris = [
      for (final e in grup.entries)
        (
          nama: namaToko[e.key] ?? e.key,
          nota: e.value.length,
          notaList: e.value,
          order: e.value.fold<int>(0, (a, n) => a + _angka(n['nilai_order'])),
          packed: e.value.fold<int>(0, (a, n) => a + _angka(n['packed'])),
          batal: e.value.fold<int>(0, (a, n) => a + _angka(n['batal'])),
          retur: returToko[e.key] ?? 0,
          actual: e.value.fold<int>(0, (a, n) => a + _angka(n['actual'])),
          status: _statusTokoDimuat(e.value),
        ),
    ]..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

    if (!mounted) return;
    final filter = List.generate(8, (_) => TextEditingController());
    var sortKolom = 0;
    var sortNaik = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setLocal) {
              bool cocok(String q, String teks, [int? n]) {
                final f = q.trim().toLowerCase();
                if (f.isEmpty) return true;
                if (teks.toLowerCase().contains(f)) return true;
                if (n != null) {
                  final digit = f.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digit.isNotEmpty && n.toString().contains(digit)) {
                    return true;
                  }
                  if (Uang.angka(n).toLowerCase().contains(f)) return true;
                }
                return false;
              }

              int banding(a, b) {
                final r = switch (sortKolom) {
                  0 => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
                  1 => a.nota.compareTo(b.nota),
                  2 => a.order.compareTo(b.order),
                  3 => a.packed.compareTo(b.packed),
                  4 => a.batal.compareTo(b.batal),
                  5 => a.retur.compareTo(b.retur),
                  6 => a.actual.compareTo(b.actual),
                  _ => a.status.toLowerCase().compareTo(b.status.toLowerCase()),
                };
                return sortNaik ? r : -r;
              }

              final tampil = baris.where((b) {
                return cocok(filter[0].text, b.nama) &&
                    cocok(filter[1].text, '${b.nota}', b.nota) &&
                    cocok(filter[2].text, Uang.angka(b.order), b.order) &&
                    cocok(filter[3].text, Uang.angka(b.packed), b.packed) &&
                    cocok(filter[4].text, Uang.angka(b.batal), b.batal) &&
                    cocok(filter[5].text, Uang.angka(b.retur), b.retur) &&
                    cocok(filter[6].text, Uang.angka(b.actual), b.actual) &&
                    cocok(filter[7].text, b.status);
              }).toList()
                ..sort(banding);

              final jumNota = tampil.fold<int>(0, (a, b) => a + b.nota);
              final jumOrder = tampil.fold<int>(0, (a, b) => a + b.order);
              final jumPacked = tampil.fold<int>(0, (a, b) => a + b.packed);
              final jumBatal = tampil.fold<int>(0, (a, b) => a + b.batal);
              final jumRetur = tampil.fold<int>(0, (a, b) => a + b.retur);
              final jumActual = tampil.fold<int>(0, (a, b) => a + b.actual);

              Widget judulFilter(
                String judul,
                TextEditingController ctrl,
                int indeks, {
                double lebar = 92,
              }) {
                final aktif = sortKolom == indeks;
                return SizedBox(
                  width: lebar,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          setLocal(() {
                            if (sortKolom == indeks) {
                              sortNaik = !sortNaik;
                            } else {
                              sortKolom = indeks;
                              sortNaik = true;
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                judul,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              aktif
                                  ? (sortNaik
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                  : Icons.unfold_more,
                              size: 14,
                              color: aktif ? Tema.seed : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: ctrl,
                        style: const TextStyle(fontSize: 12, height: 1.1),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Filter',
                          hintStyle: TextStyle(fontSize: 11),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                    ],
                  ),
                );
              }

              DataColumn kolom(
                String judul,
                TextEditingController ctrl,
                int indeks, {
                bool angka = false,
                double lebar = 92,
              }) {
                return DataColumn(
                  headingRowAlignment: MainAxisAlignment.center,
                  numeric: angka,
                  label: judulFilter(judul, ctrl, indeks, lebar: lebar),
                );
              }

              const gayaJumlah = TextStyle(fontWeight: FontWeight.bold);

              DataCell uang(int n, {bool tebal = false}) => DataCell(
                Text(
                  Uang.angka(n),
                  textAlign: TextAlign.right,
                  style: tebal ? gayaJumlah : null,
                ),
              );

              return AppDialog(
                title: Text('Toko dimuat $rute'),
                content: baris.isEmpty
                    ? const Text(
                        'Tidak ada toko yang notanya di buku ini.',
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: _garisKolom,
                          columnSpacing: 12,
                          horizontalMargin: 8,
                          headingRowHeight: 72,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 44,
                          columns: [
                            kolom('Toko', filter[0], 0, lebar: 160),
                            kolom('Nota', filter[1], 1, angka: true, lebar: 72),
                            kolom('Order', filter[2], 2, angka: true),
                            kolom('Packed', filter[3], 3, angka: true),
                            kolom('Batal', filter[4], 4, angka: true),
                            kolom('Retur', filter[5], 5, angka: true),
                            kolom('Actual', filter[6], 6, angka: true),
                            kolom('Status', filter[7], 7, lebar: 88),
                          ],
                          rows: [
                            for (final b in tampil)
                              DataRow(
                                cells: [
                                  DataCell(
                                    Tooltip(
                                      message: 'Rincian nota',
                                      child: Text(
                                        b.nama,
                                        style: const TextStyle(
                                          color: Tema.seed,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    onTap: b.notaList.isEmpty
                                        ? null
                                        : () => _dialogNotaToko(
                                            rute: rute,
                                            namaToko: b.nama,
                                            nota: b.notaList,
                                          ),
                                  ),
                                  uang(b.nota),
                                  uang(b.order),
                                  uang(b.packed),
                                  uang(b.batal),
                                  uang(b.retur),
                                  uang(b.actual),
                                  DataCell(Text(b.status)),
                                ],
                              ),
                            DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    'Jumlah (${tampil.length})',
                                    style: gayaJumlah,
                                  ),
                                ),
                                uang(jumNota, tebal: true),
                                uang(jumOrder, tebal: true),
                                uang(jumPacked, tebal: true),
                                uang(jumBatal, tebal: true),
                                uang(jumRetur, tebal: true),
                                uang(jumActual, tebal: true),
                                const DataCell(Text('')),
                              ],
                            ),
                          ],
                        ),
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      for (final c in filter) {
        c.dispose();
      }
    }
  }

  String _statusSatuNota(Map<String, dynamic> n) {
    if (n['pending'] == true) return 'pending';
    final st = (n['status']?.toString() ?? '').trim();
    return st.isEmpty ? '-' : st;
  }

  Future<List<Map<String, dynamic>>> _muatItemNota(String id) async {
    Future<List<Map<String, dynamic>>> ambil(String rpc) async {
      final raw = await _sb.rpc(rpc, params: {'p_id_nota': id});
      if (raw is! List) return [];
      return [
        for (final e in raw)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    }

    final packed = await ambil('admin_setoran_nota_item');
    if (packed.isNotEmpty) return packed;
    return ambil('admin_setoran_nota_item_batal');
  }

  Future<void> _dialogNotaToko({
    required String rute,
    required String namaToko,
    required List<Map<String, dynamic>> nota,
  }) async {
    if (!mounted) return;
    final urut = [...nota]..sort((a, b) {
      final ia = (a['id_nota']?.toString() ?? '');
      final ib = (b['id_nota']?.toString() ?? '');
      return ia.compareTo(ib);
    });
    final jumOrder = urut.fold<int>(0, (a, n) => a + _angka(n['nilai_order']));
    final jumPacked = urut.fold<int>(0, (a, n) => a + _angka(n['packed']));
    final jumBatal = urut.fold<int>(0, (a, n) => a + _angka(n['batal']));
    final jumActual = urut.fold<int>(0, (a, n) => a + _angka(n['actual']));
    const gayaJumlah = TextStyle(fontWeight: FontWeight.bold);

    DataCell uang(int n, {bool tebal = false}) => DataCell(
      Text(
        Uang.angka(n),
        textAlign: TextAlign.right,
        style: tebal ? gayaJumlah : null,
      ),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AppDialog(
          title: Text('Nota $namaToko'),
          content: urut.isEmpty
              ? const Text('Tidak ada nota untuk toko ini.')
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: _garisKolom,
                    columnSpacing: 12,
                    horizontalMargin: 8,
                    headingRowHeight: 36,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 44,
                    columns: const [
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        label: Text('Nota'),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        label: Text('Status'),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        numeric: true,
                        label: Text('Order'),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        numeric: true,
                        label: Text('Packed'),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        numeric: true,
                        label: Text('Batal'),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        numeric: true,
                        label: Text('Actual'),
                      ),
                    ],
                    rows: [
                      for (final n in urut)
                        DataRow(
                          cells: [
                            DataCell(
                              Tooltip(
                                message: 'Rincian barang',
                                child: Text(
                                  '${n['id_nota'] ?? ''}',
                                  style: const TextStyle(
                                    color: Tema.seed,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => _dialogRincianNotaToko(n),
                            ),
                            DataCell(Text(_statusSatuNota(n))),
                            uang(_angka(n['nilai_order'])),
                            uang(_angka(n['packed'])),
                            uang(_angka(n['batal'])),
                            uang(_angka(n['actual'])),
                          ],
                        ),
                      DataRow(
                        cells: [
                          DataCell(
                            Text('Jumlah (${urut.length})', style: gayaJumlah),
                          ),
                          const DataCell(Text('')),
                          uang(jumOrder, tebal: true),
                          uang(jumPacked, tebal: true),
                          uang(jumBatal, tebal: true),
                          uang(jumActual, tebal: true),
                        ],
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton.icon(
              onPressed: urut.isEmpty
                  ? null
                  : () => _dialogBarangToko(
                      rute: rute,
                      namaToko: namaToko,
                      nota: urut,
                    ),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('Barang toko'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _dialogRincianNotaToko(Map<String, dynamic> nota) async {
    final id = (nota['id_nota']?.toString() ?? '').trim();
    if (id.isEmpty) return;
    if (!await _adaNet()) return;
    if (!mounted) return;
    List<Map<String, dynamic>> items = [];
    try {
      items = await _muatItemNota(id);
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat rincian $id.');
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      umpan(context, 'Rincian barang belum bisa ditampilkan.', nada: NadaUmpan.kuning);
      return;
    }
    await _dialogTabelBarang(
      judul: 'Barang $id',
      atas: [
        Text(
          '${nota['nama_pelanggan'] ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          '${_statusSatuNota(nota)} · Packed Rp ${Uang.angka(nota['packed'])}'
          '${_angka(nota['batal']) > 0 ? ' · Batal Rp ${Uang.angka(nota['batal'])}' : ''}',
        ),
      ],
      items: items,
      kolomNilai: 'Packed',
    );
  }

  Future<void> _dialogBarangToko({
    required String rute,
    required String namaToko,
    required List<Map<String, dynamic>> nota,
  }) async {
    if (!await _adaNet()) return;
    if (!mounted) return;
    final idList = [
      for (final n in nota)
        (n['id_nota']?.toString() ?? '').trim(),
    ].where((id) => id.isNotEmpty).toList();
    if (idList.isEmpty) {
      umpan(context, 'Tidak ada nota untuk dibuka rinciannya.', nada: NadaUmpan.kuning);
      return;
    }
    final gabung = <String, Map<String, dynamic>>{};
    try {
      const jejak = 8;
      for (var i = 0; i < idList.length; i += jejak) {
        final potong = idList.sublist(
          i,
          i + jejak > idList.length ? idList.length : i + jejak,
        );
        final hasil = await Future.wait(potong.map(_muatItemNota));
        for (final items in hasil) {
          for (final it in items) {
            final kunci = _kunciBarang(it);
            final lama = gabung[kunci];
            if (lama == null) {
              gabung[kunci] = Map<String, dynamic>.from(it)
                ..['kunci_barang'] = kunci;
            } else {
              lama['qty'] = _angka(lama['qty']) + _angka(it['qty']);
              lama['packed'] = _angka(lama['packed']) + _angka(it['packed']);
            }
          }
        }
      }
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat barang $namaToko.');
      return;
    }
    final items = gabung.values.toList()
      ..sort(
        (a, b) => _labelBarang(a).toLowerCase().compareTo(
          _labelBarang(b).toLowerCase(),
        ),
      );
    if (!mounted) return;
    if (items.isEmpty) {
      umpan(context, 'Barang toko belum bisa ditampilkan.', nada: NadaUmpan.kuning);
      return;
    }
    await _dialogTabelBarang(
      judul: 'Barang $namaToko',
      atas: [
        Text(rute, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('${idList.length} nota · Packed Rp ${Uang.angka(items.fold<int>(0, (a, it) => a + _angka(it['packed'])))}'),
      ],
      items: items,
      kolomNilai: 'Packed',
    );
  }

  String _kunciKasbon(String rute, String peran) => '$rute|$peran';

  String _labelKasbon(Map<String, dynamic> row, String peran) {
    final peranTeks = peran == 'supir' ? 'Supir' : 'Kenek';
    final nama = peran == 'supir'
        ? (row['nama_supir']?.toString() ?? '').trim()
        : (row['nama_kenek']?.toString() ?? '').trim();
    if (nama.isEmpty) return peranTeks;
    return '$peranTeks $nama';
  }

  int _kasbonKlaim(Map<String, dynamic> row, String peran) =>
      _angka(row[peran == 'supir' ? 'kasbon_supir_klaim' : 'kasbon_kenek_klaim']);

  int _kasbonKlaimTotal(Map<String, dynamic> row) {
    if (row.containsKey('kasbon_klaim')) return _angka(row['kasbon_klaim']);
    if (row.containsKey('kasbon_supir_klaim') ||
        row.containsKey('kasbon_kenek_klaim')) {
      return _kasbonKlaim(row, 'supir') + _kasbonKlaim(row, 'kenek');
    }
    return _angka(row['kasbon_supir']) + _angka(row['kasbon_kenek']);
  }

  int _kasbonBatal(Map<String, dynamic> row, String peran) =>
      _angka(row[peran == 'supir' ? 'kasbon_batal_supir' : 'kasbon_batal_kenek']);

  ({bool cek, int actual}) _kasbonBaris(
    Map<String, dynamic> row,
    String peran,
  ) {
    final rute = row['rute_pengirim']?.toString() ?? '';
    final draf = _drafKasbon[_kunciKasbon(rute, peran)];
    if (draf != null) return draf;
    final cek = row[peran == 'supir' ? 'kasbon_supir_cek' : 'kasbon_kenek_cek'] ==
        true;
    final actual = _angka(
      row[peran == 'supir' ? 'kasbon_supir_actual' : 'kasbon_kenek_actual'],
    );
    return (cek: cek, actual: actual);
  }

  void _hitungKasbonRow(Map<String, dynamic> row) {
    for (final peran in ['supir', 'kenek']) {
      final isi = _kasbonBaris(row, peran);
      final pakai = isi.cek ? isi.actual : 0;
      row[peran == 'supir' ? 'kasbon_supir' : 'kasbon_kenek'] =
          pakai + _kasbonBatal(row, peran);
    }
    final klaimS = _kasbonKlaim(row, 'supir');
    final klaimK = _kasbonKlaim(row, 'kenek');
    final cekS = _kasbonBaris(row, 'supir').cek;
    final cekK = _kasbonBaris(row, 'kenek').cek;
    row['kasbon_dicek'] = (klaimS == 0 || cekS) && (klaimK == 0 || cekK);
    _selesaiHitung(row);
  }

  void _ubahKasbonDraf(
    Map<String, dynamic> row,
    String peran, {
    bool? cek,
    int? actual,
  }) {
    final rute = row['rute_pengirim']?.toString() ?? '';
    if (rute.isEmpty) return;
    final lama = _kasbonBaris(row, peran);
    final cekBaru = cek ?? lama.cek;
    var actualBaru = actual ?? lama.actual;
    if (cek == true && actual == null && actualBaru <= 0) {
      actualBaru = _kasbonKlaim(row, peran);
    }
    _drafKasbon[_kunciKasbon(rute, peran)] = (
      cek: cekBaru,
      actual: actualBaru < 0 ? 0 : actualBaru,
    );
    final i = _truk.indexWhere((r) => r['rute_pengirim']?.toString() == rute);
    if (i >= 0) {
      final next = Map<String, dynamic>.from(_truk[i]);
      _hitungKasbonRow(next);
      final daftar = List<Map<String, dynamic>>.from(_truk);
      daftar[i] = next;
      _truk = daftar;
    }
    _tandaiKotor();
  }

  InputDecoration _dekorIsianAdmin({String? hint}) {
    const garis = BorderSide(color: Tema.seed, width: 1);
    final sudut = BorderRadius.circular(8);
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: sudut, borderSide: garis),
      enabledBorder: OutlineInputBorder(borderRadius: sudut, borderSide: garis),
      focusedBorder: OutlineInputBorder(borderRadius: sudut, borderSide: garis),
      disabledBorder: OutlineInputBorder(
        borderRadius: sudut,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _isianAdmin({
    required double lebar,
    required TextAlign align,
    Key? key,
    String? initial,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    const gaya = TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.bold,
    );
    return Align(
      alignment: align == TextAlign.center
          ? Alignment.center
          : Alignment.centerRight,
      child: SizedBox(
        width: lebar,
        child: TextFormField(
          key: key,
          initialValue: initial,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textAlign: align,
          style: gaya,
          inputFormatters: const [UangFormatRibuan(kosong: '')],
          decoration: _dekorIsianAdmin(hint: '0'),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _isiDialogKasbon(
    List<Map<String, dynamic>> truk,
    void Function(void Function()) setLocal,
  ) {
    const gayaTebal = TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.bold,
    );
    final semua = truk.length > 1;
    var total = 0;
    final baris = <DataRow>[];
    for (final asal in truk) {
      final rute = asal['rute_pengirim']?.toString() ?? '';
      final row = _truk.firstWhere(
        (r) => r['rute_pengirim']?.toString() == rute,
        orElse: () => asal,
      );
      for (final peran in ['supir', 'kenek']) {
        final isi = _kasbonBaris(row, peran);
        final klaim = _kasbonKlaim(row, peran);
        if (isi.cek) total += isi.actual;
        baris.add(
          DataRow(
            cells: [
              DataCell(
                Checkbox(
                  value: isi.cek,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: _proses
                      ? null
                      : (v) {
                          _ubahKasbonDraf(row, peran, cek: v ?? false);
                          setLocal(() {});
                        },
                ),
              ),
              if (semua) DataCell(Text(rute)),
              DataCell(Text(_labelKasbon(row, peran))),
              DataCell(Text(Uang.angka(klaim))),
              DataCell(
                _isianAdmin(
                  lebar: 100,
                  align: TextAlign.right,
                  key: ValueKey('${_kunciKasbon(rute, peran)}-${isi.cek}'),
                  initial: isi.actual == 0 ? '' : Uang.angka(isi.actual),
                  enabled: !_proses,
                  onChanged: (t) {
                    _ubahKasbonDraf(
                      row,
                      peran,
                      cek: true,
                      actual: Uang.angkaTeks(t),
                    );
                    setLocal(() {});
                  },
                ),
              ),
            ],
          ),
        );
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Klaim = kasbon pengirim. Actual = kasbon admin. Gaji memakai actual yang dicentang.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 8),
        DataTable(
          border: _garisKolom,
          columnSpacing: 12,
          horizontalMargin: 8,
          headingRowHeight: 36,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 52,
          columns: [
            const DataColumn(
              headingRowAlignment: MainAxisAlignment.center,
              label: SizedBox(width: 28),
            ),
            if (semua)
              const DataColumn(
                headingRowAlignment: MainAxisAlignment.center,
                label: Text('Rute'),
              ),
            const DataColumn(
              headingRowAlignment: MainAxisAlignment.center,
              label: Text('Orang'),
            ),
            const DataColumn(
              headingRowAlignment: MainAxisAlignment.center,
              numeric: true,
              label: Text('Klaim'),
            ),
            const DataColumn(
              headingRowAlignment: MainAxisAlignment.center,
              numeric: true,
              label: SizedBox(
                width: 100,
                child: Text('Actual', textAlign: TextAlign.right),
              ),
            ),
          ],
          rows: baris,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, thickness: 0.6),
        ),
        Row(
          children: [
            const Expanded(child: Text('Kasbon', style: gayaTebal)),
            const SizedBox(
              width: 18,
              child: Text('=', textAlign: TextAlign.center),
            ),
            SizedBox(width: 80, child: _uangSel(total, tebal: true)),
          ],
        ),
      ],
    );
  }

  Future<void> _dialogKasbon(Map<String, dynamic> row) async {
    final rute = row['rute_pengirim']?.toString() ?? '';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AppDialog(
              title: Text('Kasbon $rute'),
              content: _isiDialogKasbon([row], setLocal),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _dialogKasbonJumlah() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AppDialog(
              title: const Text('Kasbon semua rute'),
              content: SingleChildScrollView(
                child: _isiDialogKasbon(_truk, setLocal),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _dialogRetur(Map<String, dynamic> row) async {
    if (!await _adaNet()) return;
    final rute = row['rute_pengirim']?.toString() ?? '';
    final baris = <_BarisCocokRetur>[];
    try {
      final raw = await _sb.rpc(
        'admin_retur_item_lihat',
        params: {'p_tanggal': _iso, 'p_rute': rute},
      );
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          baris.add(
            _BarisCocokRetur(
              kode: m['kode_barang']?.toString() ?? '',
              nama: m['nama_barang']?.toString() ?? '',
              qty: _angka(m['qty']),
              qtyKlaim: _angka(m['qty']),
              qtyFisik: _angka(m['qty_fisik']),
              nilai: _angka(m['nilai']),
              cek: _angka(m['qty_fisik']) > 0,
            ),
          );
        }
      }
    } catch (_) {}

    final dariToko = <Map<String, dynamic>>[];
    try {
      final raw = await _sb.rpc(
        'admin_retur_toko_lihat',
        params: {'p_tanggal': _iso, 'p_rute': rute},
      );
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) dariToko.add(Map<String, dynamic>.from(e));
        }
      }
    } catch (_) {}

    final drafRetur = _drafRetur[rute];
    if (drafRetur != null) {
      for (final b in baris) {
        b.dispose();
      }
      baris
        ..clear()
        ..addAll([
          for (final m in drafRetur)
            _BarisCocokRetur(
              kode: m['kode_barang']?.toString() ?? '',
              nama: m['nama_barang']?.toString() ?? '',
              qty: _angka(m['qty']),
              qtyKlaim: _angka(m['qty']),
              qtyFisik: _angka(m['qty_fisik']),
              nilai: _angka(m['nilai']),
              cek: m['cek'] == true || _angka(m['qty_fisik']) > 0,
            ),
        ]);
    }

    if (!mounted) {
      for (final b in baris) {
        b.dispose();
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            int totalQty() =>
                baris.fold<int>(0, (a, b) => a + (b.cek ? b.qtyFisik : 0));
            final nilaiKlaim = dariToko.fold<int>(
              0,
              (a, b) => a + _angka(b['nilai']),
            );

            Future<void> simpan() async {
              final kirim = [
                for (final b in baris)
                  if (b.kode.isNotEmpty)
                    {
                      'kode_barang': b.kode,
                      'nama_barang': b.nama,
                      'qty': b.qtyKlaim,
                      'qty_fisik': b.cek ? b.qtyFisik : 0,
                      'nilai': b.nilai,
                      'cek': b.cek,
                    },
              ];
              _drafRetur[rute] = kirim;
              _timpaBarisTruk(rute, {
                'retur_dicek':
                    baris.any((b) => b.qtyKlaim > 0) &&
                    baris.every((b) => b.qtyKlaim <= 0 || b.cek),
              });
              _tandaiKotor();
              if (ctx.mounted) Navigator.pop(ctx);
            }

            return AppDialog(
              title: Text('Retur $rute · $_judulHari'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _barisNilai('Qty fisik', totalQty()),
                      _barisNilai('Nominal klaim', nilaiKlaim),
                      const SizedBox(height: 8),
                      Text(
                        'Isi buku ini: klaim outlet pengirim, lalu qty yang kembali ke gudang.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (dariToko.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Dari toko',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ..._grupReturToko(dariToko),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Terima fisik gudang',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Centang dan isi qty yang benar-benar kembali. Stok baru berubah di sini.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (baris.isEmpty)
                        Text(
                          'Tidak ada klaim retur di buku ini.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        ...baris.map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: b.cek,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (v) {
                                    b.cek = v ?? false;
                                    if (b.cek && b.qtyFisik <= 0) {
                                      b.fisikCtrl.text = Uang.angka(b.qtyKlaim);
                                    }
                                    setLocal(() {});
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.nama.isEmpty ? b.kode : b.nama}\n'
                                    'Klaim ${Uang.angka(b.qtyKlaim)} · ${Uang.rp(b.nilai)}',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 64,
                                  child: TextField(
                                    controller: b.fisikCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                    inputFormatters: const [UangFormatRibuan()],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText: 'Fisik',
                                      hintStyle: TextStyle(fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                    ),
                                    onChanged: (_) {
                                      if (b.qtyFisik > 0) b.cek = true;
                                      setLocal(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
                FilledButton(onPressed: simpan, child: const Text('Pakai')),
              ],
            );
          },
        );
      },
    );
    for (final b in baris) {
      b.dispose();
    }
  }

  Future<void> _dialogReturJumlah() async {
    if (!await _adaNet()) return;
    List<Map<String, dynamic>> items = [];
    try {
      items = await _gabungItemHari(
        rpc: 'admin_retur_item_lihat',
        daftarRute: List<String>.from(_rute),
      );
    } catch (_) {}
    final dariToko = <Map<String, dynamic>>[];
    for (final r in _rute) {
      try {
        final raw = await _sb.rpc(
          'admin_retur_toko_lihat',
          params: {'p_tanggal': _iso, 'p_rute': r},
        );
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) dariToko.add(Map<String, dynamic>.from(e));
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final totalQty = items.fold<int>(0, (a, it) => a + _angka(it['qty']));
    final totalNilai = dariToko.fold<int>(0, (a, b) => a + _angka(b['nilai']));
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AppDialog(
          title: Text('Retur semua rute · $_judulHari'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _barisNilai('Qty klaim', totalQty),
                  _barisNilai('Nominal klaim', totalNilai),
                  const SizedBox(height: 8),
                  Text(
                    'Isi buku ini: klaim outlet pengirim, per rute.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (dariToko.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Dari toko',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    ..._grupReturToko(dariToko),
                  ],
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    Text(
                      'Belum ada barang retur di buku ini.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    )
                  else
                    DataTable(
                      border: _garisKolom,
                      columnSpacing: 12,
                      horizontalMargin: 8,
                      headingRowHeight: 36,
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 44,
                      columns: const [
                        DataColumn(
                          headingRowAlignment: MainAxisAlignment.center,
                          label: Text('Barang'),
                        ),
                        DataColumn(
                          headingRowAlignment: MainAxisAlignment.center,
                          numeric: true,
                          label: Text('Qty'),
                        ),
                        DataColumn(
                          headingRowAlignment: MainAxisAlignment.center,
                          numeric: true,
                          label: Text('Nilai'),
                        ),
                      ],
                      rows: items
                          .map(
                            (it) => DataRow(
                              cells: [
                                DataCell(Text(_labelBarang(it))),
                                DataCell(Text('${_angka(it['qty'])}')),
                                DataCell(Text(Uang.angka(_angka(it['nilai'])))),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _grupReturToko(List<Map<String, dynamic>> dariToko) {
    final grup = <String, List<Map<String, dynamic>>>{};
    for (final b in dariToko) {
      final nama = (b['nama_toko']?.toString() ?? '').trim();
      final kunci = nama.isEmpty
          ? (b['id_pelanggan']?.toString() ?? 'Toko')
          : nama;
      grup.putIfAbsent(kunci, () => []).add(b);
    }
    final out = <Widget>[];
    for (final e in grup.entries) {
      out.add(
        Text(
          e.key,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );
      for (final b in e.value) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_labelBarang(b)} · ${_angka(b['qty'])} pcs',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  Uang.rp(_angka(b['nilai'])),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      out.add(const SizedBox(height: 8));
    }
    return out;
  }

  String _labelBarang(Map<String, dynamic> it) {
    final nama = (it['nama_barang']?.toString() ?? '').trim();
    final kode = it['kode_barang']?.toString() ?? '';
    if (nama.isNotEmpty) return nama;
    if (kode.isNotEmpty) return kode;
    return 'Barang';
  }

  String _kunciBarang(Map<String, dynamic> it) {
    final tersimpan = (it['kunci_barang']?.toString() ?? '').trim();
    if (tersimpan.isNotEmpty) return tersimpan;
    final kode = (it['kode_barang']?.toString() ?? '').trim();
    if (kode.isNotEmpty) return kode;
    final nama = (it['nama_barang']?.toString() ?? '').trim();
    if (nama.isNotEmpty) return nama;
    return 'Barang';
  }

  void _timpaBatalDicekDariItem(
    List<Map<String, dynamic>> items,
    List<String> daftarRute,
  ) {
    _truk = [
      for (final row in _truk)
        () {
          final rute = row['rute_pengirim']?.toString() ?? '';
          if (!daftarRute.contains(rute)) return row;
          final punya = items
              .where(
                (it) =>
                    List<String>.from((it['rute_list'] as List?) ?? const [])
                        .contains(rute),
              )
              .toList();
          return {
            ...row,
            'batal_dicek':
                punya.isNotEmpty && punya.every((it) => it['dicek'] == true),
          };
        }(),
    ];
  }

  void _timpaPendingDicekDariNota(
    List<Map<String, dynamic>> nota,
    List<String> daftarRute,
  ) {
    _truk = [
      for (final row in _truk)
        () {
          final rute = row['rute_pengirim']?.toString() ?? '';
          if (!daftarRute.contains(rute)) return row;
          final punya = nota
              .where((n) => n['rute_pengirim']?.toString() == rute)
              .toList();
          return {
            ...row,
              'pending_dicek':
                  punya.isNotEmpty && punya.every((n) => n['dicek'] == true),
          };
        }(),
    ];
  }

  Future<void> _dialogTabelBarang({
    required String judul,
    required List<Widget> atas,
    required List<Map<String, dynamic>> items,
    required String kolomNilai,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AppDialog(
          title: Text(judul),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...atas,
              if (atas.isNotEmpty) const SizedBox(height: 8),
              DataTable(
                border: _garisKolom,
                columnSpacing: 12,
                horizontalMargin: 8,
                headingRowHeight: 36,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columns: [
                  const DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: Text('Barang'),
                  ),
                  const DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    numeric: true,
                    label: Text('Qty'),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    numeric: true,
                    label: Text(kolomNilai),
                  ),
                ],
                rows: items
                    .map(
                      (it) => DataRow(
                        cells: [
                          DataCell(Text(_labelBarang(it))),
                          DataCell(Text('${_angka(it['qty'])}')),
                          DataCell(Text(Uang.angka(it['packed']))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _gabungItemHari({
    required String rpc,
    required List<String> daftarRute,
  }) async {
    final gabung = <String, Map<String, dynamic>>{};
    for (final r in daftarRute) {
      final raw = await _sb.rpc(rpc, params: {'p_tanggal': _iso, 'p_rute': r});
      if (raw is! List) continue;
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final kunci = _kunciBarang(m);
        m['kunci_barang'] = kunci;
        final lama = gabung[kunci];
        if (lama == null) {
          m['rute_list'] = [r];
          gabung[kunci] = m;
        } else {
          lama['qty'] = _angka(lama['qty']) + _angka(m['qty']);
          lama['packed'] = _angka(lama['packed']) + _angka(m['packed']);
          lama['nilai'] = _angka(lama['nilai']) + _angka(m['nilai']);
          final ruteList = List<String>.from(
            (lama['rute_list'] as List?) ?? const [],
          );
          if (!ruteList.contains(r)) ruteList.add(r);
          lama['rute_list'] = ruteList;
        }
      }
    }
    final items = gabung.values.toList()
      ..sort(
        (a, b) =>
            _labelBarang(a)
                .toLowerCase()
                .compareTo(_labelBarang(b).toLowerCase()),
      );
    return items;
  }

  Future<void> _dialogSemuaItemPending(String? rute) async {
    if (!await _adaNet()) return;
    final daftarRute = (rute == null || rute.isEmpty)
        ? List<String>.from(_rute)
        : [rute];
    List<Map<String, dynamic>> items = [];
    try {
      items = await _gabungItemHari(
        rpc: 'admin_setoran_nota_item_pending',
        daftarRute: daftarRute,
      );
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat item pending.');
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      umpan(context, 'Tidak ada item pending di buku ini.', nada: NadaUmpan.kuning);
      return;
    }
    final totalQty = items.fold<int>(0, (a, it) => a + _angka(it['qty']));
    final totalPacked = items.fold<int>(0, (a, it) => a + _angka(it['packed']));
    await _dialogTabelBarang(
      judul: daftarRute.length > 1
          ? 'Semua item pending'
          : 'Semua item pending ${daftarRute.first}',
      atas: [Text('Qty $totalQty · Packed Rp ${Uang.angka(totalPacked)}')],
      items: items,
      kolomNilai: 'Packed',
    );
  }

  Future<void> _dialogSemuaItemBatal(String? rute) async {
    if (!await _adaNet()) return;
    final daftarRute = (rute == null || rute.isEmpty)
        ? List<String>.from(_rute)
        : [rute];
    List<Map<String, dynamic>> items = [];
    try {
      items = await _gabungItemHari(
        rpc: 'admin_setoran_nota_item_batal_hari',
        daftarRute: daftarRute,
      );
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat item batal.');
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      umpan(context, 'Tidak ada item batal di buku ini.', nada: NadaUmpan.kuning);
      return;
    }
    try {
      final rawCek = await _sb.rpc(
        'admin_setoran_batal_cek_lihat',
        params: {'p_tanggal': _iso},
      );
      final cek = <String, int>{};
      if (rawCek is List) {
        for (final e in rawCek) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final r = m['rute_pengirim']?.toString() ?? '';
          final k = (m['kunci_barang']?.toString() ?? '').trim();
          if (r.isEmpty || k.isEmpty) continue;
          cek['$r|$k'] = _angka(m['qty_fisik']);
        }
      }
      for (final it in items) {
        final kunci = _kunciBarang(it);
        final ruteList = List<String>.from(
          (it['rute_list'] as List?) ?? daftarRute,
        );
        final fisikSimpan = ruteList.isEmpty
            ? null
            : cek['${ruteList.first}|$kunci'];
        it['dicek'] = fisikSimpan != null;
        it['qty_fisik'] = fisikSimpan ?? _angka(it['qty']);
        if (_drafBatalCek.containsKey(kunci)) {
          it['dicek'] = _drafBatalCek[kunci]!.cek;
          it['qty_fisik'] = _drafBatalCek[kunci]!.fisik;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    final totalQty = items.fold<int>(0, (a, it) => a + _angka(it['qty']));
    final totalNilai = items.fold<int>(0, (a, it) => a + _angka(it['packed']));
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            void ubahCek(Map<String, dynamic> it, bool cek) {
              final kunci = _kunciBarang(it);
              final ruteList = List<String>.from(
                (it['rute_list'] as List?) ?? daftarRute,
              );
              if (kunci.isEmpty || ruteList.isEmpty) return;
              it['dicek'] = cek;
              if (cek && _angka(it['qty_fisik']) <= 0) {
                it['qty_fisik'] = _angka(it['qty']);
              }
              _drafBatalCek[kunci] = (
                rute: ruteList,
                cek: cek,
                fisik: _angka(it['qty_fisik']),
              );
              _timpaBatalDicekDariItem(items, daftarRute);
              _tandaiKotor();
              setLocal(() {});
            }

            void ubahFisik(Map<String, dynamic> it, String teks) {
              final kunci = _kunciBarang(it);
              final ruteList = List<String>.from(
                (it['rute_list'] as List?) ?? daftarRute,
              );
              if (kunci.isEmpty || ruteList.isEmpty) return;
              final klaim = _angka(it['qty']);
              var fisik = Uang.angkaTeks(teks);
              if (fisik > klaim) fisik = klaim;
              if (fisik < 0) fisik = 0;
              it['qty_fisik'] = fisik;
              it['dicek'] = true;
              _drafBatalCek[kunci] = (
                rute: ruteList,
                cek: true,
                fisik: fisik,
              );
              _timpaBatalDicekDariItem(items, daftarRute);
              _tandaiKotor();
              setLocal(() {});
            }

            return AppDialog(
              title: Text(
                daftarRute.length > 1
                    ? 'Semua item batal'
                    : 'Semua item batal ${daftarRute.first}',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qty $totalQty · Batal Rp ${Uang.angka(totalNilai)}\n'
                    'Fisik = yang kembali ke gudang. Kurang dari klaim masuk kasbon (harga beli, pecah supir/kenek).',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 8),
                  DataTable(
                    border: _garisKolom,
                    columnSpacing: 12,
                    horizontalMargin: 8,
                    headingRowHeight: 36,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 52,
                    columns: const [
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        label: SizedBox(width: 28),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        label: Text('Barang'),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        numeric: true,
                        label: Text('Klaim'),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        numeric: true,
                        label: SizedBox(
                          width: 76,
                          child: Text('Fisik', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        headingRowAlignment: MainAxisAlignment.center,
                        numeric: true,
                        label: Text('Batal'),
                      ),
                    ],
                    rows: items
                        .map(
                          (it) => DataRow(
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: it['dicek'] == true,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onChanged: _proses
                                      ? null
                                      : (v) => ubahCek(it, v ?? false),
                                ),
                              ),
                              DataCell(Text(_labelBarang(it))),
                              DataCell(Text('${_angka(it['qty'])}')),
                              DataCell(
                                _isianAdmin(
                                  lebar: 76,
                                  align: TextAlign.center,
                                  key: ValueKey(_kunciBarang(it)),
                                  initial: '${_angka(it['qty_fisik'])}',
                                  enabled: !_proses,
                                  onChanged: (t) => ubahFisik(it, t),
                                ),
                              ),
                              DataCell(Text(Uang.angka(it['packed']))),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _dialogRincianPending(Map<String, dynamic> nota) async {
    final id = nota['id_nota']?.toString() ?? '';
    if (id.isEmpty) return;
    if (!await _adaNet()) return;
    List<Map<String, dynamic>> items = [];
    try {
      final raw = await _sb.rpc(
        'admin_setoran_nota_item',
        params: {'p_id_nota': id},
      );
      if (raw is List) {
        items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat rincian.');
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      umpan(context, 'Rincian barang pending belum bisa ditampilkan.', nada: NadaUmpan.kuning);
      return;
    }
    await _dialogTabelBarang(
      judul: 'Rincian $id',
      atas: [
        Text(
          '${nota['nama_pelanggan'] ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text('Packed Rp ${Uang.angka(nota['packed'])}'),
      ],
      items: items,
      kolomNilai: 'Packed',
    );
  }

  Future<void> _dialogRincianBatal(Map<String, dynamic> nota) async {
    final id = nota['id_nota']?.toString() ?? '';
    if (id.isEmpty) return;
    if (!await _adaNet()) return;
    List<Map<String, dynamic>> items = [];
    try {
      final raw = await _sb.rpc(
        'admin_setoran_nota_item_batal',
        params: {'p_id_nota': id},
      );
      if (raw is List) {
        items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {
      if (!mounted) return;
      umpan(context, 'Gagal memuat rincian.');
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      umpan(context, 'Rincian barang batal belum bisa ditampilkan.', nada: NadaUmpan.kuning);
      return;
    }
    await _dialogTabelBarang(
      judul: 'Rincian $id',
      atas: [
        Text(
          '${nota['nama_pelanggan'] ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text('Batal Rp ${Uang.angka(nota['batal'])}'),
      ],
      items: items,
      kolomNilai: 'Batal',
    );
  }

  List<({String nama, Color warna, String hint})> _itemStatusHarian() {
    final jumlah = _jumlahEmpatTim();
    final adaMutasi = _mutasi.isNotEmpty;
    final adaTransfer = _truk.any(
      (r) => r['sudah_setor'] == true && _angka(r['transfer']) > 0,
    );
    final mutasiBelumIkat = _mutasi.any((m) {
      final st = m['status_cocok']?.toString() ?? '';
      return st != 'cocok' && st != 'manual';
    });
    final mutasiBeda = _truk.any((r) => r['transfer_beda'] == true);

    Color mutasiWarna;
    String mutasiHint;
    if (!adaMutasi && !adaTransfer) {
      mutasiWarna = Colors.grey.shade600;
      mutasiHint = 'Belum ada mutasi atau transfer.';
    } else if (mutasiBeda || mutasiBelumIkat) {
      mutasiWarna = Colors.red;
      mutasiHint = mutasiBelumIkat
          ? 'Ada mutasi yang belum diikat ke rute.'
          : 'Mutasi tidak sama dengan transfer pengirim.';
    } else {
      mutasiWarna = Colors.green.shade700;
      mutasiHint = 'Mutasi sudah cocok dengan transfer.';
    }

    final adaTunai = _truk.any(
      (r) => r['sudah_setor'] == true && _angka(r['tunai']) > 0,
    );
    final tunaiBeda = _truk.any((r) => r['tunai_beda'] == true);
    Color tunaiWarna;
    String tunaiHint;
    if (!adaTunai) {
      tunaiWarna = Colors.grey.shade600;
      tunaiHint = 'Tidak ada tunai pengirim.';
    } else if (tunaiBeda || jumlah['tunai_dicek'] != true) {
      tunaiWarna = Colors.red;
      tunaiHint = 'Tunai admin belum sama dengan tunai pengirim.';
    } else {
      tunaiWarna = Colors.green.shade700;
      tunaiHint = 'Tunai admin sama dengan pengirim.';
    }

    ({Color warna, String hint}) langkah({
      required bool ada,
      required bool dicek,
      required String kosong,
      required String belum,
      required String beres,
    }) {
      if (!ada) {
        return (warna: Colors.grey.shade600, hint: kosong);
      }
      if (dicek) {
        return (warna: Colors.green.shade700, hint: beres);
      }
      return (warna: Colors.orange.shade800, hint: belum);
    }

    final batal = langkah(
      ada: _angka(jumlah['batal']) > 0,
      dicek: jumlah['batal_dicek'] == true,
      kosong: 'Tidak ada nota batal.',
      belum: 'Ada batal yang belum dicek.',
      beres: 'Batal sudah dicek.',
    );
    final pending = langkah(
      ada: _angka(jumlah['pending']) > 0,
      dicek: jumlah['pending_dicek'] == true,
      kosong: 'Tidak ada nota pending.',
      belum: 'Ada pending yang belum dicek.',
      beres: 'Pending sudah dicek.',
    );
    final retur = langkah(
      ada: _angka(jumlah['retur']) != 0,
      dicek: jumlah['retur_dicek'] == true,
      kosong: 'Tidak ada retur.',
      belum: 'Ada retur yang belum dicocokkan.',
      beres: 'Retur sudah dicocokkan.',
    );
    final kasbon = langkah(
      ada: _angka(jumlah['kasbon_klaim']) != 0,
      dicek: jumlah['kasbon_dicek'] == true,
      kosong: 'Tidak ada kasbon pengirim.',
      belum: 'Ada kasbon yang belum dicek.',
      beres: 'Kasbon sudah dicek.',
    );

    Color bukuWarna;
    String bukuHint;
    if (_sedangLihatBukuTerbuka) {
      if (_bukuGantung > 0) {
        bukuWarna = Colors.orange.shade800;
        bukuHint =
            'Buku ${_judulBuku.isEmpty ? _bukuTanggal : _judulBuku} terbuka. '
            'Masih $_bukuGantung nota di truk. Kunci atau pending dulu sebelum tutup.';
      } else {
        bukuWarna = Colors.green.shade700;
        bukuHint =
            'Buku ${_judulBuku.isEmpty ? _bukuTanggal : _judulBuku} siap ditutup.'
            '${_bukuPending > 0 ? ' $_bukuPending pending akan pindah ke buku berikutnya.' : ''}';
      }
    } else if (_bukuTerbuka) {
      bukuWarna = Colors.grey.shade600;
      bukuHint =
          'Ini buku lama. Data kartu ini tidak berubah. '
          'Buku terbuka: ${_judulBuku.isEmpty ? _bukuTanggal : _judulBuku}.';
    } else {
      bukuWarna = Colors.grey.shade600;
      bukuHint = _bukuTanggal.isEmpty
          ? 'Tidak ada buku setoran terbuka. Packing gudang akan membuka buku baru.'
          : 'Kartu ini sudah ditutup.';
    }

    return [
      (
        nama: 'Buku',
        warna: bukuWarna,
        hint: bukuHint,
      ),
      (nama: 'Mutasi', warna: mutasiWarna, hint: mutasiHint),
      (nama: 'Tunai', warna: tunaiWarna, hint: tunaiHint),
      (nama: 'Batal', warna: batal.warna, hint: batal.hint),
      (nama: 'Pending', warna: pending.warna, hint: pending.hint),
      (nama: 'Retur', warna: retur.warna, hint: retur.hint),
      (nama: 'Kasbon', warna: kasbon.warna, hint: kasbon.hint),
    ];
  }

  Widget _barisStatusHarian() {
    final item = _itemStatusHarian();
    return SizedBox(
      height: _tinggiStatusHarian,
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              for (var i = 0; i < item.length; i++) ...[
                if (i > 0)
                  Text(
                    ' · ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                Expanded(
                  child: Tooltip(
                    message: item[i].hint,
                    child: Text(
                      item[i].nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: item[i].warna,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _bendera(Map<String, dynamic> row) {
    final out = <String>[];
    if (_angka(row['jumlah_dikirim']) > 0) {
      out.add('Masih ${_angka(row['jumlah_dikirim'])} nota dikirim');
    }
    if (row['bop_lebih'] == true) {
      out.add('BOP > 170.000');
    }
    if (row['sesa_tidak_nol'] == true) {
      out.add('Setoran pengirim tidak seimbang');
    }
    if (row['tunai_beda'] == true) {
      out.add('Tunai admin ≠ pengirim');
    }
    if (row['transfer_beda'] == true) {
      out.add('Mutasi ≠ transfer');
    }
    return out;
  }

  Widget _uangSel(dynamic n, {Color? warna, bool tebal = true}) {
    final gaya = TextStyle(
      fontSize: _teksIsi,
      height: 1.15,
      color: warna ?? Colors.black,
      fontWeight: tebal ? FontWeight.bold : FontWeight.normal,
    );
    return Row(
      children: [
        SizedBox(width: 22, child: Text('Rp', style: gaya)),
        Expanded(
          child: Text(
            Uang.angka(_angka(n)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: gaya,
          ),
        ),
      ],
    );
  }

  Widget _kotakKolom(
    double lebar,
    Widget child, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: lebar,
      child: OverflowBox(
        alignment: alignment,
        maxWidth: lebar,
        maxHeight: double.infinity,
        child: child,
      ),
    );
  }

  Widget _judulKolom(double lebar, String teks) {
    return SizedBox(
      width: lebar,
      child: Text(
        teks,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: _teksIsi, fontWeight: FontWeight.w600),
      ),
    );
  }

  DataColumn _kolomJudul(double lebar, String teks) {
    return DataColumn(
      headingRowAlignment: MainAxisAlignment.center,
      label: _judulKolom(lebar, teks),
    );
  }

  List<DataColumn> get _judulSetoran => [
    _kolomJudul(_lebarRute, 'Rute'),
    _kolomJudul(_lebarNilai, 'Nota'),
    _kolomJudul(_lebarNilai, 'Setor'),
    _kolomJudul(_lebarNilai, 'Hitung'),
  ];

  Widget _chipTombol({
    required String label,
    required VoidCallback onTap,
    bool adaIsi = false,
    bool ceklis = false,
    double? tinggi,
    bool lebarPenuh = true,
    bool rataTengah = false,
    double? ukuranFont,
  }) {
    final Color chipWarna;
    if (ceklis && adaIsi) {
      chipWarna = Colors.green.shade700;
    } else if (adaIsi) {
      chipWarna = Colors.orange.shade800;
    } else {
      chipWarna = Tema.seed;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _proses ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: lebarPenuh ? double.infinity : null,
          height: tinggi ?? _tinggiBarisNilai,
          constraints: lebarPenuh
              ? null
              : const BoxConstraints(maxWidth: _lebarLabelNilai),
          padding: EdgeInsets.symmetric(horizontal: lebarPenuh ? 8 : 6),
          alignment: rataTengah ? Alignment.center : Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: chipWarna, width: 1.2),
          ),
          child: Builder(
            builder: (context) {
              final teks = Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: rataTengah ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: chipWarna,
                  fontWeight: FontWeight.bold,
                  fontSize: ukuranFont ?? 11,
                  height: 1.15,
                ),
              );
              if (!lebarPenuh) return teks;
              return Row(
                children: [
                  Expanded(child: teks),
                  Icon(
                    ceklis && adaIsi ? Icons.check : Icons.chevron_right,
                    size: 14,
                    color: chipWarna,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _barisNilai(
    String label,
    dynamic n, {
    String? teks,
    String? hint,
    VoidCallback? onLabel,
    bool ceklis = false,
  }) {
    final angka = _angka(n);
    final aksi = onLabel;
    final pesanHint = hint ??
        (aksi == null
            ? null
            : (ceklis ? 'Sudah dicek. Ketuk untuk buka.' : 'Ketuk untuk cek'));
    final labelTeks = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        height: 1.15,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
    final Widget labelKiri;
    if (aksi != null && angka != 0) {
      labelKiri = _chipTombol(
        label: label,
        onTap: aksi,
        adaIsi: true,
        ceklis: ceklis,
      );
    } else {
      labelKiri = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: aksi == null || _proses ? null : aksi,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: labelTeks,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: _tinggiBarisNilai,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _lebarLabelNilai,
            child: pesanHint == null
                ? labelKiri
                : Tooltip(message: pesanHint, child: labelKiri),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: teks != null
                ? Text(
                    teks,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: _teksIsi,
                      height: 1.15,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : _uangSel(n),
          ),
        ],
      ),
    );
  }

  Widget _kolomNota(
    Map<String, dynamic> row, {
    VoidCallback? onPending,
    VoidCallback? onBatal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _barisNilai('Kiriman', row['kiriman']),
        _barisNilai(
          'Batal',
          row['batal'],
          onLabel: onBatal,
          ceklis: row['batal_dicek'] == true && _angka(row['batal']) > 0,
        ),
        _barisNilai(
          'Pending',
          row['pending'],
          onLabel: onPending,
          ceklis: row['pending_dicek'] == true && _angka(row['pending']) > 0,
        ),
        _barisNilai('Actual', row['actual']),
      ],
    );
  }

  Widget _kolomSetor(
    Map<String, dynamic> row, {
    VoidCallback? onTunaiAdmin,
    bool ceklisTunai = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _barisNilai('Transfer', row['transfer']),
        _barisNilai('Mutasi', row['transfer_mutasi']),
        _barisNilai('Tunai', row['tunai']),
        _barisNilai(
          'Tunai admin',
          row['tunai_admin'],
          onLabel: onTunaiAdmin,
          ceklis: ceklisTunai,
        ),
      ],
    );
  }

  Widget _kolomHitung(
    Map<String, dynamic> row,
    int kasbon, {
    VoidCallback? onKasbon,
    VoidCallback? onRetur,
    bool ceklisRetur = false,
    bool ceklisKasbon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _barisNilai('BOP', row['bop']),
        _barisNilai(
          'Kasbon',
          kasbon,
          onLabel: onKasbon,
          ceklis: ceklisKasbon,
        ),
        _barisNilai(
          'Retur',
          row['retur'],
          onLabel: onRetur,
          ceklis: ceklisRetur,
        ),
        _barisNilai('Cek', row['sesa_cek'], hint: _hintCek),
      ],
    );
  }

  Map<String, dynamic> _jumlahEmpatTim() {
    var kiriman = 0;
    var batal = 0;
    var pending = 0;
    var actual = 0;
    var transfer = 0;
    var mutasi = 0;
    var tunai = 0;
    var tunaiAdmin = 0;
    var bop = 0;
    var retur = 0;
    var kasbon = 0;
    var kasbonKlaim = 0;
    var sesa = 0;
    var cek = 0;
    var adaSetor = false;
    var bopLebih = false;
    for (final row in _truk) {
      kiriman += _angka(row['kiriman']);
      batal += _angka(row['batal']);
      pending += _angka(row['pending']);
      actual += _angka(row['actual']);
      transfer += _angka(row['transfer']);
      mutasi += _angka(row['transfer_mutasi']);
      tunai += _angka(row['tunai']);
      tunaiAdmin += _angka(row['tunai_admin']);
      bop += _angka(row['bop']);
      retur += _angka(row['retur']);
      kasbon += _angka(row['kasbon_supir']) + _angka(row['kasbon_kenek']);
      kasbonKlaim += _kasbonKlaimTotal(row);
      sesa += _angka(row['sesa']);
      cek += _angka(row['sesa_cek']);
      if (row['sudah_setor'] == true) adaSetor = true;
      if (row['bop_lebih'] == true) bopLebih = true;
    }
    final adaBatal = batal > 0;
    final batalDicek =
        adaBatal &&
        _truk.every(
          (row) => _angka(row['batal']) <= 0 || row['batal_dicek'] == true,
        );
    final adaPending = pending > 0;
    final pendingDicek =
        adaPending &&
        _truk.every(
          (row) => _angka(row['pending']) <= 0 || row['pending_dicek'] == true,
        );
    final tunaiDicek =
        _truk.isNotEmpty &&
        tunai > 0 &&
        _truk.every(
          (row) => _angka(row['tunai']) == _angka(row['tunai_admin']),
        );
    final adaRetur = retur != 0;
    final returDicek =
        adaRetur &&
        _truk.every(
          (row) => _angka(row['retur']) == 0 || row['retur_dicek'] == true,
        );
    final adaKasbonKlaim = kasbonKlaim != 0;
    final kasbonDicek =
        adaKasbonKlaim &&
        _truk.every(
          (row) => _kasbonKlaimTotal(row) == 0 || row['kasbon_dicek'] == true,
        );
    return {
      'kiriman': kiriman,
      'batal': batal,
      'pending': pending,
      'actual': actual,
      'transfer': transfer,
      'transfer_mutasi': mutasi,
      'tunai': tunai,
      'tunai_admin': tunaiAdmin,
      'bop': bop,
      'retur': retur,
      'kasbon': kasbon,
      'kasbon_klaim': kasbonKlaim,
      'sesa': sesa,
      'sesa_cek': cek,
      'sudah_setor': adaSetor,
      'bop_lebih': bopLebih,
      'batal_dicek': batalDicek,
      'pending_dicek': pendingDicek,
      'tunai_dicek': tunaiDicek,
      'retur_dicek': returDicek,
      'kasbon_dicek': kasbonDicek,
    };
  }

  List<DataRow> _barisTrukSetoran() {
    return [
      ..._truk.map((row) {
        final rute = row['rute_pengirim']?.toString() ?? '';
        final bendera = _bendera(row);
        final kasbonKlaim = _kasbonKlaimTotal(row);
        return DataRow(
          cells: [
            DataCell(
              _kotakKolom(
                _lebarRute,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rute,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Tema.seed,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        fontSize: _teksIsi,
                        height: 1.15,
                      ),
                    ),
                    if (row['sudah_setor'] != true)
                      Text(
                        'Belum setor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (bendera.isNotEmpty)
                      Text(
                        bendera.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.15,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                alignment: Alignment.center,
              ),
              onTap: () => _dialogTokoDikirim(rute),
            ),
            DataCell(
              _kotakKolom(
                _lebarNilai,
                _kolomNota(
                  row,
                  onPending: () => _dialogNota(pending: true, rute: rute),
                  onBatal: () => _dialogNota(pending: false, rute: rute),
                ),
              ),
            ),
            DataCell(
              _kotakKolom(
                _lebarNilai,
                _kolomSetor(
                  row,
                  onTunaiAdmin: () => _dialogTunai(row),
                  ceklisTunai:
                      _angka(row['tunai']) > 0 &&
                      _angka(row['tunai']) == _angka(row['tunai_admin']),
                ),
              ),
            ),
            DataCell(
              _kotakKolom(
                _lebarNilai,
                _kolomHitung(
                  row,
                  kasbonKlaim,
                  onKasbon: () => _dialogKasbon(row),
                  onRetur: () => _dialogRetur(row),
                  ceklisRetur:
                      row['retur_dicek'] == true && _angka(row['retur']) != 0,
                  ceklisKasbon:
                      row['kasbon_dicek'] == true && kasbonKlaim != 0,
                ),
              ),
            ),
          ],
        );
      }),
    ];
  }

  Widget _kartuJumlahSetoran({required double tinggiBaris}) {
    final jumlah = _jumlahEmpatTim();
    final kasbonKlaim = _kasbonKlaimTotal(jumlah);
    return SizedBox(
      height: _tinggiKartuSetoran(1, tinggiBaris),
      child: _kartuTabel(
        DataTable(
          headingRowHeight: _tinggiJudulSetoran,
          dataRowMinHeight: tinggiBaris,
          dataRowMaxHeight: tinggiBaris,
          dividerThickness: 0,
          columnSpacing: 16,
          horizontalMargin: 10,
          border: _garisKolom,
          columns: _judulSetoran,
          rows: [
            DataRow(
              cells: [
                DataCell(
                  _kotakKolom(
                    _lebarRute,
                    const Text(
                      'Jumlah',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _teksIsi,
                        height: 1.15,
                      ),
                    ),
                    alignment: Alignment.center,
                  ),
                ),
                DataCell(
                  _kotakKolom(
                    _lebarNilai,
                    _kolomNota(
                      jumlah,
                      onPending: () => _dialogNota(pending: true),
                      onBatal: () => _dialogNota(pending: false),
                    ),
                  ),
                ),
                DataCell(
                  _kotakKolom(
                    _lebarNilai,
                    _kolomSetor(
                      jumlah,
                      onTunaiAdmin: _dialogTunaiJumlah,
                      ceklisTunai: jumlah['tunai_dicek'] == true,
                    ),
                  ),
                ),
                DataCell(
                  _kotakKolom(
                    _lebarNilai,
                    _kolomHitung(
                      jumlah,
                      kasbonKlaim,
                      onKasbon: _dialogKasbonJumlah,
                      onRetur: _dialogReturJumlah,
                      ceklisRetur: jumlah['retur_dicek'] == true,
                      ceklisKasbon: jumlah['kasbon_dicek'] == true,
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

  bool _mutasiTerikat(Map<String, dynamic> m) {
    final st = m['status_cocok']?.toString() ?? '';
    return st == 'cocok' || st == 'manual';
  }

  Widget _selMutasi(Widget child, {Alignment align = Alignment.centerLeft}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Align(alignment: align, child: child),
    );
  }

  Widget _tabelMutasi() {
    const gaya = TextStyle(
      fontSize: _teksIsi,
      height: 1.15,
      fontWeight: FontWeight.bold,
    );
    const gayaJudul = TextStyle(
      fontSize: _teksIsi,
      fontWeight: FontWeight.bold,
    );
    Widget judul(String teks) =>
        _selMutasi(Text(teks, style: gayaJudul), align: Alignment.center);
    final urut = [..._mutasi]..sort((a, b) {
      final ia = _mutasiTerikat(a) ? 1 : 0;
      final ib = _mutasiTerikat(b) ? 1 : 0;
      if (ia != ib) return ia - ib;
      return _angka(b['jumlah']).compareTo(_angka(a['jumlah']));
    });
    final baris = <TableRow>[
      TableRow(
        children: [
          judul('Tanggal'),
          judul('Jumlah'),
          judul('Rekening'),
          judul('Rute'),
          judul('Status'),
        ],
      ),
    ];
    for (final m in urut) {
      final rute = m['rute_pengirim']?.toString();
      final terikat = _mutasiTerikat(m) && _rute.contains(rute);
      final teksStatus = terikat ? 'Cocok ${rute!}' : 'Belum diikat';
      final rek = (m['rekening_alias']?.toString() ?? '').trim();
      final berita = (m['berita']?.toString() ?? '').trim();
      baris.add(
        TableRow(
          children: [
            _selMutasi(Text('${m['tanggal_mutasi'] ?? '-'}', style: gaya)),
            _selMutasi(_uangSel(m['jumlah'], tebal: true)),
            _selMutasi(
              Tooltip(
                message: berita.isEmpty ? 'Rekening' : berita,
                child: Text(
                  rek.isEmpty ? '-' : rek,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gaya,
                ),
              ),
            ),
            _selMutasi(
              Text(
                terikat ? rute! : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gaya,
              ),
              align: Alignment.center,
            ),
            _selMutasi(
              Text(
                teksStatus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _teksIsi,
                  fontWeight: FontWeight.bold,
                  color: terikat ? Colors.green.shade700 : Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.15),
        1: FlexColumnWidth(1.35),
        2: FlexColumnWidth(1.1),
        3: FlexColumnWidth(1.15),
        4: FlexColumnWidth(1.25),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        verticalInside: BorderSide(color: Color(0xFF8FB4D9), width: 1),
      ),
      children: baris,
    );
  }

  Widget _kartuTabel(Widget tabel) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: tabel,
        ),
      ),
    );
  }

  Widget _barisKiriKanan({
    required Widget kiri,
    required Widget kanan,
    required double tinggiKanan,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        final gap = _celahSampingKartu;
        final butuh = _lebarKartuSetoran + gap + _lebarKananMin;
        final lebarKanan = c.maxWidth >= butuh
            ? c.maxWidth - _lebarKartuSetoran - gap
            : _lebarKananMin;
        final baris = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: _lebarKartuSetoran, child: kiri),
            SizedBox(width: gap),
            SizedBox(
              width: lebarKanan,
              height: tinggiKanan,
              child: kanan,
            ),
          ],
        );
        if (c.maxWidth >= butuh) return baris;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: baris,
        );
      },
    );
  }

  Widget _kotakHadir({
    required Map<String, dynamic> row,
  }) {
    final kunci = row['nama_kunci']?.toString() ?? '';
    final nama = row['nama']?.toString() ?? kunci;
    final hadir = row['hadir'] == true;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: hadir ? 'Hadir (scan HP)' : 'Belum scan masuk',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hadir ? Colors.green.shade700 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              nama,
              style: TextStyle(
                fontSize: _teksIsi,
                height: 1,
                color: hadir ? Colors.black : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grupAbsensi({
    required String judul,
    required List<Map<String, dynamic>> orang,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          judul,
          style: const TextStyle(
            fontSize: _teksIsi,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        for (final row in orang) _kotakHadir(row: row),
      ],
    );
  }

  Widget _kartuAbsensiHari() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_pengirim.isNotEmpty)
                      _grupAbsensi(
                        judul: 'Pengirim',
                        orang: _pengirim,
                      ),
                    if (_pengirim.isNotEmpty && _gudang.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 18,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    if (_gudang.isNotEmpty)
                      _grupAbsensi(
                        judul: 'Gudang',
                        orang: _gudang,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogItemMasukSupplier({
    required String nama,
    required List<Map<String, dynamic>> items,
  }) {
    final total = items.fold<int>(0, (a, m) => a + _angka(m['nilai']));
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: Text(nama),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final m in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (m['nama_barang']?.toString() ?? '')
                                      .trim()
                                      .isEmpty
                                  ? (m['kode_barang']?.toString() ?? '')
                                  : m['nama_barang'].toString(),
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              m['kode_barang']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Uang.angka(m['qty']),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Text(
                          Uang.angka(m['nilai']),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _barisNilai('Total', total),
            ],
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

  Widget _kartuMutasiHari() {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tabelMutasi(),
                      if (_mutasi.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                          child: Text(
                            'Belum ada mutasi.',
                            style: TextStyle(
                              fontSize: _teksIsi,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _tombolBiru(
                      label: 'Unggah mutasi CSV',
                      onPressed: _proses ? null : _unggahMutasi,
                      ikon: Icons.upload_file_outlined,
                      ukuranFont: _teksIsi,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tombolBiru(
                      label: 'Hapus mutasi buku ini',
                      onPressed: _proses || _mutasi.isEmpty
                          ? null
                          : _hapusMutasi,
                      ukuranFont: _teksIsi,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuOpnameHari() {
    final String judulStatus;
    final String detail;
    final Color warna;
    if (!_opnameAda) {
      judulStatus = 'Belum ada input';
      detail = 'Gudang belum mengirim opname untuk buku ini.';
      warna = Colors.grey.shade700;
    } else if (_opnameStatus == 'kunci') {
      if (_opnameSelisihSku == 0) {
        judulStatus = 'Dikunci · cocok';
        detail = 'Tidak ada selisih stok.';
        warna = Colors.green.shade700;
      } else if (_opnameMenunggu > 0) {
        judulStatus = 'Perlu konfirmasi admin';
        detail =
            '$_opnameMenunggu dari $_opnameSelisihSku SKU  ·  Rp ${Uang.angka(_opnameNilaiSelisih)}';
        warna = Colors.orange.shade800;
      } else {
        judulStatus = 'Selisih dikonfirmasi';
        detail =
            '$_opnameSelisihSku SKU  ·  Rp ${Uang.angka(_opnameNilaiSelisih)}';
        warna = Colors.green.shade700;
      }
    } else if (_opnameSelisihSku == 0) {
      judulStatus = 'Draft · cocok';
      detail = 'Tidak ada selisih stok.';
      warna = Colors.green.shade700;
    } else {
      judulStatus = 'Draft · selisih';
      detail =
          '$_opnameSelisihSku SKU  ·  Rp ${Uang.angka(_opnameNilaiSelisih)}';
      warna = Colors.orange.shade800;
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: SizedBox.expand(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tombolSetengahKiri(
                label: _opnameMenunggu > 0 ? 'Konfirmasi opname' : 'Lihat opname',
                onPressed: _proses ? null : _cekOpname,
                ukuranFont: _teksIsi,
              ),
              const SizedBox(height: 4),
              Text(
                'Fisik gudang; qty sah dikunci admin jika ada selisih',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _opnameBeda.isEmpty ? null : _dialogSelisihOpname,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judulStatus,
                      style: TextStyle(
                        fontSize: _teksIsi,
                        fontWeight: FontWeight.bold,
                        color: warna,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: _teksIsi,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barisSupplierMasuk({
    required String nama,
    required int nilai,
    required double tinggi,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: tinggi,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _chipTombol(
                label: nama,
                onTap: onTap ?? () {},
                tinggi: (tinggi - 4).clamp(18.0, _tinggiBarisNilai),
                lebarPenuh: false,
                rataTengah: true,
                ukuranFont: _teksIsi,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Uang.angka(nilai),
            style: const TextStyle(
              fontSize: _teksIsi,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisRekapMasuk(String label, int nilai) {
    return SizedBox(
      height: _tinggiTotalMasuk,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: _teksIsi,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            Uang.angka(nilai),
            style: const TextStyle(
              fontSize: _teksIsi,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuBarangMasukHari({required double tinggiBarisSupplier}) {
    final urutan = <int>[];
    final namaSup = <int, String>{};
    final grup = <int, List<Map<String, dynamic>>>{};
    for (final m in _masuk) {
      final id = _idDariRpc(m['id_supplier']);
      if (!grup.containsKey(id)) {
        urutan.add(id);
        grup[id] = [];
      }
      grup[id]!.add(m);
      final n = (m['nama_supplier']?.toString() ?? '').trim();
      if (n.isNotEmpty) namaSup[id] = n;
    }
    final total = _masuk.fold<int>(0, (a, m) => a + _angka(m['nilai']));
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tombolSetengahKiri(
                  label: 'Barang masuk',
                  onPressed: _proses ? null : _dialogBarangMasuk,
                  ukuranFont: _teksIsi,
                ),
                const SizedBox(height: 8),
                if (urutan.isEmpty)
                  Text(
                    'Belum ada data.',
                    style: TextStyle(
                      fontSize: _teksIsi,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  )
                else
                  for (final id in urutan)
                    _barisSupplierMasuk(
                      nama: namaSup[id] ?? 'Supplier',
                      nilai: grup[id]!.fold<int>(
                        0,
                        (a, m) => a + _angka(m['nilai']),
                      ),
                      tinggi: tinggiBarisSupplier <= 0
                          ? _tinggiBarisSupplier
                          : tinggiBarisSupplier,
                      onTap: () => _dialogItemMasukSupplier(
                        nama: namaSup[id] ?? 'Supplier',
                        items: grup[id]!,
                      ),
                    ),
                const SizedBox(height: 6),
                _barisRekapMasuk('Total', total),
                _barisRekapMasuk('Ongkir belanja', _ongkirHari),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kolomKananAtas({
    required double tinggiKartuMasuk,
    required double tinggiBarisSupplier,
    required double tinggiKolom,
  }) {
    const minMutasi = 80.0;
    var hMasuk = tinggiKartuMasuk;
    if (tinggiKolom.isFinite) {
      final sisa = (tinggiKolom - _celahKartu).clamp(0.0, tinggiKolom);
      final maksMasuk = (sisa - minMutasi).clamp(0.0, sisa);
      if (hMasuk > maksMasuk) hMasuk = maksMasuk;
    }
    final cadanganMasuk =
        8 + _tinggiTombolAksi + 8 + 6 + _tinggiTotalMasuk * 2 + 10;
    final ruangSupplier = (hMasuk - cadanganMasuk).clamp(0.0, double.infinity);
    final hSupplier = (ruangSupplier / _barisSupplierTampil).clamp(
      0.0,
      tinggiBarisSupplier < 0 ? 0.0 : tinggiBarisSupplier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _kartuMutasiHari()),
        if (hMasuk >= 72) ...[
          const SizedBox(height: _celahKartu),
          SizedBox(
            height: hMasuk,
            width: double.infinity,
            child: _kartuBarangMasukHari(tinggiBarisSupplier: hSupplier),
          ),
        ],
      ],
    );
  }

  Widget _kartuRuteSetoran({required double tinggiBaris}) {
    return SizedBox(
      height: _tinggiKartuSetoran(_rute.length, tinggiBaris),
      child: _kartuTabel(
        _truk.isEmpty
            ? Center(
                child: Text(
                  'Belum ada data. Jalankan ulang 042_admin_setoran.sql di Supabase.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            : DataTable(
                headingRowHeight: _tinggiJudulSetoran,
                dataRowMinHeight: tinggiBaris,
                dataRowMaxHeight: tinggiBaris,
                dividerThickness: 0,
                columnSpacing: 16,
                horizontalMargin: 10,
                border: _garisKolom,
                columns: _judulSetoran,
                rows: _barisTrukSetoran(),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(halaman: HalamanAdmin.setoran),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
        title: Row(
          children: [
            IconButton(
              tooltip: 'Buku lama',
              onPressed: _pilihHari,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
            if (!_ikutiBukuTerbuka && _bukuTerbuka)
              IconButton(
                tooltip: 'Buku terbuka',
                onPressed: () {
                  _ikutiBukuTerbuka = true;
                  _muatData(layarPenuh: true);
                },
                icon: const Icon(Icons.menu_book_outlined),
              ),
            Expanded(
              child: Text(_judulAppBar, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        titleSpacing: 0,
        actions: [
          if (_kotor)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Belum disimpan',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: FilledButton(
              onPressed: _muat || _proses ? null : _simpanHalaman,
              style: _gayaTombolBiru,
              child: const Text('Simpan'),
            ),
          ),
          if (_sedangLihatBukuTerbuka)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: OutlinedButton(
                onPressed: _muat || _proses ? null : _tutupBuku,
                child: const Text('Tutup buku'),
              ),
            ),
          IconButton(
            tooltip: 'Unduh',
            onPressed: _muat || _proses ? null : _unduhHalaman,
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Segarkan',
            onPressed: () => _muatData(layarPenuh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _muat
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final tinggiKartuAbsen = 12 + _tinggiBarisAbsensi;
                final tinggiAbsen = _celahKartu + tinggiKartuAbsen;
                final tinggiStatus = _celahKartu + _tinggiStatusHarian;
                final tinggiTersedia =
                    constraints.maxHeight - _padHalamanAtas - _padHalamanBawah;
                final tinggiBlok = (tinggiTersedia - tinggiAbsen - tinggiStatus)
                    .clamp(240.0, 4000.0);
                final cadanganKartu =
                    2 *
                    (_padKartuTabelAtas +
                        _padKartuTabelBawah +
                        _tinggiJudulSetoran);
                var tinggiBaris =
                    (tinggiBlok - _celahKartu - cadanganKartu) / 5;
                tinggiBaris = tinggiBaris.floorToDouble();
                if (tinggiBaris > _tinggiBarisSetoranMaks) {
                  tinggiBaris = _tinggiBarisSetoranMaks;
                }
                if (tinggiBaris < 104) tinggiBaris = 104;
                final tinggiRute = _tinggiKartuSetoran(
                  _rute.length,
                  tinggiBaris,
                );
                final tinggiJumlah = _tinggiKartuSetoran(1, tinggiBaris);
                var tinggiMasuk = _tinggiKartuMasukPenuh;
                const tetapKananTanpaMasuk =
                    _tinggiTombolAksi * 3 + _celahKartu * 4 + 80;
                final maksMasuk = tinggiRute - tetapKananTanpaMasuk;
                if (maksMasuk > 120 && tinggiMasuk > maksMasuk) {
                  tinggiMasuk = maksMasuk;
                }
                final tinggiBarisSupplier =
                    ((tinggiMasuk - 96) / _barisSupplierTampil).clamp(
                      18.0,
                      _tinggiBarisSupplier,
                    );
                final isi = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _barisStatusHarian(),
                    const SizedBox(height: _celahKartu),
                    _barisKiriKanan(
                      kiri: RepaintBoundary(
                        child: _kartuRuteSetoran(tinggiBaris: tinggiBaris),
                      ),
                      kanan: RepaintBoundary(
                        child: _kolomKananAtas(
                          tinggiKartuMasuk: tinggiMasuk,
                          tinggiBarisSupplier: tinggiBarisSupplier,
                          tinggiKolom: tinggiRute,
                        ),
                      ),
                      tinggiKanan: tinggiRute,
                    ),
                    const SizedBox(height: _celahKartu),
                    _barisKiriKanan(
                      kiri: RepaintBoundary(
                        child: _kartuJumlahSetoran(tinggiBaris: tinggiBaris),
                      ),
                      kanan: RepaintBoundary(child: _kartuOpnameHari()),
                      tinggiKanan: tinggiJumlah,
                    ),
                    const SizedBox(height: _celahKartu),
                    SizedBox(
                      height: tinggiKartuAbsen,
                      width: double.infinity,
                      child: _kartuAbsensiHari(),
                    ),
                  ],
                );
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    _padHalamanAtas,
                    16,
                    _padHalamanBawah,
                  ),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: tinggiTersedia),
                      child: isi,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BarisCocokRetur {
  _BarisCocokRetur({
    required this.kode,
    required this.nama,
    this.qtyKlaim = 0,
    this.nilai = 0,
    int qty = 0,
    int qtyFisik = 0,
    this.cek = false,
  }) : qtyCtrl = TextEditingController(text: qty == 0 ? '' : Uang.angka(qty)),
       fisikCtrl = TextEditingController(
         text: qtyFisik == 0 ? '' : Uang.angka(qtyFisik),
       );

  final String kode;
  final String nama;
  final int qtyKlaim;
  final int nilai;
  bool cek;
  final TextEditingController qtyCtrl;
  final TextEditingController fisikCtrl;

  int get qty => qtyKlaim > 0 ? qtyKlaim : Uang.angkaTeks(qtyCtrl.text);
  int get qtyFisik => Uang.angkaTeks(fisikCtrl.text);

  void dispose() {
    qtyCtrl.dispose();
    fisikCtrl.dispose();
  }
}

class _BarisMasuk {
  _BarisMasuk({
    required this.kode,
    required this.nama,
    this.qtySudah = 0,
    this.nilaiSudah = 0,
    int hargaAwal = 0,
    int qtyTambah = 0,
    this.baru = false,
    this.satuan = '',
    this.rincian = '',
    this.kategori = '',
  }) : qtyCtrl = TextEditingController(
         text: qtyTambah == 0 ? '' : Uang.angka(qtyTambah),
       ),
       hargaCtrl = TextEditingController(
         text: hargaAwal == 0 ? '' : Uang.angka(hargaAwal),
       );

  final String kode;
  final String nama;
  final bool baru;
  final String satuan;
  final String rincian;
  final String kategori;
  final int qtySudah;
  final int nilaiSudah;
  final TextEditingController qtyCtrl;
  final TextEditingController hargaCtrl;

  int get qty => Uang.angkaTeks(qtyCtrl.text);
  int get harga => Uang.angkaTeks(hargaCtrl.text);
  int get nilai => qty > 0 && harga > 0 ? qty * harga : 0;

  void dispose() {
    qtyCtrl.dispose();
    hargaCtrl.dispose();
  }
}
